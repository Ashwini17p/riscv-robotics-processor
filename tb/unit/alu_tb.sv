`timescale 1ns/1ps

module alu_tb;

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [3:0]  alu_control;
    logic [31:0] result;

    // ALU control definitions
    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b0001;
    localparam logic [3:0] ALU_AND  = 4'b0010;
    localparam logic [3:0] ALU_OR   = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_SLL  = 4'b0101;
    localparam logic [3:0] ALU_SRL  = 4'b0110;
    localparam logic [3:0] ALU_SRA  = 4'b0111;
    localparam logic [3:0] ALU_SLT  = 4'b1000;
    localparam logic [3:0] ALU_SLTU = 4'b1001;

    // DUT
    alu dut (
        .operand_a   (operand_a),
        .operand_b   (operand_b),
        .alu_control (alu_control),
        .result      (result)
    );

    // Test task
    task automatic test_alu(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [3:0]  control,
        input logic [31:0] expected,
        input string       test_name
    );

        begin
            operand_a   = a;
            operand_b   = b;
            alu_control = control;

            #1;

            if (result === expected) begin
                $display("PASS: %s | A=%h B=%h Result=%h",
                         test_name, a, b, result);
            end
            else begin
                $error("FAIL: %s | A=%h B=%h Expected=%h Got=%h",
                       test_name, a, b, expected, result);
            end
        end

    endtask


    initial begin

        $display("========================================");
        $display("       ALU TESTBENCH START");
        $display("========================================");

        // ADD
        test_alu(
            32'd5,
            32'd3,
            ALU_ADD,
            32'd8,
            "ADD"
        );

        // SUB
        test_alu(
            32'd10,
            32'd4,
            ALU_SUB,
            32'd6,
            "SUB"
        );

        // AND
        test_alu(
            32'hF0F0_F0F0,
            32'h0FF0_0FF0,
            ALU_AND,
            32'h00F0_00F0,
            "AND"
        );

        // OR
        test_alu(
            32'hF000_0000,
            32'h0000_00FF,
            ALU_OR,
            32'hF000_00FF,
            "OR"
        );

        // XOR
        test_alu(
            32'hFFFF_0000,
            32'h0000_FFFF,
            ALU_XOR,
            32'hFFFF_FFFF,
            "XOR"
        );

        // SLL
        test_alu(
            32'd1,
            32'd4,
            ALU_SLL,
            32'd16,
            "SLL"
        );

        // SRL
        test_alu(
            32'd16,
            32'd2,
            ALU_SRL,
            32'd4,
            "SRL"
        );

        // SRA
        // -16 >>> 2 = -4 = FFFFFFFC
        test_alu(
            32'hFFFF_FFF0,
            32'd2,
            ALU_SRA,
            32'hFFFF_FFFC,
            "SRA"
        );

        // SLT signed
        // -5 < 3 ? 1
        test_alu(
            32'hFFFF_FFFB,
            32'd3,
            ALU_SLT,
            32'd1,
            "SLT signed"
        );

        // SLTU unsigned
        // 0xFFFFFFFF < 1 ? false
        test_alu(
            32'hFFFF_FFFF,
            32'd1,
            ALU_SLTU,
            32'd0,
            "SLTU unsigned"
        );

        // ADD overflow/wraparound
        // FFFFFFFF + 1 = 00000000
        test_alu(
            32'hFFFF_FFFF,
            32'd1,
            ALU_ADD,
            32'h0000_0000,
            "ADD overflow"
        );

        $display("========================================");
        $display("          ALU TESTBENCH END");
        $display("========================================");

        $finish;

    end

endmodule