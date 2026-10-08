#!/usr/bin/env bash
# Run the Task 1C self-checking testbench (38 RV32I instruction checks) with Icarus Verilog.
# Usage: ./simulation/run_t1c.sh            (from anywhere inside the repo)
#        VERBOSE=1 ./simulation/run_t1c.sh  (include the datapath debug trace)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODE="$ROOT/rtl/t1_riscv_cpu/code"
BUILD="$ROOT/build/t1c"
mkdir -p "$BUILD"
cp "$CODE"/rv32i_test_1c.hex "$BUILD"/        # instr_mem.v loads the hex from the working directory
iverilog -g2005 -o "$BUILD/t1c.vvp" "$ROOT/tb/.test/tb_1c.v" "$CODE"/*.v "$CODE"/components/*.v
cd "$BUILD"
if [ "${VERBOSE:-0}" = "1" ]; then printf "finish\n" | timeout 120 vvp t1c.vvp; else printf "finish\n" | timeout 120 vvp t1c.vvp | grep -vE "MEM TRACE|LOAD DEBUG|executing"; fi
