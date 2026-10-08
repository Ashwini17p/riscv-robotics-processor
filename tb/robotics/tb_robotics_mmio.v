// ============================================================
// tb_robotics_mmio.v
// Testbench for robotics_mmio
// ============================================================

`timescale 1ns/1ps

module tb_robotics_mmio;

    reg clk;
    reg reset;

    reg        mmio_valid;
    reg        mmio_write;
    reg [31:0] mmio_addr;
    reg [31:0] mmio_wdata;

    reg [4:0] sensor_in;

    reg reflex_active;

    wire [31:0] mmio_rdata;

    wire [7:0] left_motor_cmd;
    wire [7:0] right_motor_cmd;

    wire reflex_enable;

    robotics_mmio DUT (
        .cust_valid(1'b0), .cust_left(8'd0), .cust_right(8'd0),

        .clk(clk),
        .reset(reset),

        .mmio_valid(mmio_valid),
        .mmio_write(mmio_write),

        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),

        .sensor_in(sensor_in),

        .reflex_active(reflex_active),

        .mmio_rdata(mmio_rdata),

        .left_motor_cmd(left_motor_cmd),
        .right_motor_cmd(right_motor_cmd),

        .reflex_enable(reflex_enable)

    );

    // Clock
    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    initial begin

        $display("==============================================");
        $display(" MMIO TEST START");
        $display("==============================================");

        reset = 1'b1;

        mmio_valid = 1'b0;
        mmio_write = 1'b0;

        mmio_addr  = 32'b0;
        mmio_wdata = 32'b0;

        sensor_in = 5'b00000;
        reflex_active = 1'b0;

        #20;

        reset = 1'b0;

        // ====================================================
        // Write LEFT MOTOR
        // ====================================================

        mmio_valid = 1'b1;
        mmio_write = 1'b1;

        mmio_addr  = 32'h40000004;
        mmio_wdata = 32'd60;

        #10;

        if (left_motor_cmd == 8'd60)
            $display("TEST 1 PASS : LEFT MOTOR WRITE");
        else
            $display("TEST 1 FAIL : LEFT MOTOR WRITE");

        // ====================================================
        // Write RIGHT MOTOR
        // ====================================================

        mmio_addr  = 32'h40000008;
        mmio_wdata = 32'd80;

        #10;

        if (right_motor_cmd == 8'd80)
            $display("TEST 2 PASS : RIGHT MOTOR WRITE");
        else
            $display("TEST 2 FAIL : RIGHT MOTOR WRITE");

        // ====================================================
        // Enable reflex
        // ====================================================

        mmio_addr  = 32'h4000000C;
        mmio_wdata = 32'd1;

        #10;

        if (reflex_enable == 1'b1)
            $display("TEST 3 PASS : REFLEX ENABLE");
        else
            $display("TEST 3 FAIL : REFLEX ENABLE");

        // ====================================================
        // Read sensor
        // ====================================================

        mmio_write = 1'b0;
        mmio_addr  = 32'h40000000;

        sensor_in = 5'b00100;

        #10;

        if (mmio_rdata[4:0] == 5'b00100)
            $display("TEST 4 PASS : SENSOR READ");
        else
            $display("TEST 4 FAIL : SENSOR READ");

        // ====================================================
        // Read status
        // ====================================================

        reflex_active = 1'b1;

        mmio_addr = 32'h40000010;

        #10;

        if (mmio_rdata[0] == 1'b1)
            $display("TEST 5 PASS : STATUS READ");
        else
            $display("TEST 5 FAIL : STATUS READ");

        $display("==============================================");
        $display(" MMIO TEST COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule