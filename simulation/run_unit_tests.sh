#!/usr/bin/env bash
# Run the SystemVerilog unit testbenches (ALU, PC, register file) with Icarus Verilog (-g2012).
# Note: the testbenches use SystemVerilog features; if Icarus rejects one, run it in Vivado xsim / ModelSim instead.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/unit"; mkdir -p "$BUILD"
for t in alu pc register_file; do
  echo "=== $t ==="
  iverilog -g2012 -o "$BUILD/$t.vvp" "$ROOT/rtl/core/$t.sv" "$ROOT/tb/unit/${t}_tb.sv" && printf "finish\n" | timeout 60 vvp "$BUILD/$t.vvp" | tail -n 8
done
