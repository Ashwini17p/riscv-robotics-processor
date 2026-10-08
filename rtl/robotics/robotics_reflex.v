`timescale 1ns/1ps
// robotics_reflex.v
//
// Hardware safety/reflex unit.
//
// If obstacle_detected = 1 and reflex_enable = 1,
// both motor outputs are forced to zero.
//
// This represents a CPU-independent emergency stop path.
// ============================================================

module robotics_reflex (

    input        clk,
    input        reset,

    input        reflex_enable,
    input        obstacle_detected,

    input  [7:0] left_motor_in,
    input  [7:0] right_motor_in,

    output reg [7:0] left_motor_out,
    output reg [7:0] right_motor_out,

    output reg       reflex_active,
    output reg       reflex_event

);

    reg previous_obstacle;

    always @(posedge clk) begin

        if (reset) begin

            left_motor_out  <= 8'd0;
            right_motor_out <= 8'd0;

            reflex_active   <= 1'b0;
            reflex_event    <= 1'b0;

            previous_obstacle <= 1'b0;

        end
        else begin

            // Default: no new event
            reflex_event <= 1'b0;

            // ------------------------------------------------
            // Hardware reflex
            // ------------------------------------------------

            if (reflex_enable && obstacle_detected) begin

                left_motor_out  <= 8'd0;
                right_motor_out <= 8'd0;

                reflex_active <= 1'b1;

            end
            else begin

                left_motor_out  <= left_motor_in;
                right_motor_out <= right_motor_in;

                reflex_active <= 1'b0;

            end

            // ------------------------------------------------
            // Generate event on obstacle rising edge
            // ------------------------------------------------

            if (reflex_enable &&
                obstacle_detected &&
                !previous_obstacle) begin

                reflex_event <= 1'b1;

            end

            previous_obstacle <= obstacle_detected;

        end

    end

endmodule