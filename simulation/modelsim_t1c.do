# ModelSim / Questa script for the Task 1C testbench.
# Run from the repository root:   vsim -do simulation/modelsim_t1c.do
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vlog -vlog01compat rtl/t1_riscv_cpu/code/*.v rtl/t1_riscv_cpu/code/components/*.v tb/.test/tb_1c.v
# instr_mem.v reads rv32i_test_1c.hex relative to the simulation directory
file copy -force rtl/t1_riscv_cpu/code/rv32i_test_1c.hex .
vsim -voptargs=+acc work.tb
add wave -r /tb/uut/*
run 5000 ns
