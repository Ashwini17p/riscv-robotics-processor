`timescale 1ns/1ps

module pc_tb;

    logic        clk;
    logic        reset;
    logic [31:0] pc_next;
    logic [31:0] pc;

    // DUT
    pc dut (
        .clk     (clk),
        .reset   (reset),
        .pc_next (pc_next),
        .pc      (pc)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    // For this first test, next PC = current PC + 4
    assign pc_next = pc + 32'd4;

    // Test sequence
    initial begin

        clk   = 1'b0;
        reset = 1'b1;

        // Hold reset for 12 ns
        #12;

        // Check reset
        if (pc !== 32'h0000_0000)
            $error("FAIL: PC is not zero during reset");
        else
            $display("PASS: PC reset");

        // Release reset
        reset = 1'b0;

        // First rising edge after reset
        @(posedge clk);
        #1;

        if (pc !== 32'd4)
            $error("FAIL: Expected PC=4, got %0d", pc);
        else
            $display("PASS: PC=4");

        // Second clock
        @(posedge clk);
        #1;

        if (pc !== 32'd8)
            $error("FAIL: Expected PC=8, got %0d", pc);
        else
            $display("PASS: PC=8");

        // Third clock
        @(posedge clk);
        #1;

        if (pc !== 32'd12)
            $error("FAIL: Expected PC=12, got %0d", pc);
        else
            $display("PASS: PC=12");

        // Fourth clock
        @(posedge clk);
        #1;

        if (pc !== 32'd16)
            $error("FAIL: Expected PC=16, got %0d", pc);
        else
            $display("PASS: PC=16");

        $display("--------------------------------");
        $display("PC TEST PASSED");
        $display("--------------------------------");

        $finish;

    end

endmodule