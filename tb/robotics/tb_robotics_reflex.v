// ============================================================
// tb_robotics_reflex.v
// Testbench for robotics_reflex
// ============================================================

`timescale 1ns/1ps

module tb_robotics_reflex;

    reg clk;
    reg reset;

    reg reflex_enable;
    reg obstacle_detected;

    reg [7:0] left_motor_in;
    reg [7:0] right_motor_in;

    wire [7:0] left_motor_out;
    wire [7:0] right_motor_out;

    wire reflex_active;
    wire reflex_event;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    robotics_reflex DUT (

        .clk(clk),
        .reset(reset),

        .reflex_enable(reflex_enable),
        .obstacle_detected(obstacle_detected),

        .left_motor_in(left_motor_in),
        .right_motor_in(right_motor_in),

        .left_motor_out(left_motor_out),
        .right_motor_out(right_motor_out),

        .reflex_active(reflex_active),
        .reflex_event(reflex_event)

    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    // --------------------------------------------------------
    // Tests
    // --------------------------------------------------------

    initial begin

        $display("==============================================");
        $display(" ROBOTICS REFLEX TEST START");
        $display("==============================================");

        reset            = 1'b1;
        reflex_enable    = 1'b0;
        obstacle_detected = 1'b0;

        left_motor_in    = 8'd70;
        right_motor_in   = 8'd70;

        #20;

        reset = 1'b0;

        // ----------------------------------------------------
        // TEST 1 : Normal operation
        // ----------------------------------------------------

        #10;

        if ((left_motor_out == 8'd70) &&
            (right_motor_out == 8'd70)) begin

            $display("TEST 1 PASS : NORMAL MOTOR OUTPUT");

        end
        else begin

            $display("TEST 1 FAIL : NORMAL MOTOR OUTPUT");

        end

        // ----------------------------------------------------
        // TEST 2 : Enable reflex
        // ----------------------------------------------------

        reflex_enable = 1'b1;

        #10;

        if ((left_motor_out == 8'd70) &&
            (right_motor_out == 8'd70)) begin

            $display("TEST 2 PASS : REFLEX ENABLED");

        end
        else begin

            $display("TEST 2 FAIL : REFLEX ENABLED");

        end

        // ----------------------------------------------------
        // TEST 3 : Obstacle detected
        // ----------------------------------------------------

        obstacle_detected = 1'b1;

        #10;

        if ((left_motor_out == 8'd0) &&
            (right_motor_out == 8'd0) &&
            (reflex_active == 1'b1)) begin

            $display("TEST 3 PASS : EMERGENCY STOP");

        end
        else begin

            $display("TEST 3 FAIL : EMERGENCY STOP");

        end

        // ----------------------------------------------------
        // TEST 4 : Obstacle removed
        // ----------------------------------------------------

        obstacle_detected = 1'b0;

        #10;

        if ((left_motor_out == 8'd70) &&
            (right_motor_out == 8'd70) &&
            (reflex_active == 1'b0)) begin

            $display("TEST 4 PASS : RECOVERY");

        end
        else begin

            $display("TEST 4 FAIL : RECOVERY");

        end

        $display("==============================================");
        $display(" ROBOTICS REFLEX TEST COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule