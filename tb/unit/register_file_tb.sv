
`timescale 1ns/1ps

module register_file_tb;
    reg         clk;
    reg  [4:0]  rs1;
    reg  [4:0]  rs2;
    reg  [4:0]  rd;
    reg  [31:0] write_data;
    reg         reg_write;

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    register_file dut (
        .clk        (clk),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .write_data (write_data),
        .reg_write  (reg_write),
        .read_data1 (read_data1),
        .read_data2 (read_data2)
    );

    always #5 clk = ~clk;

    // Task for writing a register
    task write_reg;
        input [4:0]  address;
        input [31:0] data;
        begin
            @(negedge clk);
            rd         = address;
            write_data = data;
            reg_write  = 1'b1;

            @(posedge clk);
            #1;

            reg_write = 1'b0;

            $display("WRITE: x%0d = 0x%08h", address, data);
        end
    endtask

    // Task for reading two registers
    task read_regs;
        input [4:0] address1;
        input [4:0] address2;
        begin
            rs1 = address1;
            rs2 = address2;
            #2;

            $display("READ : x%0d = 0x%08h, x%0d = 0x%08h",
                     address1, read_data1,
                     address2, read_data2);
        end
    endtask

    initial begin

        // Initialize signals
        clk        = 1'b0;
        rs1        = 5'd0;
        rs2        = 5'd0;
        rd         = 5'd0;
        write_data = 32'd0;
        reg_write  = 1'b0;

      
        $display("     REGISTER FILE TESTBENCH START");
       

      
        // Test 1: Read x0
        read_regs(5'd0, 5'd0);

        if (read_data1 == 32'd0 && read_data2 == 32'd0)
            $display("TEST 1 PASS: x0 = 0");
        else
            $display("TEST 1 FAIL: x0 is not zero");

      
        // Test 2: Write x1
        
        write_reg(5'd1, 32'h12345678);

        read_regs(5'd1, 5'd0);

        if (read_data1 == 32'h12345678)
            $display("TEST 2 PASS: x1 contains correct data");
        else
            $display("TEST 2 FAIL: x1 contains 0x%08h",
                     read_data1);

    
        // Test 3: Write x2
        write_reg(5'd2, 32'hABCDEF01);

        read_regs(5'd1, 5'd2);

        if (read_data1 == 32'h12345678 &&
            read_data2 == 32'hABCDEF01)
            $display("TEST 3 PASS: Dual read successful");
        else
            $display("TEST 3 FAIL");

       
        // Test 4: Write multiple registers
     
        write_reg(5'd5, 32'h11111111);
        write_reg(5'd10, 32'h22222222);
        write_reg(5'd15, 32'h33333333);

        read_regs(5'd5, 5'd10);

        if (read_data1 == 32'h11111111 &&
            read_data2 == 32'h22222222)
            $display("TEST 4 PASS: Multiple register writes");
        else
            $display("TEST 4 FAIL");

    
        // Test 5: x0 must remain zero
      
        write_reg(5'd0, 32'hFFFFFFFF);

        read_regs(5'd0, 5'd0);

        if (read_data1 == 32'd0 &&
            read_data2 == 32'd0)
            $display("TEST 5 PASS: x0 remains zero");
        else
            $display("TEST 5 FAIL: x0 was modified");

       
        // Test 6: Read same register
       
        rs1 = 5'd15;
        rs2 = 5'd15;
        #2;

        if (read_data1 == 32'h33333333 &&
            read_data2 == 32'h33333333)
            $display("TEST 6 PASS: Same register read");
        else
            $display("TEST 6 FAIL");

    
       
        $display("     REGISTER FILE TESTBENCH END");
      

        #10;
        $finish;
    end

endmodule
```
