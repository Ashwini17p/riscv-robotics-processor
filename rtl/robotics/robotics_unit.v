`timescale 1ns/1ps
// ============================================================
// robotics_unit.v
//
// Custom-instruction functional unit (opcode custom-0 = 0001011).
// Purely combinational: it sits next to the ALU and answers the
// robotics instructions in a single cycle.
//
//   funct3  mnemonic     action
//   000     RSENSOR      rd <= {27'b0, sensor_in}
//   001     ROBOTSTEP    line-following step: derive motor commands from the
//                        five line sensors   (rd <= {16'b0, left, right})
//   010     MOTORCMD     left <= rs1[7:0], right <= rs2[7:0]
//
// motor_cmd_valid = 1 for ROBOTSTEP and MOTORCMD: the surrounding system
// latches left/right_motor_cmd into the motor command registers.
//
// sensor_in[4:0] = {far-left, left, center, right, far-right}; 1 = line seen.
//
//   sensors                         left   right
//   00100  center                    70     70
//   01000  left                      50     75
//   10000  far left                  30     80
//   00010  right                     75     50
//   00001  far right                 80     30
//
// Patterns with several sensors active are resolved outermost-first
// (far-left, far-right, left, right, center); 11111 (junction) goes
// straight; 00000 (line lost) stops the robot.
// ============================================================

module robotics_unit (

    input  [4:0]  sensor_in,

    input  [6:0]  opcode,
    input  [2:0]  funct3,

    input  [31:0] rs1_data,
    input  [31:0] rs2_data,

    output reg [31:0] result,

    output reg        motor_cmd_valid,
    output reg [7:0]  left_motor_cmd,
    output reg [7:0]  right_motor_cmd

);

    localparam ROBOT_OPCODE = 7'b0001011;

    localparam F3_RSENSOR   = 3'b000;
    localparam F3_ROBOTSTEP = 3'b001;
    localparam F3_MOTORCMD  = 3'b010;

    // --------------------------------------------------------
    // Line-following steering table
    // --------------------------------------------------------

    reg [7:0] step_left;
    reg [7:0] step_right;

    always @(*) begin

        step_left  = 8'd0;
        step_right = 8'd0;

        if (sensor_in == 5'b11111) begin          // junction: straight
            step_left  = 8'd70;
            step_right = 8'd70;
        end
        else if (sensor_in[4]) begin              // far left
            step_left  = 8'd30;
            step_right = 8'd80;
        end
        else if (sensor_in[0]) begin              // far right
            step_left  = 8'd80;
            step_right = 8'd30;
        end
        else if (sensor_in[3]) begin              // left
            step_left  = 8'd50;
            step_right = 8'd75;
        end
        else if (sensor_in[1]) begin              // right
            step_left  = 8'd75;
            step_right = 8'd50;
        end
        else if (sensor_in[2]) begin              // center
            step_left  = 8'd70;
            step_right = 8'd70;
        end
        // 00000: line lost -> stop (0, 0)

    end

    // --------------------------------------------------------
    // Instruction decode
    // --------------------------------------------------------

    always @(*) begin

        result          = 32'b0;
        motor_cmd_valid = 1'b0;
        left_motor_cmd  = 8'd0;
        right_motor_cmd = 8'd0;

        if (opcode == ROBOT_OPCODE) begin

            case (funct3)

                F3_RSENSOR: begin
                    result = {27'b0, sensor_in};
                end

                F3_ROBOTSTEP: begin
                    left_motor_cmd  = step_left;
                    right_motor_cmd = step_right;
                    motor_cmd_valid = 1'b1;
                    result          = {16'b0, step_left, step_right};
                end

                F3_MOTORCMD: begin
                    left_motor_cmd  = rs1_data[7:0];
                    right_motor_cmd = rs2_data[7:0];
                    motor_cmd_valid = 1'b1;
                end

                default: begin
                end

            endcase

        end

    end

endmodule
