// main_decoder_rbt.v - main decoder of t1_riscv_cpu plus the custom-0 (robotics) opcode
// Derived from rtl/t1_riscv_cpu/code/components/main_decoder.v; only the custom-0 case and the
// Custom output are new.

// main_decoder.v - logic for main decoder

module main_decoder_rbt (
    input  [6:0] op,
    output [1:0] ResultSrc,
    output       MemWrite, Branch, ALUSrc,
    output       RegWrite, Jump, Jalr, ALUSrcA_PC,
    output [2:0] ImmSrc,
    output [1:0] ALUOp,
    output       Custom          // custom-0 (robotics) instruction
);

reg [13:0] controls;

always @(*) begin
    case (op)

        // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump_Jalr_ALUSrcA_PC

        7'b0000011:
            controls = 14'b1_000_1_0_01_0_00_0_0_0; // lw

        7'b0100011:
            controls = 14'b0_001_1_1_00_0_00_0_0_0; // sw

        7'b0110011:
            controls = 14'b1_xxx_0_0_00_0_10_0_0_0; // R-type

        7'b1100011:
            controls = 14'b0_010_0_0_00_1_01_0_0_0; // beq

        7'b0010011:
            controls = 14'b1_000_1_0_00_0_10_0_0_0; // I-type ALU

        7'b1101111:
            controls = 14'b1_011_0_0_10_0_00_1_0_0; // jal

        7'b0110111:
            controls = 14'b1_100_1_0_00_0_00_0_0_0; // lui

        7'b0010111:
            controls = 14'b1_100_1_0_00_0_00_0_0_1; // auipc

        7'b1100111:
            controls = 14'b1_000_1_0_10_0_00_1_1_0; // jalr

        // custom-0: RBT instructions. Writes rd with the robotics-unit result (ResultSrc = 11)
        7'b0001011:
            controls = 14'b1_000_0_0_11_0_00_0_0_0;

        default:
            controls = 14'b0_000_0_0_00_0_00_0_0_0;

    endcase
end

assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
        ResultSrc, Branch, ALUOp, Jump, Jalr, ALUSrcA_PC} = controls;

assign Custom = (op == 7'b0001011);

endmodule