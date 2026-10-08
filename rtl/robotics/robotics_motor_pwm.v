`timescale 1ns/1ps
// ============================================================
// robotics_motor_pwm.v
//
// 8-bit PWM generator for two motors.
//
// motor_cmd = 0   -> 0%
// motor_cmd = 255 -> approximately 100%
//
// PWM counter runs from 0 to 255.
// ============================================================

module robotics_motor_pwm (

    input       clk,
    input       reset,

    input [7:0] left_motor_cmd,
    input [7:0] right_motor_cmd,

    output reg  left_pwm,
    output reg  right_pwm

);

    reg [7:0] pwm_counter;

    always @(posedge clk) begin

        if (reset) begin

            pwm_counter <= 8'd0;

        end
        else begin

            pwm_counter <= pwm_counter + 8'd1;

        end

    end

    always @(*) begin

        if (pwm_counter < left_motor_cmd)
            left_pwm = 1'b1;
        else
            left_pwm = 1'b0;

        if (pwm_counter < right_motor_cmd)
            right_pwm = 1'b1;
        else
            right_pwm = 1'b0;

    end

endmodule