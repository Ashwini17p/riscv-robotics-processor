#!/usr/bin/env bash
# Robotics extension test suite (Icarus Verilog):
#   1. robotics unit tests  : unit, motor PWM, reflex, MMIO, standalone top (tb_robotics_*.v)
#   2. regression           : robotics core still passes the original 38-check RV32I testbench
#   3. SoC ISA self-test    : custom instructions + register map + GPIO executed by the CPU
#   4. benchmark            : four line-following implementations vs. a reference model
#   5. FPGA top smoke test  : riscv_robot_fpga_top in free-run mode, PWM duty on the motor pins
# Usage: ./simulation/run_robotics.sh [--rebuild-programs]
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
R=rtl/t1_riscv_cpu/code; C=$R/components; RB=rtl/robotics
CORE="$C/alu.v $C/alu_decoder.v $C/imm_extend.v $C/reg_file.v $C/reset_ff.v $C/adder.v $C/mux2.v $C/mux3.v $C/mux4.v"
SUBSYS="$RB/robotics_subsystem.v $RB/robotics_ext_regs.v $RB/robotics_mmio.v $RB/robotics_unit.v $RB/robotics_reflex.v $RB/robotics_motor_pwm.v $RB/ir_sync.v"
B=build/robotics; mkdir -p "$B"
[ "${1:-}" = "--rebuild-programs" ] && ./programs/build.sh
fail=0

echo "=== 1. robotics unit tests ==="
for t in unit:robotics_unit motor_pwm:robotics_motor_pwm reflex:robotics_reflex mmio:robotics_mmio \
         top:"robotics_unit robotics_reflex robotics_motor_pwm robotics_top"; do
  name=${t%%:*}; mods=""; for m in ${t#*:}; do mods="$mods $RB/$m.v"; done
  iverilog -g2005 -o "$B/u_$name.vvp" tb/robotics/tb_robotics_$name.v $mods
  out=$(timeout 60 vvp "$B/u_$name.vvp")
  p=$(echo "$out" | grep -c "PASS"); f=$(echo "$out" | grep -c "FAIL")
  printf '  tb_robotics_%-10s %2d PASS, %d FAIL\n' "$name" "$p" "$f"; [ "$f" -ne 0 ] && fail=1
done

echo; echo "=== 2. regression: robotics core vs original RV32I testbench ==="
cp $R/rv32i_test_1c.hex "$B/"
iverilog -g2005 -o "$B/reg.vvp" tb/.test/tb_1c.v tb/robotics/t1_wrapper_rbt.v rtl/robot_cpu/*.v $R/instr_mem.v $R/data_mem.v $CORE
(cd "$B" && printf 'finish\n' | timeout 60 vvp reg.vvp | grep -E "Faulty|congrat|incorrect")

echo; echo "=== 3. SoC self-test of the robotics instructions and register map ==="
iverilog -g2005 -DSIM_PLUSARGS -o "$B/isa.vvp" tb/robotics/robot_soc_isa_tb.v rtl/robot_soc/*.v rtl/robot_cpu/*.v $SUBSYS $R/data_mem.v $CORE
timeout 60 vvp "$B/isa.vvp" +hex=programs/hex/rbt_isa_test.hex | grep -E "PASS|FAIL"

echo; echo "=== 4. benchmark (same sensor sequence, same reference model) ==="
iverilog -g2005 -DSIM_PLUSARGS -o "$B/bench.vvp" tb/robotics/robot_bench_tb.v rtl/robot_soc/*.v rtl/robot_cpu/*.v $SUBSYS $R/data_mem.v $CORE
: > "$B/bench.log"
for m in sw mmio custom auto; do
  timeout 120 vvp "$B/bench.vvp" +hex=programs/hex/bench_$m.hex +mode=$m $(cat programs/hex/bench_$m.cfg) | grep -E "RESULT|PASS|FAIL" | tee -a "$B/bench.log" | grep -E "PASS|FAIL"
done
echo; python3 simulation/bench_report.py "$B/bench.log" | tee "$B/results.md"

echo; echo "=== 5. FPGA top smoke test (free-run mode, PWM duty on the motor pins) ==="
iverilog -g2005 -DSIM_PLUSARGS -o "$B/smoke.vvp" tb/robotics/fpga_top_smoke_tb.v fpga/basys3_robot/riscv_robot_fpga_top.v fpga/basys3_robot/sim/BUFG.v rtl/robot_soc/*.v rtl/robot_cpu/*.v $SUBSYS $R/data_mem.v $CORE
timeout 250 vvp "$B/smoke.vvp" +hex=programs/hex/line_follower.hex | grep -E "PASS|FAIL"
exit $fail
