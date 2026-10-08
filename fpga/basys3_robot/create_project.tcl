# Recreate the Vivado project for the robot SoC on the Basys 3 (Vivado 2025.1, xc7a35tcpg236-1).
#
# Usage:  vivado -mode batch -source fpga/basys3_robot/create_project.tcl
# The project is generated in <repo>/build/vivado_robot (git-ignored).
# Program image: programs/hex/line_follower.hex (change HEX_FILE below, or the generic on the top).

set script_dir [file dirname [file normalize [info script]]]
set repo       [file normalize [file join $script_dir .. ..]]
set proj_dir   [file join $repo build vivado_robot]
set cpu_dir    [file join $repo rtl t1_riscv_cpu code]
set hex        [file join $repo programs hex line_follower.hex]

create_project riscv_robot $proj_dir -part xc7a35tcpg236-1 -force

# --- shared RV32I building blocks from the reference core (unchanged files)
set comp [file join $cpu_dir components]
add_files -norecurse [list \
    [file join $comp alu.v] [file join $comp alu_decoder.v] [file join $comp imm_extend.v] \
    [file join $comp reg_file.v] [file join $comp reset_ff.v] [file join $comp adder.v] \
    [file join $comp mux2.v] [file join $comp mux3.v] [file join $comp mux4.v] \
    [file join $cpu_dir data_mem.v]]

# --- robotics core variant, SoC and robotics subsystem
add_files -norecurse [glob -directory [file join $repo rtl robot_cpu]  *.v]
add_files -norecurse [glob -directory [file join $repo rtl robot_soc]  *.v]
add_files -norecurse [glob -directory [file join $repo rtl robotics]   *.v]
add_files -norecurse [file join $script_dir riscv_robot_fpga_top.v]

# --- program image: embedded via generated rtl/robot_soc/rom_image.v (no separate hex source needed)
# add_files -norecurse $hex   ;# not needed: ROM is the generated rom_image.v

# --- constraints and simulation
add_files -fileset constrs_1 -norecurse [file join $script_dir basys3_robot.xdc]
add_files -fileset sim_1 -norecurse [file join $repo tb robotics fpga_top_smoke_tb.v]
set_property top fpga_top_smoke_tb [get_filesets sim_1]

set_property top riscv_robot_fpga_top [current_fileset]
set_property generic "HEX_FILE=line_follower.hex DIV_BIT=3" [current_fileset]
update_compile_order -fileset sources_1
puts "Project created in $proj_dir"
