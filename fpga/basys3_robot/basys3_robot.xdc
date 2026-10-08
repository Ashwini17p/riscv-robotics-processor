## =========================================================
## Basys 3 - RISC-V robot SoC (riscv_robot_fpga_top)
## Pin numbers follow the Digilent Basys 3 master XDC - cross-check against it before use.
## =========================================================
## 100 MHz clock
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
## CPU clock (100 MHz / 16 in run mode, DIV_BIT = 3); declared at the run-mode rate
create_generated_clock -name cpu_clk -source [get_ports clk] -divide_by 16 [get_pins bufg_cpu/O]

## Buttons and switch
set_property PACKAGE_PIN U18 [get_ports reset]
set_property PACKAGE_PIN T18 [get_ports btn_step]
set_property PACKAGE_PIN V17 [get_ports sw_run]
set_property IOSTANDARD LVCMOS33 [get_ports {reset btn_step sw_run}]

## Pmod JA - sensors
##   JA1..JA3, JA4, JA7 = line sensors {far-right, right, center, left, far-left} -> sensor_pin[0..4]
##   JA8 = obstacle sensor
set_property PACKAGE_PIN J1 [get_ports {sensor_pin[0]}]
set_property PACKAGE_PIN L2 [get_ports {sensor_pin[1]}]
set_property PACKAGE_PIN J2 [get_ports {sensor_pin[2]}]
set_property PACKAGE_PIN G2 [get_ports {sensor_pin[3]}]
set_property PACKAGE_PIN H1 [get_ports {sensor_pin[4]}]
set_property PACKAGE_PIN K2 [get_ports obstacle_pin]
set_property IOSTANDARD LVCMOS33 [get_ports {sensor_pin[*] obstacle_pin}]

## Pmod JB - H-bridge motor driver
##   JB1 left EN (PWM), JB2 left IN1, JB3 left IN2, JB4 right EN (PWM), JB7 right IN1, JB8 right IN2
set_property PACKAGE_PIN A14 [get_ports motor_l_en]
set_property PACKAGE_PIN A16 [get_ports motor_l_in1]
set_property PACKAGE_PIN B15 [get_ports motor_l_in2]
set_property PACKAGE_PIN B16 [get_ports motor_r_en]
set_property PACKAGE_PIN A15 [get_ports motor_r_in1]
set_property PACKAGE_PIN A17 [get_ports motor_r_in2]
set_property IOSTANDARD LVCMOS33 [get_ports {motor_l_en motor_l_in1 motor_l_in2 motor_r_en motor_r_in1 motor_r_in2}]

## Pmod JC - general-purpose I/O
set_property PACKAGE_PIN K17 [get_ports {gpio[0]}]
set_property PACKAGE_PIN M18 [get_ports {gpio[1]}]
set_property PACKAGE_PIN N17 [get_ports {gpio[2]}]
set_property PACKAGE_PIN P18 [get_ports {gpio[3]}]
set_property PACKAGE_PIN L17 [get_ports {gpio[4]}]
set_property PACKAGE_PIN M19 [get_ports {gpio[5]}]
set_property PACKAGE_PIN P17 [get_ports {gpio[6]}]
set_property PACKAGE_PIN R18 [get_ports {gpio[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[*]}]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## Asynchronous human / sensor inputs are synchronised in RTL
set_false_path -from [get_ports {reset btn_step sw_run sensor_pin[*] obstacle_pin gpio[*]}]
