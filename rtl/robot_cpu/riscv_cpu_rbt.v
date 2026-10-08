// riscv_cpu_rbt.v - RV32I single-cycle core with the custom-0 robotics instruction port.
//
//   Same as riscv_cpu.v plus:
//     rbt_en / rbt_funct3 / rbt_rs1 / rbt_rs2   -> robotics unit (decoded in the ID path)
//     rbt_rd                                    <- result written back to rd (ResultSrc = 11)

module riscv_cpu_rbt (
    input         clk,
    input         reset,
    output [31:0] PC,
    input  [31:0] Instr,

    output        MemWrite,
    output [31:0] Mem_WrAddr,
    output [31:0] Mem_WrData,
    output [31:0] Mem_WrData_Internal,

    input  [31:0] ReadData,
    output [31:0] Result,

    // custom-instruction port
    output        rbt_en,
    output [2:0]  rbt_funct3,
    output [31:0] rbt_rs1,
    output [31:0] rbt_rs2,
    input  [31:0] rbt_rd
);

wire ALUSrc, RegWrite, Jump, Jalr, ALUSrcA_PC;
wire [31:0] SrcA, WriteData;

wire [1:0] ResultSrc;
wire [2:0] ImmSrc;
wire [3:0] ALUControl;
wire PCSrc;

controller_rbt c (
    .op(Instr[6:0]),
    .funct3(Instr[14:12]),
    .funct7b5(Instr[30]),
    .SrcA(SrcA),
    .WriteData(WriteData),

    .ResultSrc(ResultSrc),
    .MemWrite(MemWrite),
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .Jump(Jump),
    .Jalr(Jalr),
    .ALUSrcA_PC(ALUSrcA_PC),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    .Custom(rbt_en)
);

datapath_rbt dp (
    .clk(clk),
    .reset(reset),

    .ResultSrc(ResultSrc),
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    .Jalr(Jalr),
    .ALUSrcA_PC(ALUSrcA_PC),

    .PC(PC),
    .Instr(Instr),

    .Mem_WrAddr(Mem_WrAddr),
    .Mem_WrData(Mem_WrData),
    .Mem_WrData_Internal(Mem_WrData_Internal),

    .ReadData(ReadData),
    .Result(Result),

    .SrcA(SrcA),
    .WriteData(WriteData),

    .RbtResult(rbt_rd)
);

assign rbt_funct3 = Instr[14:12];
assign rbt_rs1    = SrcA;
assign rbt_rs2    = WriteData;

endmodule
