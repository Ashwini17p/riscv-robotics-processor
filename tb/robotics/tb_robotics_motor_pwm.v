// ============================================================
// tb_robotics_motor_pwm.v
// Testbench for robotics_motor_pwm
// ============================================================

`timescale 1ns/1ps

module tb_robotics_motor_pwm;

    reg clk;
    reg reset;

    reg [7:0] left_motor_cmd;
    reg [7:0] right_motor_cmd;

    wire left_pwm;
    wire right_pwm;

    robotics_motor_pwm DUT (

        .clk(clk),
        .reset(reset),

        .left_motor_cmd(left_motor_cmd),
        .right_motor_cmd(right_motor_cmd),

        .left_pwm(left_pwm),
        .right_pwm(right_pwm)

    );

    // High-time counters (self-checking: over any 256 consecutive clocks the pin is high 'duty' times)
    integer high_l = 0, high_r = 0;
    always @(posedge clk) begin
        if (left_pwm)  high_l = high_l + 1;
        if (right_pwm) high_r = high_r + 1;
    end

    // Clock
    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    initial begin

        $display("==============================================");
        $display(" MOTOR PWM TEST START");
        $display("==============================================");

        reset = 1'b1;

        left_motor_cmd  = 8'd0;
        right_motor_cmd = 8'd0;

        #20;

        reset = 1'b0;

        // ----------------------------------------------------
        // 0% test
        // ----------------------------------------------------

        left_motor_cmd  = 8'd0;
        right_motor_cmd = 8'd0;

        #20;

        if ((left_pwm == 1'b0) &&
            (right_pwm == 1'b0)) begin

            $display("TEST 1 PASS : 0%% DUTY");

        end
        else begin

            $display("TEST 1 FAIL : 0%% DUTY");

        end

        // ----------------------------------------------------
        // 50% test
        // ----------------------------------------------------

        left_motor_cmd  = 8'd128;
        right_motor_cmd = 8'd128;

        @(posedge clk); high_l = 0; high_r = 0;
        #2560;

        if (high_l == 128 && high_r == 128)
            $display("TEST 2 PASS : 50%% DUTY (high %0d / %0d of 256 clocks)", high_l, high_r);
        else
            $display("TEST 2 FAIL : 50%% DUTY (high %0d / %0d, expected 128)", high_l, high_r);

        // ----------------------------------------------------
        // Different motor values
        // ----------------------------------------------------

        left_motor_cmd  = 8'd64;
        right_motor_cmd = 8'd192;

        @(posedge clk); high_l = 0; high_r = 0;
        #2560;

        if (high_l == 64 && high_r == 192)
            $display("TEST 3 PASS : DIFFERENTIAL DUTY (high %0d / %0d, expected 64 / 192)", high_l, high_r);
        else
            $display("TEST 3 FAIL : DIFFERENTIAL DUTY (high %0d / %0d, expected 64 / 192)", high_l, high_r);

        $display("==============================================");
        $display(" MOTOR PWM TEST COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule