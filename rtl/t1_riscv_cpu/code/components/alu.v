module alu #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [3:0] alu_control,
    output reg [WIDTH-1:0] alu_out,
    output zero
);

always @(*) begin
    case (alu_control)

        // ADD
        4'b0000:
            alu_out = a + b;

        // SUB
        4'b0001:
            alu_out = a - b;

        // AND
        4'b0010:
            alu_out = a & b;

        // OR
        4'b0011:
            alu_out = a | b;

        // XOR
        4'b0100:
            alu_out = a ^ b;

        // SLT
        4'b0101:
            alu_out = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;

        // SLL
        4'b0110:
            alu_out = a << b[4:0];

        // SRL
        4'b0111:
            alu_out = a >> b[4:0];

        // SLTU
        4'b1000:
            alu_out = (a < b) ? 32'd1 : 32'd0;

        // SRA
        4'b1001: begin
            // Make a 64-bit sign-extended value first.
            // Then perform a logical right shift.
            // The lower 32 bits are exactly arithmetic-right-shift(a).
            alu_out = {{WIDTH{a[WIDTH-1]}}, a} >> b[4:0];
        end

        default:
            alu_out = 32'b0;

    endcase
end

assign zero = (alu_out == 32'b0);

endmodule