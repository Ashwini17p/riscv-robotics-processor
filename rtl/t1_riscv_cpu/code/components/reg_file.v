
// reg_file.v - register file for single-cycle RISC-V CPU
//              32 registers, each 32 bits
//              two combinational read ports
//              one synchronous write port
//              x0 is hardwired to zero
//
//              Implemented explicitly using flip-flops
//              to improve timing and routing on FPGA.

module reg_file #(parameter DATA_WIDTH = 32) (
    input       clk,
    input       wr_en,
    input       [4:0] rd_addr1, rd_addr2, wr_addr,
    input       [DATA_WIDTH-1:0] wr_data,
    output      [DATA_WIDTH-1:0] rd_data1, rd_data2
);

    // 32 x DATA_WIDTH register array
    reg [DATA_WIDTH-1:0] reg_file_arr [0:31];

    integer i;

    // Synchronous register write
    always @(posedge clk) begin
        if (wr_en && (wr_addr != 5'b00000))
            reg_file_arr[wr_addr] <= wr_data;
    end

    // Combinational read ports
    assign rd_data1 =
        (rd_addr1 == 5'b00000) ? {DATA_WIDTH{1'b0}} :
        reg_file_arr[rd_addr1];

    assign rd_data2 =
        (rd_addr2 == 5'b00000) ? {DATA_WIDTH{1'b0}} :
        reg_file_arr[rd_addr2];

endmodule
