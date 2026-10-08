`timescale 1ns/1ps
// robot_soc_isa_tb.v - runs programs/hex/rbt_isa_test.hex on robot_soc.
// Inputs: sensors = 00100, obstacle = 0, gpio_in = 0xA3. The program reports through GPIO_OUT:
// 0x80 = all checks passed, 0x80 + n = n checks failed.

module robot_soc_isa_tb;

reg clk = 0, reset = 1;
always #5 clk = ~clk;

wire [7:0] gpio_out, gpio_oe;
wire left_pwm, right_pwm, reflex_active;
wire [7:0] lc, rc;
wire [31:0] PC, Instr, Result, DataAdr;
wire MemWrite;

robot_soc #(.HEX_FILE("program.hex")) dut (
    .clk(clk), .reset(reset),
    .sensor_pin(5'b00100), .obstacle_pin(1'b0), .gpio_in(8'hA3),
    .gpio_out(gpio_out), .gpio_oe(gpio_oe), .left_pwm(left_pwm), .right_pwm(right_pwm),
    .PC(PC), .Instr(Instr), .Result(Result), .DataAdr(DataAdr), .MemWrite(MemWrite),
    .reflex_active(reflex_active), .left_motor_command(lc), .right_motor_command(rc)
);

initial begin
    repeat (3) @(posedge clk);
    reset = 0;
    repeat (800) @(posedge clk);
    $display("GPIO_OUT = 0x%h, PC = 0x%h", gpio_out, PC);
    if (gpio_out == 8'h80) $display("PASS: RBT instruction / register-map self-test (all checks passed)");
    else                   $display("FAIL: RBT self-test, %0d checks failed (GPIO_OUT = 0x%h)", gpio_out - 8'h80, gpio_out);
    $finish;
end

endmodule
