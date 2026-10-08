// riscv_robot_fpga_top.v - Basys 3 top level for the robot SoC (RV32I core + robotics subsystem)
//
//   CPU clock:
//     sw_run = 1  free-running, 100 MHz / 2^(DIV_BIT+1)  (default 100 MHz / 16 = 6.25 MHz)
//     sw_run = 0  single-step: one CPU clock edge per press of btn_step (debug)
//   The core's combinational path is ~13.6 ns, so up to ~70 MHz would close; 100 MHz would not.
//   The 8-bit PWM period is 256 CPU clocks, so the motor PWM frequency is f_cpu / 256:
//     DIV_BIT = 3 -> 6.25 MHz -> 24.4 kHz  (default; suits L298N / TB6612 style drivers)
//     DIV_BIT = 1 -> 25 MHz   -> 97.7 kHz
//   The robotics subsystem shares the CPU clock, so in single-step mode the PWM only advances per step.
//
//   Pins (see basys3_robot.xdc):
//     Pmod JA  five line sensors + obstacle sensor     Pmod JB  H-bridge: EN (PWM) + direction
//     Pmod JC  general-purpose I/O                     LEDs     sensor / PWM / reflex status
//   Direction pins are fixed to "forward"; the subsystem has no reverse (8-bit PWM duty only).

module riscv_robot_fpga_top #(
    parameter HEX_FILE = "line_follower.hex",
    parameter DIV_BIT  = 3                       // CPU clock = clk / 2^(DIV_BIT+1)
) (
    input  wire       clk,            // 100 MHz
    input  wire       reset,          // BTNC
    input  wire       btn_step,       // BTNU
    input  wire       sw_run,         // SW0
    input  wire [4:0] sensor_pin,     // {far-left, left, center, right, far-right}
    input  wire       obstacle_pin,
    output wire       motor_l_en, motor_l_in1, motor_l_in2,
    output wire       motor_r_en, motor_r_in1, motor_r_in2,
    inout  wire [7:0] gpio,
    output wire [7:0] led
);

// ---------------------------------------------------------------- clocking
reg [7:0] div = 8'd0;
always @(posedge clk) div <= div + 1'b1;

localparam DEBOUNCE_MAX = 20'd999_999;          // ~10 ms @ 100 MHz
reg [19:0] debounce_counter = 20'd0;
reg        btn_sync0 = 1'b0, btn_sync1 = 1'b0, btn_stable = 1'b0, btn_stable_prev = 1'b0;
reg        step_pulse = 1'b0;

always @(posedge clk) begin
    btn_sync0 <= btn_step;
    btn_sync1 <= btn_sync0;
    if (btn_sync1 == btn_stable)                debounce_counter <= 20'd0;
    else if (debounce_counter == DEBOUNCE_MAX) begin btn_stable <= btn_sync1; debounce_counter <= 20'd0; end
    else                                        debounce_counter <= debounce_counter + 1'b1;
    btn_stable_prev <= btn_stable;
    step_pulse      <= btn_stable && !btn_stable_prev;
end

reg cpu_clk_reg = 1'b0;
always @(posedge clk) cpu_clk_reg <= sw_run ? div[DIV_BIT] : step_pulse;

wire cpu_clk;
BUFG bufg_cpu (.I(cpu_clk_reg), .O(cpu_clk));

// ---------------------------------------------------------------- SoC
wire [7:0]  gpio_out, gpio_oe;
wire [31:0] PC, Instr, Result, DataAdr;
wire        MemWrite, left_pwm, right_pwm, reflex_active;
wire [7:0]  left_cmd, right_cmd;

robot_soc #(.HEX_FILE(HEX_FILE)) soc (
    .clk(cpu_clk), .reset(reset),
    .sensor_pin(sensor_pin), .obstacle_pin(obstacle_pin),
    .gpio_in(gpio), .gpio_out(gpio_out), .gpio_oe(gpio_oe),
    .left_pwm(left_pwm), .right_pwm(right_pwm),
    .PC(PC), .Instr(Instr), .Result(Result), .DataAdr(DataAdr), .MemWrite(MemWrite),
    .reflex_active(reflex_active),
    .left_motor_command(left_cmd), .right_motor_command(right_cmd)
);

assign motor_l_en  = left_pwm;
assign motor_l_in1 = 1'b1;   assign motor_l_in2 = 1'b0;      // forward
assign motor_r_en  = right_pwm;
assign motor_r_in1 = 1'b1;   assign motor_r_in2 = 1'b0;

genvar g;
generate
    for (g = 0; g < 8; g = g + 1) begin : g_gpio
        assign gpio[g] = gpio_oe[g] ? gpio_out[g] : 1'bz;
    end
endgenerate

// ---------------------------------------------------------------- LEDs
//   [4:0] sensors   [5] obstacle   [6] reflex active (emergency stop)   [7] left PWM
assign led = {left_pwm, reflex_active, obstacle_pin, sensor_pin};

endmodule
