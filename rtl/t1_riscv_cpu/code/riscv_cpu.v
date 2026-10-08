module riscv_cpu (
    input         clk,
    input         reset,
    output [31:0] PC,
    input  [31:0] Instr,

    output        MemWrite,
    output [31:0] Mem_WrAddr,
    output [31:0] Mem_WrData,
    output [31:0] Mem_WrData_Internal,

    input  [31:0] ReadData,
    output [31:0] Result
);

wire ALUSrc, RegWrite, Jump, Jalr, ALUSrcA_PC;
wire [31:0] SrcA, WriteData;

wire [1:0] ResultSrc;
wire [2:0] ImmSrc;
wire [3:0] ALUControl;
wire PCSrc;

controller c (
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
    .ALUControl(ALUControl)
);

datapath dp (
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
    .WriteData(WriteData)
);

endmodule