
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc,
    input         ALUSrc,
    input         RegWrite,
    input [2:0]   ImmSrc,
    input [3:0]   ALUControl,
    input         Jalr,
    input         ALUSrcA_PC,

    output [31:0] PC,
    input  [31:0] Instr,

    output [31:0] Mem_WrAddr,
    output [31:0] Mem_WrData,
    output [31:0] Mem_WrData_Internal,

    input  [31:0] ReadData,

    output [31:0] Result,
    output [31:0] SrcA,
    output [31:0] WriteData
);

wire [31:0] PCNext;
wire [31:0] PCPlus4;
wire [31:0] PCTarget;
wire [31:0] JALRTarget;
wire [31:0] PCJumpTarget;

wire [31:0] ImmExt;
wire [31:0] ALUSrcA;
wire [31:0] SrcB;
wire [31:0] ALUResult;

wire [31:0] ALUImmExt;

wire Zero;

wire [7:0]  ByteData;
wire [15:0] HalfData;

reg [31:0] StoreData;
reg [31:0] LoadResult;

wire [31:0] MemoryAddress;


/* =========================================================
   PROGRAM COUNTER
   ========================================================= */

reset_ff #(32) pcreg (
    clk,
    reset,
    PCNext,
    PC
);

adder pcadd4 (
    PC,
    32'd4,
    PCPlus4
);

adder pcaddbranch (
    PC,
    ImmExt,
    PCTarget
);

adder jalradd (
    SrcA,
    ImmExt,
    JALRTarget
);

mux2 #(32) jumpmux (
    PCTarget,
    JALRTarget,
    Jalr,
    PCJumpTarget
);

mux2 #(32) pcmux (
    PCPlus4,
    PCJumpTarget,
    PCSrc,
    PCNext
);


/* =========================================================
   REGISTER FILE
   ========================================================= */

reg_file rf (
    clk,
    RegWrite,
    Instr[19:15],
    Instr[24:20],
    Instr[11:7],
    Result,
    SrcA,
    WriteData
);


/* =========================================================
   IMMEDIATE EXTENSION
   ========================================================= */

imm_extend ext (
    Instr[31:7],
    ImmSrc,
    ImmExt
);


/* =========================================================
   SHIFT-IMMEDIATE HANDLING
   SLLI / SRLI / SRAI use shamt = Instr[24:20]
   ========================================================= */

