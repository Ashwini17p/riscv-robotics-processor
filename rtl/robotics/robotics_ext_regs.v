`timescale 1ns/1ps
// ============================================================
// robotics_ext_regs.v
//
// Extension registers next to robotics_mmio (the base map 0x40000000..0x40000010 is untouched):
//
//   0x40000014 : GPIO_OUT   [7:0]  RW   output latch
//   0x40000018 : GPIO_DIR   [7:0]  RW   1 = pin is an output
//   0x4000001C : GPIO_IN    [7:0]  RO   synchronised pin levels
//   0x40000020 : AUTO       [0]    RW   1 = hardware line-follow: motor commands come from the
//                                       ROBOTSTEP logic every cycle, the CPU is not involved
// ============================================================

module robotics_ext_regs (

    input         clk,
    input         reset,

    input         mmio_valid,
    input         mmio_write,
    input  [31:0] mmio_addr,
    input  [31:0] mmio_wdata,

    input  [7:0]  gpio_in_sync,

    output        hit,                 // address belongs to this block
    output reg [31:0] mmio_rdata,

    output reg [7:0] gpio_out,
    output reg [7:0] gpio_oe,
    output reg       auto_enable

);

    localparam ADDR_GPIO_OUT = 32'h40000014;
    localparam ADDR_GPIO_DIR = 32'h40000018;
    localparam ADDR_GPIO_IN  = 32'h4000001C;
    localparam ADDR_AUTO     = 32'h40000020;

    assign hit = (mmio_addr == ADDR_GPIO_OUT) || (mmio_addr == ADDR_GPIO_DIR) ||
                 (mmio_addr == ADDR_GPIO_IN)  || (mmio_addr == ADDR_AUTO);

    always @(posedge clk) begin
        if (reset) begin
            gpio_out    <= 8'd0;
            gpio_oe     <= 8'd0;
            auto_enable <= 1'b0;
        end
        else if (mmio_valid && mmio_write) begin
            case (mmio_addr)
                ADDR_GPIO_OUT: gpio_out    <= mmio_wdata[7:0];
                ADDR_GPIO_DIR: gpio_oe     <= mmio_wdata[7:0];
                ADDR_AUTO:     auto_enable <= mmio_wdata[0];
                default: ;
            endcase
        end
    end

    always @(*) begin
        mmio_rdata = 32'b0;
        if (mmio_valid && !mmio_write) begin
            case (mmio_addr)
                ADDR_GPIO_OUT: mmio_rdata = {24'b0, gpio_out};
                ADDR_GPIO_DIR: mmio_rdata = {24'b0, gpio_oe};
                ADDR_GPIO_IN:  mmio_rdata = {24'b0, gpio_in_sync};
                ADDR_AUTO:     mmio_rdata = {31'b0, auto_enable};
                default: ;
            endcase
        end
    end

endmodule
