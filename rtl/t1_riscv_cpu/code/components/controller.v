
// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
	 input [31:0] SrcA,
	 input [31:0] WriteData,
	 
    output[1:0]  ResultSrc,
    output       MemWrite,
    output       PCSrc, 
	 output       ALUSrc,
    output       RegWrite, 
	 output       Jump,
	 output       Jalr,
	 output       ALUSrcA_PC,
    output [2:0] ImmSrc,
    output [3:0] ALUControl
);

wire [1:0] ALUOp;
wire       Branch;

reg  BranchTaken;
  
  

main_decoder    md (op, ResultSrc, MemWrite, Branch,
                    ALUSrc, RegWrite, Jump,Jalr, ALUSrcA_PC, ImmSrc, ALUOp);

alu_decoder     ad (op[5], funct3, funct7b5, ALUOp, ALUControl);


// Branch Conditions

always @(*) begin

    case (funct3)

        3'b000: BranchTaken = (SrcA == WriteData);                    // BEQ
        3'b001: BranchTaken = (SrcA != WriteData);                    // BNE
        3'b100: BranchTaken = ($signed(SrcA) < $signed(WriteData));   // BLT
        3'b101: BranchTaken = ($signed(SrcA) >= $signed(WriteData));  // BGE
        3'b110: BranchTaken = (SrcA < WriteData);                     // BLTU
        3'b111: BranchTaken = (SrcA >= WriteData);                    // BGEU

        default: BranchTaken = 1'b0;

    endcase

end

assign PCSrc = (Branch & BranchTaken) | Jump;


endmodule