assign ALUImmExt =
    ((Instr[6:0] == 7'b0010011) &&
     ((Instr[14:12] == 3'b001) ||
      (Instr[14:12] == 3'b101)))
    ? {27'b0, Instr[24:20]}
    : ImmExt;


/* =========================================================
   ALU INPUT MUXES
   ========================================================= */

mux2 #(32) srcamux (
    SrcA,
    PC,
    ALUSrcA_PC,
    ALUSrcA
);

mux2 #(32) srcbmux (
    WriteData,
    ALUImmExt,
    ALUSrc,
    SrcB
);


/* =========================================================
   ALU
   ========================================================= */

alu alu (
    ALUSrcA,
    SrcB,
    ALUControl,
    ALUResult,
    Zero
);


/* =========================================================
   MEMORY ADDRESS
   =========================================================

   DataAdr must equal the plain ALU-computed byte address
   for every load/store width (SB/LB/LBU, SH/LH/LHU, SW/LW).
   There is no extra offset to add here -- byte/halfword
   selection *within* the addressed word is handled below,
   purely from MemoryAddress[1:0]/[1], via StoreData,
   ByteData and HalfData. data_mem.v separately turns this
   same address into a word index using [31:2].
   ========================================================= */

assign MemoryAddress = ALUResult;


/* =========================================================
   MEMORY ADDRESS OUTPUT
   ========================================================= */

assign Mem_WrAddr = MemoryAddress;


/* =========================================================
   STORE DATA
   =========================================================

   Little-endian placement.

   SB:
       address +0 -> bits [7:0]
       address +1 -> bits [15:8]
       address +2 -> bits [23:16]
       address +3 -> bits [31:24]

   SH:
       address +0 -> bits [15:0]
       address +2 -> bits [31:16]

   SW:
       complete 32-bit word
   ========================================================= */

always @(*) begin

    case (Instr[14:12])

        /* ---------------- SB ---------------- */

        3'b000: begin

            case (MemoryAddress[1:0])

                2'b00:
                    StoreData = {
                        24'b0,
                        WriteData[7:0]
                    };

                2'b01:
                    StoreData = {
                        16'b0,
                        WriteData[7:0],
                        8'b0
                    };

                2'b10:
                    StoreData = {
                        8'b0,
                        WriteData[7:0],
                        16'b0
                    };

                2'b11:
                    StoreData = {
                        WriteData[7:0],
                        24'b0
                    };

                default:
                    StoreData = 32'b0;

            endcase

        end


        /* ---------------- SH ---------------- */

        3'b001: begin

            if (MemoryAddress[1:0] == 2'b00) begin

                StoreData = {
                    16'b0,
                    WriteData[15:0]
                };

            end
            else if (MemoryAddress[1:0] == 2'b10) begin

                StoreData = {
                    WriteData[15:0],
                    16'b0
                };

            end
            else begin

                StoreData = 32'b0;

            end

        end


        /* ---------------- SW ---------------- */

        3'b010:
            StoreData = WriteData;


        /* ---------------- DEFAULT ---------------- */

        default:
            StoreData = WriteData;

    endcase

end


/* =========================================================
   MEMORY WRITE DATA
   ========================================================= */

assign Mem_WrData = WriteData;

assign Mem_WrData_Internal = StoreData;


/* =========================================================
   LOAD BYTE EXTRACTION
   ========================================================= */

assign ByteData =
    (MemoryAddress[1:0] == 2'b00) ? ReadData[7:0]   :
    (MemoryAddress[1:0] == 2'b01) ? ReadData[15:8]  :
    (MemoryAddress[1:0] == 2'b10) ? ReadData[23:16] :
                                    ReadData[31:24];


/* =========================================================
   LOAD HALFWORD EXTRACTION
   ========================================================= */

assign HalfData =
    (MemoryAddress[1] == 1'b0)
    ? ReadData[15:0]
    : ReadData[31:16];


/* =========================================================
   LOAD EXTENSION
   ========================================================= */

always @(*) begin

    case (Instr[14:12])

        /* LB - sign extend */

        3'b000:
            LoadResult = {
                {24{ByteData[7]}},
                ByteData
            };


        /* LH - sign extend */

        3'b001:
            LoadResult = {
                {16{HalfData[15]}},
                HalfData
            };


        /* LW */

        3'b010:
            LoadResult = ReadData;


        /* LBU - zero extend */

        3'b100:
            LoadResult = {
                24'b0,
                ByteData
            };


        /* LHU - zero extend */

        3'b101:
            LoadResult = {
                16'b0,
                HalfData
            };


        default:
            LoadResult = ReadData;

    endcase

end


/* =========================================================
   RESULT MUX
   ========================================================= */

mux3 #(32) resultmux (
    ALUResult,
    LoadResult,
    PCPlus4,
    ResultSrc,
    Result
);


/* =========================================================
   DEBUG
   ========================================================= */

always @(*) begin

    if (PC >= 32'h64 && PC <= 32'h80) begin

        $display(
            "MEM TRACE: PC=%h Instr=%h rs1=x%0d SrcA=%h rs2=x%0d WriteData=%h Imm=%h ALUResult=%h DataAdr=%h Result=%h",
            PC,
            Instr,
            Instr[19:15],
            SrcA,
            Instr[24:20],
            WriteData,
            ALUImmExt,
            ALUResult,
            Mem_WrAddr,
            Result
        );

    end

end


always @(*) begin

    /* -------- SHIFT DEBUG -------- */

    if ((Instr[6:0] == 7'b0010011) &&
        (Instr[14:12] == 3'b101)) begin

        $display(
            "SHIFT DEBUG: PC=%h Instr=%h SrcA=%h ALUSrcA=%h SrcB=%h ALUControl=%b ALUResult=%h Result=%h",
            PC,
            Instr,
            SrcA,
            ALUSrcA,
            SrcB,
            ALUControl,
            ALUResult,
            Result
        );

    end


    /* -------- STORE DEBUG -------- */

    if ((Instr[6:0] == 7'b0100011) &&
        ((Instr[14:12] == 3'b000) ||
         (Instr[14:12] == 3'b001))) begin

        $display(
            "STORE DEBUG: PC=%h Instr=%h rs1=%h rs2=%h Imm=%h Addr=%h WriteData=%h ReadData=%h StoreData=%h",
            PC,
            Instr,
            SrcA,
            WriteData,
            ImmExt,
            MemoryAddress,
            WriteData,
            ReadData,
            StoreData
        );

    end


    /* -------- LOAD DEBUG -------- */

    if ((Instr[6:0] == 7'b0000011) &&
        ((Instr[14:12] == 3'b000) ||
         (Instr[14:12] == 3'b001) ||
         (Instr[14:12] == 3'b010) ||
         (Instr[14:12] == 3'b100) ||
         (Instr[14:12] == 3'b101))) begin

        $display(
            "LOAD DEBUG: PC=%h Instr=%h rs1=%h Imm=%h ALUAddr=%h MemAddr=%h ReadData=%h ByteData=%h HalfData=%h LoadResult=%h Result=%h",
            PC,
            Instr,
            SrcA,
            ImmExt,
            ALUResult,
            MemoryAddress,
            ReadData,
            ByteData,
            HalfData,
            LoadResult,
            Result
        );

    end

end

endmodule
