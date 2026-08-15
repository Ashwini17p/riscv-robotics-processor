module pc (
    input  logic clk,
    input  logic reset,
    input  logic [31:0] pc_next,
    output logic [31:0] pc
);

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 32'h0000_0000;
        else
            pc <= pc_next;
    end

endmodule