# Recreate the Vivado project for the Basys 3 build (Vivado 2025.1, xc7a35tcpg236-1).
#
# Usage (from anywhere):
#   vivado -mode batch -source fpga/basys3/create_project.tcl
# or, in the Vivado Tcl console:  source fpga/basys3/create_project.tcl
# The generated project lands in <repo>/build/vivado (git-ignored).

set script_dir [file dirname [file normalize [info script]]]
set repo       [file normalize [file join $script_dir .. ..]]
set proj_dir   [file join $repo build vivado]
set cpu_dir    [file join $repo rtl t1_riscv_cpu code]

create_project riscv_robotics_processor $proj_dir -part xc7a35tcpg236-1 -force

# --- RTL: simulation reference sources, minus the two files overridden for the FPGA build
set rtl [concat [glob -directory $cpu_dir *.v] [glob -directory [file join $cpu_dir components] *.v]]
set keep {}
foreach f $rtl {
    set n [file tail $f]
    if {$n ne "reg_file.v" && $n ne "t1_riscv_cpu.v"} { lappend keep $f }
}
add_files -norecurse $keep
add_files -norecurse [glob -directory [file join $script_dir rtl_overrides] *.v]
add_files -norecurse [file join $script_dir riscv_fpga_top.v]

# --- program image read by instr_mem.v ($readmemh)
add_files -norecurse [file join $cpu_dir rv32i_test_1c.hex]

# --- ILA debug core
add_files -norecurse [file join $script_dir ip ila_0 ila_0.xci]
generate_target all [get_ips ila_0]

# --- constraints
add_files -fileset constrs_1 -norecurse [file join $script_dir basys3.xdc]

# --- simulation fileset
add_files -fileset sim_1 -norecurse [file join $repo tb .test tb_1c.v]
set_property top tb [get_filesets sim_1]

set_property top riscv_fpga_top [current_fileset]
update_compile_order -fileset sources_1
puts "Project created in $proj_dir"
