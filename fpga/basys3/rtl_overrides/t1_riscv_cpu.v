module t1_riscv_cpu (
    input         clk,
    input         reset,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData,
    input  [31:0] Ext_DataAdr,

    output        MemWrite,
    output [31:0] WriteData,
    output [31:0] DataAdr,
    output [31:0] ReadData,
    output [31:0] PC,
    output [31:0] Result,
output [31:0] Instr
);


wire [31:0] DataAdr_rv32;
wire [31:0] WriteData_rv32;
wire [31:0] WriteData_rv32_Internal;
wire        MemWrite_rv32;

riscv_cpu rvcpu (
    .clk(clk),
    .reset(reset),
    .PC(PC),
    .Instr(Instr),
    .MemWrite(MemWrite_rv32),
    .Mem_WrAddr(DataAdr_rv32),
    .Mem_WrData(WriteData_rv32),
    .Mem_WrData_Internal(WriteData_rv32_Internal),
    .ReadData(ReadData),
    .Result(Result)
);

instr_mem instrmem (
    PC,
    Instr
);

data_mem datamem (
    .clk(clk),
    .wr_en(MemWrite),
    .wr_addr(DataAdr),
    .wr_data(WriteData_rv32_Internal),
    .rd_data_mem(ReadData)
);

assign MemWrite =
    (Ext_MemWrite && reset) ? 1'b1 : MemWrite_rv32;

assign WriteData =
    (Ext_MemWrite && reset) ? Ext_WriteData : WriteData_rv32;

assign DataAdr =
    reset ? Ext_DataAdr : DataAdr_rv32;

endmodule