// ============================================================
// tb_robotics_top.v
//
// Complete robotics subsystem testbench.
// ============================================================

`timescale 1ns/1ps

module tb_robotics_top;

    reg clk;
    reg reset;

    reg [4:0] sensor_in;

    reg obstacle_detected;
    reg reflex_enable;

    wire left_pwm;
    wire right_pwm;

    wire reflex_active;
    wire reflex_event;

    wire [7:0] left_motor_command;
    wire [7:0] right_motor_command;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    robotics_top DUT (

        .clk(clk),
        .reset(reset),

        .sensor_in(sensor_in),

        .obstacle_detected(obstacle_detected),

        .reflex_enable(reflex_enable),

        .left_pwm(left_pwm),
        .right_pwm(right_pwm),

        .reflex_active(reflex_active),
        .reflex_event(reflex_event),

        .left_motor_command(left_motor_command),
        .right_motor_command(right_motor_command)

    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------

    initial begin

        $display("");
        $display("================================================");
        $display(" COMPLETE ROBOTICS SYSTEM TEST");
        $display("================================================");

        reset = 1'b1;

        sensor_in = 5'b00000;

        obstacle_detected = 1'b0;
        reflex_enable     = 1'b0;

        #30;

        reset = 1'b0;

        // ====================================================
        // CENTER
        // ====================================================

        sensor_in = 5'b00100;

        #20;

        $display("CENTER  : LEFT=%d RIGHT=%d",
                 left_motor_command,
                 right_motor_command);

        // ====================================================
        // LEFT
        // ====================================================

        sensor_in = 5'b01000;

        #20;

        $display("LEFT    : LEFT=%d RIGHT=%d",
                 left_motor_command,
                 right_motor_command);

        // ====================================================
        // FAR LEFT
        // ====================================================

        sensor_in = 5'b10000;

        #20;

        $display("FAR LEFT: LEFT=%d RIGHT=%d",
                 left_motor_command,
                 right_motor_command);

        // ====================================================
        // RIGHT
        // ====================================================

        sensor_in = 5'b00010;

        #20;

        $display("RIGHT   : LEFT=%d RIGHT=%d",
                 left_motor_command,
                 right_motor_command);

        // ====================================================
        // FAR RIGHT
        // ====================================================

        sensor_in = 5'b00001;

        #20;

        $display("FAR RIGHT: LEFT=%d RIGHT=%d",
                 left_motor_command,
                 right_motor_command);

        // ====================================================
        // ENABLE REFLEX
        // ====================================================

        reflex_enable = 1'b1;

        // Robot currently wants to move
        sensor_in = 5'b00100;

        #20;

        $display("NORMAL WITH REFLEX ENABLED:");
        $display("LEFT=%d RIGHT=%d",
                 left_motor_command,
                 right_motor_command);

        // ====================================================
        // OBSTACLE
        // ====================================================

        obstacle_detected = 1'b1;

        #20;

        $display("OBSTACLE DETECTED:");
        $display("LEFT=%d RIGHT=%d REFLEX=%d EVENT=%d",
                 left_motor_command,
                 right_motor_command,
                 reflex_active,
                 reflex_event);

        if ((left_motor_command == 8'd0) &&
            (right_motor_command == 8'd0) &&
            (reflex_active == 1'b1)) begin

            $display("REFLEX TEST PASS");

        end
        else begin

            $display("REFLEX TEST FAIL");

        end

        // ====================================================
        // Remove obstacle
        // ====================================================

        obstacle_detected = 1'b0;

        #20;

        $display("OBSTACLE REMOVED:");
        $display("LEFT=%d RIGHT=%d REFLEX=%d",
                 left_motor_command,
                 right_motor_command,
                 reflex_active);

        // ====================================================

        $display("");
        $display("================================================");
        $display(" COMPLETE ROBOTICS SYSTEM TEST COMPLETE");
        $display("================================================");

        $finish;

    end

endmodule