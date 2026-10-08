module riscv_fpga_top (
    input  wire       clk,
    input  wire       reset,
    input  wire       btn_step,   // manual single-step button (Basys3 BTNU, pin T18)
    output wire [7:0] led
);

    // ---------------------------------------------------------------
    // Manual single-step "clock"
    // ---------------------------------------------------------------
    // Rather than free-running the CPU at some fixed divided rate,
    // advance it by exactly ONE instruction per press of btn_step.
    // You press the button, PC/LED update by one instruction, you
    // read the LEDs and/or re-trigger the ILA, then press again for
    // the next instruction - no race between clock speed, ILA sample
    // depth, and human reaction time.
    //
    // Implementation: debounce the button, edge-detect a press, and
    // emit a single clk-wide (10 ns) pulse on cpu_clk_reg for each
    // press. That's exactly one clean rising edge per press, which is
    // all reset_ff's posedge-triggered PC register needs. Because
    // presses happen on human timescales (always vastly slower than
    // the ~13.6 ns the combinational path actually needs - see the
    // WNS -3.636 ns @ 10 ns note from the free-running version this
    // replaced), timing here is trivially met no matter how fast or
    // slow you press.
    localparam DEBOUNCE_MAX = 20'd999_999;  // ~10 ms at 100 MHz

    reg  [19:0] debounce_counter = 20'd0;
    reg         btn_sync0 = 1'b0, btn_sync1 = 1'b0;
    reg         btn_stable = 1'b0, btn_stable_prev = 1'b0;
    reg         cpu_clk_reg = 1'b0;
    wire        cpu_clk;

    always @(posedge clk) begin
        // 2-FF synchronizer for the asynchronous button input
        btn_sync0 <= btn_step;
        btn_sync1 <= btn_sync0;

        // Debounce: only accept a new level after it's been stable
        // for DEBOUNCE_MAX cycles (~10 ms)
        if (btn_sync1 == btn_stable) begin
            debounce_counter <= 20'd0;
        end else if (debounce_counter == DEBOUNCE_MAX) begin
            btn_stable       <= btn_sync1;
            debounce_counter <= 20'd0;
        end else begin
            debounce_counter <= debounce_counter + 1'b1;
        end

        btn_stable_prev <= btn_stable;

        // One clk-wide pulse on cpu_clk_reg per debounced button press
        cpu_clk_reg <= (btn_stable && !btn_stable_prev);
    end

    // Route through a BUFG so it's treated as a proper clock net
    // (avoids "non-dedicated clock routing" DRC warnings you'd get
    // from using a plain register output as a clock directly).
    BUFG bufg_cpu_clk (
        .I (cpu_clk_reg),
        .O (cpu_clk)
    );

    wire        MemWrite;
    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire [31:0] ReadData;
    wire [31:0] PC;
    wire [31:0] Result;
    wire [31:0] Instr;

    wire        Ext_MemWrite;
    wire [31:0] Ext_WriteData;
    wire [31:0] Ext_DataAdr;

    assign Ext_MemWrite  = 1'b0;
    assign Ext_WriteData = 32'b0;
    assign Ext_DataAdr   = 32'b0;

    t1_riscv_cpu cpu (
        .clk(cpu_clk),
        .reset(reset),

        .Ext_MemWrite(Ext_MemWrite),
        .Ext_WriteData(Ext_WriteData),
        .Ext_DataAdr(Ext_DataAdr),

        .MemWrite(MemWrite),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .ReadData(ReadData),
        .PC(PC),
        .Result(Result),
        .Instr(Instr)
    );

    // Temporary LED debug
    assign led = PC[9:2];

    // ILA - clocked by the fast, always-running 100 MHz clock (not
    // cpu_clk). The auto-inserted dbg_hub needs a genuinely fast,
    // free-running clock to respond over JTAG; a slow divided clock
    // here is why Hardware Manager reported "no debug cores" and
    // "debug hub core was not detected." Running the ILA faster than
    // the CPU's own clock is fine - it just oversamples the (slow)
    // PC/Instr/etc. transitions cleanly.
    ila_0 ila_inst (
        .clk    (clk),
        .probe0 (PC),
        .probe1 (Instr),
        .probe2 (Result),
        .probe3 (MemWrite),
        .probe4 (DataAdr)
    );

endmodule