`timescale 1ns/1ps
// robot_bench_tb.v - SoC-level benchmark and functional test of four line-following implementations.
//
//   Drives the same sequence of 24 sensor patterns (incl. obstacle) into robot_soc and compares the
//   motor commands against a reference model (the table in rtl/robotics/robotics_unit.v). For the
//   program under test (+mode=sw | mmio | custom | auto) it measures:
//     - reaction latency: cycles from a sensor change until the motor command equals the expected value
//     - decision-path length: instructions between ctl_start and ctl_end
//     - loop iteration length
//     - fraction of CPU cycles spent generating PWM in software
//     - steady-state duty cycle on the left motor pin
//   Plusargs: +hex=<file> +mode=<m> +ctl_start= +ctl_end= +pwm_start= +pwm_end=  (addresses in hex)
//   The core is single-cycle (CPI = 1), so cycles == instructions retired.

module robot_bench_tb;

reg clk = 1'b0, reset = 1'b1;
always #5 clk = ~clk;

reg  [5:0] pat = 6'b000100;                 // {obstacle, far-left, left, center, right, far-right}
wire [7:0] gpio_out, gpio_oe;
wire       left_pwm, right_pwm, reflex_active;
wire [7:0] left_cmd, right_cmd;
wire [31:0] PC, Instr, Result, DataAdr;
wire        MemWrite;

robot_soc #(.HEX_FILE("program.hex")) dut (
    .clk(clk), .reset(reset),
    .sensor_pin(pat[4:0]), .obstacle_pin(pat[5]),
    .gpio_in({2'b00, pat}), .gpio_out(gpio_out), .gpio_oe(gpio_oe),
    .left_pwm(left_pwm), .right_pwm(right_pwm),
    .PC(PC), .Instr(Instr), .Result(Result), .DataAdr(DataAdr), .MemWrite(MemWrite),
    .reflex_active(reflex_active), .left_motor_command(left_cmd), .right_motor_command(right_cmd)
);

// ------------------------------------------------------------------ plusargs
reg [8*16-1:0] mode;
reg [31:0] a_ctl_start, a_ctl_end, a_pwm_start, a_pwm_end;
reg has_ctl, has_pwm;
initial begin
    if (!$value$plusargs("mode=%s", mode)) mode = "mmio";
    has_ctl = 1'b0; has_pwm = 1'b0;
    if ($value$plusargs("ctl_start=%h", a_ctl_start) && $value$plusargs("ctl_end=%h", a_ctl_end)) has_ctl = 1'b1;
    if ($value$plusargs("pwm_start=%h", a_pwm_start) && $value$plusargs("pwm_end=%h", a_pwm_end)) has_pwm = 1'b1;
end

// ------------------------------------------------------------------ reference model
function [15:0] exp_cmd(input [5:0] p);          // {left, right}
    begin
        exp_cmd = {8'd0, 8'd0};
        if (p[4:0] == 5'b11111)      exp_cmd = {8'd70, 8'd70};
        else if (p[4])               exp_cmd = {8'd30, 8'd80};
        else if (p[0])               exp_cmd = {8'd80, 8'd30};
        else if (p[3])               exp_cmd = {8'd50, 8'd75};
        else if (p[1])               exp_cmd = {8'd75, 8'd50};
        else if (p[2])               exp_cmd = {8'd70, 8'd70};
        if (p[5])                    exp_cmd = {8'd0, 8'd0};     // obstacle -> emergency stop
    end
endfunction

wire sw_mode = (mode == "sw");
// software baseline: the commands live in s4 (x20) / s5 (x21); hardware variants: reflex output
wire [7:0] obs_l = sw_mode ? dut.cpu.dp.rf.reg_file_arr[20][7:0] : left_cmd;
wire [7:0] obs_r = sw_mode ? dut.cpu.dp.rf.reg_file_arr[21][7:0] : right_cmd;

integer cycle = 0;
always @(posedge clk) cycle <= cycle + 1;

// ------------------------------------------------------------------ stimulus
localparam NCHG = 24;
reg [5:0] seq [0:NCHG-1];
initial begin
    seq[0]=6'b001000;  seq[1]=6'b010000;  seq[2]=6'b000010;  seq[3]=6'b000001;  seq[4]=6'b000000;  seq[5]=6'b000100;
    seq[6]=6'b100100;  seq[7]=6'b000100;  seq[8]=6'b001100;  seq[9]=6'b000110;  seq[10]=6'b011000; seq[11]=6'b000011;
    seq[12]=6'b011111; seq[13]=6'b001000; seq[14]=6'b000000; seq[15]=6'b010000; seq[16]=6'b000100; seq[17]=6'b000010;
    seq[18]=6'b101000; seq[19]=6'b001000; seq[20]=6'b000001; seq[21]=6'b010100; seq[22]=6'b000110; seq[23]=6'b000100;
end

reg [15:0] lfsr = 16'hACE1;
function [15:0] next_lfsr(input [15:0] x);
    next_lfsr = {x[14:0], x[15] ^ x[13] ^ x[12] ^ x[10]};
endfunction

integer pending = 0, t_change = 0, n_lat = 0, missed = 0;
integer lat_min = 1000000, lat_max = 0, lat_sum = 0;
reg [15:0] exp_now;
integer in_ctl = 0, path_cnt = 0, n_path = 0, path_min = 1000000, path_max = 0, path_sum = 0;
integer last_start = -1, n_iter = 0, iter_min = 1000000, iter_max = 0, iter_sum = 0;
integer pwm_cycles = 0, meas_cycles = 0, measuring = 0;

always @(negedge clk) if (!reset) begin
    if (pending && ({obs_l, obs_r} === exp_now)) begin
        n_lat = n_lat + 1; lat_sum = lat_sum + (cycle - t_change);
        if (cycle - t_change < lat_min) lat_min = cycle - t_change;
        if (cycle - t_change > lat_max) lat_max = cycle - t_change;
        pending = 0;
    end
    if (measuring) begin
        meas_cycles = meas_cycles + 1;
        if (has_pwm && PC >= a_pwm_start && PC < a_pwm_end) pwm_cycles = pwm_cycles + 1;
        if (has_ctl) begin
            if (PC == a_ctl_start) begin
                if (last_start >= 0) begin
                    n_iter = n_iter + 1; iter_sum = iter_sum + (cycle - last_start);
                    if (cycle - last_start < iter_min) iter_min = cycle - last_start;
                    if (cycle - last_start > iter_max) iter_max = cycle - last_start;
                end
                last_start = cycle; in_ctl = 1; path_cnt = 0;
            end
            if (in_ctl && PC == a_ctl_end) begin
                n_path = n_path + 1; path_sum = path_sum + path_cnt;
                if (path_cnt < path_min) path_min = path_cnt;
                if (path_cnt > path_max) path_max = path_cnt;
                in_ctl = 0;
            end
            if (in_ctl) path_cnt = path_cnt + 1;
        end
    end
end

// steady-state duty of the left motor pin (center pattern)
integer duty_hi = 0, duty_n = 0, duty_on = 0;
wire pin_l = sw_mode ? gpio_out[0] : left_pwm;
always @(negedge clk) if (duty_on) begin duty_n = duty_n + 1; if (pin_l) duty_hi = duty_hi + 1; end

integer i, wait_n;
initial begin
    #1;
    repeat (3) @(posedge clk);
    reset = 1'b0;
    repeat (600) @(posedge clk);
    measuring = 1;
    for (i = 0; i < NCHG; i = i + 1) begin
        lfsr = next_lfsr(lfsr);  lfsr = next_lfsr(lfsr);  lfsr = next_lfsr(lfsr);
        wait_n = 500 + (lfsr % 300);             // 500..799 cycles between changes (random phase)
        repeat (wait_n) @(posedge clk);
        if (pending) missed = missed + 1;
        @(negedge clk);
        pat = seq[i];
        exp_now = exp_cmd(seq[i]);
        pending = 1; t_change = cycle;
    end
    repeat (900) @(posedge clk);
    if (pending) missed = missed + 1;
    measuring = 0;
    duty_on = 1;
    repeat (2560) @(posedge clk);
    duty_on = 0;
    $display("RESULT mode=%0s changes=%0d measured=%0d missed=%0d lat_min=%0d lat_avg=%0d lat_max=%0d path_n=%0d path_min=%0d path_avg=%0d path_max=%0d iter_n=%0d iter_min=%0d iter_avg=%0d iter_max=%0d pwm_cycles=%0d total_cycles=%0d pin_duty_pct=%0d",
        mode, NCHG, n_lat, missed, lat_min, (n_lat ? lat_sum / n_lat : 0), lat_max,
        n_path, path_min, (n_path ? path_sum / n_path : 0), path_max,
        n_iter, iter_min, (n_iter ? iter_sum / n_iter : 0), iter_max,
        pwm_cycles, meas_cycles, (duty_n ? (duty_hi * 100) / duty_n : 0));
    if (missed == 0 && n_lat == NCHG) $display("PASS: %0s follows the reference model on all %0d sensor transitions", mode, NCHG);
    else                              $display("FAIL: %0s - %0d of %0d transitions matched", mode, n_lat, NCHG);
    $finish;
end

initial begin #100000000; $display("FAIL: timeout"); $finish; end

endmodule
