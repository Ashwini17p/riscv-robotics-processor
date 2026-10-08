

// ============================================================
// robotics_top.v
//
// Standalone robotics subsystem.
//
// This is NOT connected to the RISC-V CPU yet.
//
// It allows us to verify the complete robotics hardware
// before modifying the existing processor.
module robotics_top (

    input        clk,
    input        reset,

    // Five line sensors
    input  [4:0] sensor_in,

    // Obstacle sensor
    input        obstacle_detected,

    // Enable hardware reflex
    input        reflex_enable,

    // PWM outputs
    output       left_pwm,
    output       right_pwm,

    // Debug/status
    output       reflex_active,
    output       reflex_event,

    output [7:0] left_motor_command,
    output [7:0] right_motor_command

);

    // --------------------------------------------------------
    // Internal motor command from robotics algorithm
    // These are driven by robotics_unit, so they must be wires.
    // --------------------------------------------------------

    wire [7:0] algorithm_left_motor;
    wire [7:0] algorithm_right_motor;

    // --------------------------------------------------------
    // Reflex output
    // --------------------------------------------------------

    wire [7:0] reflex_left_motor;
    wire [7:0] reflex_right_motor;

    // --------------------------------------------------------
    // Custom robotics unit
    // --------------------------------------------------------

    robotics_unit U_ROBOTICS (

        .sensor_in(sensor_in),

        // Directly issue ROBOT_STEP
        .opcode(7'b0001011),
        .funct3(3'b001),

        .rs1_data(32'b0),
        .rs2_data(32'b0),

        .result(),

        .motor_cmd_valid(),

        .left_motor_cmd(algorithm_left_motor),
        .right_motor_cmd(algorithm_right_motor)

    );

    // --------------------------------------------------------
    // Hardware reflex
    // --------------------------------------------------------

    robotics_reflex U_REFLEX (

        .clk(clk),
        .reset(reset),

        .reflex_enable(reflex_enable),
        .obstacle_detected(obstacle_detected),

        .left_motor_in(algorithm_left_motor),
        .right_motor_in(algorithm_right_motor),

        .left_motor_out(reflex_left_motor),
        .right_motor_out(reflex_right_motor),

        .reflex_active(reflex_active),
        .reflex_event(reflex_event)

    );

    // --------------------------------------------------------
    // Export final motor commands
    // --------------------------------------------------------

    assign left_motor_command  = reflex_left_motor;
    assign right_motor_command = reflex_right_motor;

    // --------------------------------------------------------
    // PWM generator
    // --------------------------------------------------------

    robotics_motor_pwm U_PWM (

        .clk(clk),
        .reset(reset),

        .left_motor_cmd(reflex_left_motor),
        .right_motor_cmd(reflex_right_motor),

        .left_pwm(left_pwm),
        .right_pwm(right_pwm)

    );

endmodule