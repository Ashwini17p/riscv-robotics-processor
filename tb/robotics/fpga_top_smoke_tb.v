`timescale 1ns/1ps
// fpga_top_smoke_tb.v - smoke test of riscv_robot_fpga_top running the demo line follower in free-run mode.
// Measures the PWM duty cycle on the motor enable pins (period = 256 CPU clocks = 4096 board clocks at the default /16 divider).
//   centre   : 70/256 = 27 %  both       far left : 30/256 = 12 %  left,  80/256 = 31 %  right
//   right    : 75/256 = 29 %  left,  50/256 = 20 %  right        obstacle : 0 % / 0 % (hardware reflex)

module fpga_top_smoke_tb;

reg clk = 0, reset = 1, btn_step = 0, sw_run = 1;
reg [4:0] sensor_pin = 5'b00100;
reg obstacle_pin = 0;
wire ml_en, ml_i1, ml_i2, mr_en, mr_i1, mr_i2;
wire [7:0] gpio, led;
always #5 clk = ~clk;

riscv_robot_fpga_top dut (
    .clk(clk), .reset(reset), .btn_step(btn_step), .sw_run(sw_run),
    .sensor_pin(sensor_pin), .obstacle_pin(obstacle_pin),
    .motor_l_en(ml_en), .motor_l_in1(ml_i1), .motor_l_in2(ml_i2),
    .motor_r_en(mr_en), .motor_r_in1(mr_i1), .motor_r_in2(mr_i2),
    .gpio(gpio), .led(led)
);

integer errors = 0, hl, hr, n;

task measure(input [255:0] name, input [4:0] s, input obst, input integer exp_l, input integer exp_r);
    begin
        sensor_pin = s; obstacle_pin = obst;
        repeat (9000) @(posedge clk);                       // let the robot react
        hl = 0; hr = 0;
        for (n = 0; n < 12288; n = n + 1) begin             // 3 PWM periods
            @(posedge clk);
            if (ml_en) hl = hl + 1;
            if (mr_en) hr = hr + 1;
        end
        hl = (hl * 100) / 12288; hr = (hr * 100) / 12288;     // percent
        if (hl >= exp_l - 1 && hl <= exp_l + 1 && hr >= exp_r - 1 && hr <= exp_r + 1)
            $display("PASS: %0s  left %0d %%  right %0d %%", name, hl, hr);
        else begin
            errors = errors + 1;
            $display("FAIL: %0s  left %0d %% (exp %0d)  right %0d %% (exp %0d)", name, hl, exp_l, hr, exp_r);
        end
    end
endtask

initial begin
    repeat (10) @(posedge clk);
    reset = 0;
    measure("centre           ", 5'b00100, 0, 27, 27);
    measure("far left         ", 5'b10000, 0, 12, 31);
    measure("right            ", 5'b00010, 0, 29, 20);
    measure("obstacle         ", 5'b00100, 1,  0,  0);
    if (errors == 0) $display("FPGA TOP SMOKE TEST PASSED"); else $display("FPGA TOP SMOKE TEST FAILED");
    $finish;
end

initial begin #50000000; $display("FAIL: timeout"); $finish; end

endmodule
