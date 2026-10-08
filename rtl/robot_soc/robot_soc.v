`timescale 1ns/1ps
// robot_soc.v - RV32I core + robotics unit + memories
//
//   Address map (data bus):
//     0x0000_0000 .. data RAM (64 words, wraps)
//     0x4000_0000 .. robotics subsystem registers (64-byte window, word access)
//
//   The robotics subsystem is reachable three ways: memory-mapped (lw / sw), the custom-0
//   instructions executed directly by the core (RSENSOR / ROBOTSTEP / MOTORCMD, see
//   robotics_unit.v), and an autonomous hardware line-follow mode (AUTO register).

module robot_soc #(parameter HEX_FILE = "program.hex") (
    input         clk,
    input         reset,

    // robot pins
    input  [4:0]  sensor_pin,        // {far-left, left, center, right, far-right}
    input         obstacle_pin,
    input  [7:0]  gpio_in,
    output [7:0]  gpio_out,
    output [7:0]  gpio_oe,
    output        left_pwm,
    output        right_pwm,

    // debug / observation
    output [31:0] PC,
    output [31:0] Instr,
    output [31:0] Result,
    output [31:0] DataAdr,
    output        MemWrite,
    output        reflex_active,
    output [7:0]  left_motor_command,
    output [7:0]  right_motor_command
);

wire [31:0] Mem_WrData, Mem_WrData_Internal;
wire [31:0] dmem_rdata, mmio_rdata, ReadData;

wire        rbt_en;
wire [2:0]  rbt_funct3;
wire [31:0] rbt_rs1, rbt_rs2, rbt_rd;

wire mmio_sel = (DataAdr[31:6] == 26'h1000000);          // 0x4000_0000 .. 0x4000_003F

riscv_cpu_rbt cpu (
    .clk(clk), .reset(reset),
    .PC(PC), .Instr(Instr),
    .MemWrite(MemWrite),
    .Mem_WrAddr(DataAdr),
    .Mem_WrData(Mem_WrData),
    .Mem_WrData_Internal(Mem_WrData_Internal),
    .ReadData(ReadData),
    .Result(Result),
    .rbt_en(rbt_en), .rbt_funct3(rbt_funct3),
    .rbt_rs1(rbt_rs1), .rbt_rs2(rbt_rs2), .rbt_rd(rbt_rd)
);

instr_mem_rbt #(.HEX_FILE(HEX_FILE)) imem (.instr_addr(PC), .instr(Instr));

data_mem dmem (
    .clk(clk),
    .wr_en(MemWrite & ~mmio_sel),
    .wr_addr(DataAdr),
    .wr_data(Mem_WrData_Internal),
    .rd_data_mem(dmem_rdata)
);

assign ReadData = mmio_sel ? mmio_rdata : dmem_rdata;

robotics_subsystem rcu (
    .clk(clk), .reset(reset),
    .bus_sel(mmio_sel),
    .bus_write(MemWrite & mmio_sel),
    .bus_addr(DataAdr),
    .bus_wdata(Mem_WrData),
    .bus_rdata(mmio_rdata),
    .cust_opcode(rbt_en & ~reset ? 7'b0001011 : 7'b0000000),
    .cust_funct3(rbt_funct3),
    .cust_rs1(rbt_rs1), .cust_rs2(rbt_rs2),
    .cust_result(rbt_rd),
    .sensor_pin(sensor_pin), .obstacle_pin(obstacle_pin),
    .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_oe(gpio_oe),
    .left_pwm(left_pwm), .right_pwm(right_pwm),
    .reflex_active(reflex_active), .reflex_event(),
    .left_motor_command(left_motor_command), .right_motor_command(right_motor_command)
);

endmodule
