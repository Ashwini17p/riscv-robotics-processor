`timescale 1ns/1ps
// ============================================================
// robotics_mmio.v
//
// Robotics memory-mapped peripheral.
//
// Address map:
//
// 0x40000000 : SENSOR
// 0x40000004 : LEFT MOTOR
// 0x40000008 : RIGHT MOTOR
// 0x4000000C : CONTROL
// 0x40000010 : STATUS
// ============================================================

module robotics_mmio (

    input        clk,
    input        reset,

    input        mmio_valid,
    input        mmio_write,

    input [31:0] mmio_addr,
    input [31:0] mmio_wdata,

    input  [4:0] sensor_in,

    input        reflex_active,

    // Custom-instruction write port (extension): ROBOTSTEP / MOTORCMD update the same
    // motor command registers that the memory-mapped writes use.
    input        cust_valid,
    input  [7:0] cust_left,
    input  [7:0] cust_right,

    output reg [31:0] mmio_rdata,

    output reg [7:0] left_motor_cmd,
    output reg [7:0] right_motor_cmd,

    output reg       reflex_enable

);

    // --------------------------------------------------------
    // Address definitions
    // --------------------------------------------------------

    localparam ADDR_SENSOR      = 32'h40000000;
    localparam ADDR_LEFT_MOTOR  = 32'h40000004;
    localparam ADDR_RIGHT_MOTOR = 32'h40000008;
    localparam ADDR_CONTROL     = 32'h4000000C;
    localparam ADDR_STATUS      = 32'h40000010;

    // --------------------------------------------------------
    // Write registers
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            left_motor_cmd  <= 8'd0;
            right_motor_cmd <= 8'd0;

            reflex_enable   <= 1'b0;

        end
        else begin

            if (mmio_valid && mmio_write) begin

                case (mmio_addr)

                    ADDR_LEFT_MOTOR: begin

                        left_motor_cmd <= mmio_wdata[7:0];

                    end

                    ADDR_RIGHT_MOTOR: begin

                        right_motor_cmd <= mmio_wdata[7:0];

                    end

                    ADDR_CONTROL: begin

                        reflex_enable <= mmio_wdata[0];

                    end

                    default: begin

                    end

                endcase

            end

            // custom instruction (executes in its own cycle, never together with a store)
            if (cust_valid) begin

                left_motor_cmd  <= cust_left;
                right_motor_cmd <= cust_right;

            end

        end

    end

    // --------------------------------------------------------
    // Read registers
    // --------------------------------------------------------

    always @(*) begin

        mmio_rdata = 32'b0;

        if (mmio_valid && !mmio_write) begin

            case (mmio_addr)

                ADDR_SENSOR: begin

                    mmio_rdata = {27'b0, sensor_in};

                end

                ADDR_LEFT_MOTOR: begin

                    mmio_rdata = {24'b0, left_motor_cmd};

                end

                ADDR_RIGHT_MOTOR: begin

                    mmio_rdata = {24'b0, right_motor_cmd};

                end

                ADDR_CONTROL: begin

                    mmio_rdata = {31'b0, reflex_enable};

                end

                ADDR_STATUS: begin

                    mmio_rdata = {31'b0, reflex_active};

                end

                default: begin

                    mmio_rdata = 32'b0;

                end

            endcase

        end

    end

endmodule