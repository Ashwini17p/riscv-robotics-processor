`timescale 1ns/1ps

module tb_pc;

    logic clk;
    logic reset;
    logic [31:0] pc_next;
    logic [31:0] pc;

    pc dut ( .clk (clk), .reset (reset), .pc_next (pc_next), .pc (pc));

   
    always #5 clk = ~clk;

    assign pc_next = pc + 32'd4;

    initial begin

        clk   = 1'b0;
        reset = 1'b1;

        #12;

        reset = 1'b0;

        #50;

        $finish;

    end

endmodule