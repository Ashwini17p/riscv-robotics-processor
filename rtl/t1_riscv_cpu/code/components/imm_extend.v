module imm_extend (
    input  [31:7]     instr,
    input  [ 2:0]     immsrc,
    output reg [31:0] immext
);

always @(*) begin
    case(immsrc)

        // I-type
        3'b000: begin
            // SLLI, SRLI, SRAI use shamt[4:0]
            if (instr[30:25] == 6'b010000)
                immext = {27'b0, instr[24:20]};
            else
                immext = {{20{instr[31]}}, instr[31:20]};
        end

        // S-type
        3'b001:
            immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};

        // B-type
        3'b010:
            immext = {{20{instr[31]}}, instr[7],
                      instr[30:25], instr[11:8], 1'b0};

        // J-type
        3'b011:
            immext = {{12{instr[31]}}, instr[19:12],
                      instr[20], instr[30:21], 1'b0};

        // U-type
        3'b100:
            immext = {instr[31:12], 12'b0};

        default:
            immext = 32'bx;

    endcase
end

endmodule