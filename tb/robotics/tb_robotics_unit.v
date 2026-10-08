// ============================================================
// tb_robotics_unit.v
// Testbench for robotics_unit
// ============================================================

`timescale 1ns/1ps

module tb_robotics_unit;

    reg [4:0]  sensor_in;

    reg [6:0]  opcode;
    reg [2:0]  funct3;

    reg [31:0] rs1_data;
    reg [31:0] rs2_data;

    wire [31:0] result;

    wire        motor_cmd_valid;
    wire [7:0]  left_motor_cmd;
    wire [7:0]  right_motor_cmd;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    robotics_unit DUT (

        .sensor_in(sensor_in),

        .opcode(opcode),
        .funct3(funct3),

        .rs1_data(rs1_data),
        .rs2_data(rs2_data),

        .result(result),

        .motor_cmd_valid(motor_cmd_valid),
        .left_motor_cmd(left_motor_cmd),
        .right_motor_cmd(right_motor_cmd)

    );

    // --------------------------------------------------------
    // Constants
    // --------------------------------------------------------

    localparam ROBOT_OPCODE = 7'b0001011;

    localparam F3_RSENSOR   = 3'b000;
    localparam F3_ROBOTSTEP = 3'b001;
    localparam F3_MOTORCMD  = 3'b010;

    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin

        $display("==============================================");
        $display(" ROBOTICS UNIT TEST START");
        $display("==============================================");

        // Initial values
        sensor_in = 5'b00000;
        opcode    = ROBOT_OPCODE;
        funct3    = F3_RSENSOR;
        rs1_data  = 32'b0;
        rs2_data  = 32'b0;

        #10;

        // ====================================================
        // TEST 1 : RSENSOR
        // ====================================================

        sensor_in = 5'b00100;
        funct3    = F3_RSENSOR;

        #10;

        if (result[4:0] == 5'b00100)
            $display("TEST 1 PASS : RSENSOR");
        else
            $display("TEST 1 FAIL : RSENSOR");

        // ====================================================
        // TEST 2 : CENTER
        // ====================================================

        sensor_in = 5'b00100;
        funct3    = F3_ROBOTSTEP;

        #10;

        if ((left_motor_cmd == 8'd70) &&
            (right_motor_cmd == 8'd70)) begin

            $display("TEST 2 PASS : CENTER");

        end
        else begin

            $display("TEST 2 FAIL : CENTER");
            $display("LEFT = %d RIGHT = %d",
                     left_motor_cmd,
                     right_motor_cmd);

        end

        // ====================================================
        // TEST 3 : LEFT
        // ====================================================

        sensor_in = 5'b01000;
        funct3    = F3_ROBOTSTEP;

        #10;

        if ((left_motor_cmd == 8'd50) &&
            (right_motor_cmd == 8'd75)) begin

            $display("TEST 3 PASS : LEFT");

        end
        else begin

            $display("TEST 3 FAIL : LEFT");

        end

        // ====================================================
        // TEST 4 : FAR LEFT
        // ====================================================

        sensor_in = 5'b10000;
        funct3    = F3_ROBOTSTEP;

        #10;

        if ((left_motor_cmd == 8'd30) &&
            (right_motor_cmd == 8'd80)) begin

            $display("TEST 4 PASS : FAR LEFT");

        end
        else begin

            $display("TEST 4 FAIL : FAR LEFT");

        end

        // ====================================================
        // TEST 5 : RIGHT
        // ====================================================

        sensor_in = 5'b00010;
        funct3    = F3_ROBOTSTEP;

        #10;

        if ((left_motor_cmd == 8'd75) &&
            (right_motor_cmd == 8'd50)) begin

            $display("TEST 5 PASS : RIGHT");

        end
        else begin

            $display("TEST 5 FAIL : RIGHT");

        end

        // ====================================================
        // TEST 6 : FAR RIGHT
        // ====================================================

        sensor_in = 5'b00001;
        funct3    = F3_ROBOTSTEP;

        #10;

        if ((left_motor_cmd == 8'd80) &&
            (right_motor_cmd == 8'd30)) begin

            $display("TEST 6 PASS : FAR RIGHT");

        end
        else begin

            $display("TEST 6 FAIL : FAR RIGHT");

        end

        // ====================================================
        // TEST 7 : MOTOR_CMD
        // ====================================================

        funct3   = F3_MOTORCMD;

        rs1_data = 32'd45;
        rs2_data = 32'd90;

        #10;

        if ((motor_cmd_valid == 1'b1) &&
            (left_motor_cmd == 8'd45) &&
            (right_motor_cmd == 8'd90)) begin

            $display("TEST 7 PASS : MOTOR_CMD");

        end
        else begin

            $display("TEST 7 FAIL : MOTOR_CMD");

        end

        // ====================================================

        $display("==============================================");
        $display(" ROBOTICS UNIT TEST COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule