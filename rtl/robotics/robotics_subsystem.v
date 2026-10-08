`timescale 1ns/1ps
// ============================================================
// robotics_subsystem.v
//
// Robotics subsystem as integrated into the RISC-V SoC:
//
//   pins ──► ir_sync ──┬──► robotics_unit  (custom-0 instructions, CPU path)
//                      ├──► robotics_unit  (autonomous ROBOTSTEP, CPU-free path)
//                      └──► robotics_mmio  (memory-mapped registers)
//
//   motor command = AUTO ? ROBOTSTEP(sensors) : motor command registers
//        │
//        ▼
//   robotics_reflex  (obstacle emergency stop)  ──►  robotics_motor_pwm  ──►  left/right PWM
//
// Three ways to drive the robot: memory-mapped writes, custom instructions, or the autonomous mode.
// ============================================================

module robotics_subsystem (

    input         clk,
    input         reset,

    // memory-mapped bus (window 0x40000000 .. 0x4000003F)
    input         bus_sel,
    input         bus_write,
    input  [31:0] bus_addr,
    input  [31:0] bus_wdata,
    output [31:0] bus_rdata,

    // custom-instruction port
    input  [6:0]  cust_opcode,
    input  [2:0]  cust_funct3,
    input  [31:0] cust_rs1,
    input  [31:0] cust_rs2,
    output [31:0] cust_result,

    // pins
    input  [4:0]  sensor_pin,
    input         obstacle_pin,
    input  [7:0]  gpio_in,
    output [7:0]  gpio_out,
    output [7:0]  gpio_oe,
    output        left_pwm,
    output        right_pwm,

    // observation
    output        reflex_active,
    output        reflex_event,
    output [7:0]  left_motor_command,
    output [7:0]  right_motor_command

);

    // ---------------------------------------------------------------- input synchronisers
    wire [5:0] in_sync;
    ir_sync #(.N(6)) u_sync (.clk(clk), .rst(reset), .raw({obstacle_pin, sensor_pin}),
                             .invert(6'b0), .sync(in_sync));
    wire [4:0] sensor_s   = in_sync[4:0];
    wire       obstacle_s = in_sync[5];

    reg [7:0] gpio_s0, gpio_s1;
    always @(posedge clk) begin
        if (reset) begin gpio_s0 <= 8'd0; gpio_s1 <= 8'd0; end
        else       begin gpio_s0 <= gpio_in; gpio_s1 <= gpio_s0; end
    end

    // ---------------------------------------------------------------- custom instructions (CPU path)
    wire        cust_valid;
    wire [7:0]  cust_left, cust_right;

    robotics_unit u_cust (
        .sensor_in(sensor_s),
        .opcode(cust_opcode), .funct3(cust_funct3),
        .rs1_data(cust_rs1), .rs2_data(cust_rs2),
        .result(cust_result),
        .motor_cmd_valid(cust_valid),
        .left_motor_cmd(cust_left), .right_motor_cmd(cust_right)
    );

    // ---------------------------------------------------------------- autonomous path
    wire [7:0] auto_left, auto_right;

    robotics_unit u_auto (
        .sensor_in(sensor_s),
        .opcode(7'b0001011), .funct3(3'b001),
        .rs1_data(32'b0), .rs2_data(32'b0),
        .result(),
        .motor_cmd_valid(),
        .left_motor_cmd(auto_left), .right_motor_cmd(auto_right)
    );

    // ---------------------------------------------------------------- memory-mapped registers
    wire [31:0] mmio_rdata, ext_rdata;
    wire        ext_hit, auto_enable, reflex_enable;
    wire [7:0]  reg_left, reg_right;

    robotics_mmio u_mmio (
        .clk(clk), .reset(reset),
        .mmio_valid(bus_sel), .mmio_write(bus_write),
        .mmio_addr(bus_addr), .mmio_wdata(bus_wdata),
        .sensor_in(sensor_s),
        .reflex_active(reflex_active),
        .cust_valid(cust_valid), .cust_left(cust_left), .cust_right(cust_right),
        .mmio_rdata(mmio_rdata),
        .left_motor_cmd(reg_left), .right_motor_cmd(reg_right),
        .reflex_enable(reflex_enable)
    );

    robotics_ext_regs u_ext (
        .clk(clk), .reset(reset),
        .mmio_valid(bus_sel), .mmio_write(bus_write),
        .mmio_addr(bus_addr), .mmio_wdata(bus_wdata),
        .gpio_in_sync(gpio_s1),
        .hit(ext_hit), .mmio_rdata(ext_rdata),
        .gpio_out(gpio_out), .gpio_oe(gpio_oe), .auto_enable(auto_enable)
    );

    assign bus_rdata = ext_hit ? ext_rdata : mmio_rdata;

    // ---------------------------------------------------------------- reflex + PWM
    wire [7:0] cmd_left  = auto_enable ? auto_left  : reg_left;
    wire [7:0] cmd_right = auto_enable ? auto_right : reg_right;

    wire [7:0] out_left, out_right;

    robotics_reflex u_reflex (
        .clk(clk), .reset(reset),
        .reflex_enable(reflex_enable), .obstacle_detected(obstacle_s),
        .left_motor_in(cmd_left), .right_motor_in(cmd_right),
        .left_motor_out(out_left), .right_motor_out(out_right),
        .reflex_active(reflex_active), .reflex_event(reflex_event)
    );

    robotics_motor_pwm u_pwm (
        .clk(clk), .reset(reset),
        .left_motor_cmd(out_left), .right_motor_cmd(out_right),
        .left_pwm(left_pwm), .right_pwm(right_pwm)
    );

    assign left_motor_command  = out_left;
    assign right_motor_command = out_right;

endmodule
