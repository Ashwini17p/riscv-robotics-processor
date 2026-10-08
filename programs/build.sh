#!/usr/bin/env bash
# Assemble the benchmark and demo programs into programs/hex/*.hex (+ .lst listing, .cfg label addresses).
# Needs RISC-V binutils, e.g.  sudo apt install gcc-riscv64-unknown-elf
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/programs/bench"; OUT="$ROOT/programs/hex"; TMP="$ROOT/build/programs"
mkdir -p "$OUT" "$TMP"
P=riscv64-unknown-elf
for s in "$SRC"/bench_*.S "$ROOT"/programs/demo/*.S "$ROOT"/programs/test/*.S; do
  n=$(basename "$s" .S)
  $P-as -march=rv32i -mabi=ilp32 -I "$SRC" -o "$TMP/$n.o" "$s"
  $P-ld -m elf32lriscv -Ttext=0 -nostdlib -o "$TMP/$n.elf" "$TMP/$n.o"
  $P-objcopy -O binary "$TMP/$n.elf" "$TMP/$n.bin"
  python3 - "$TMP/$n.bin" "$OUT/$n.hex" <<'PY'
import sys, struct
b = open(sys.argv[1], 'rb').read()
b += b'\0' * (-len(b) % 4)
open(sys.argv[2], 'w').write(''.join('%08x\n' % w for w in struct.unpack('<%dI' % (len(b)//4), b)))
PY
  $P-objdump -d -M no-aliases "$TMP/$n.elf" > "$OUT/$n.lst"
  : > "$OUT/$n.cfg"
  for sym in ctl_start ctl_end pwm_start pwm_end; do
    a=$($P-nm "$TMP/$n.elf" | awk -v s=$sym '$3==s{print $1}')
    [ -n "$a" ] && printf '+%s=%s ' "$sym" "$a" >> "$OUT/$n.cfg"
  done
  echo "$n: $(wc -l < "$OUT/$n.hex") words"
done

# Generate the instruction ROM (rtl/robot_soc/rom_image.v) from the default program image.
python3 "$ROOT/programs/hex2rom.py" \
  "$OUT/line_follower.hex" \
  "$ROOT/rtl/robot_soc/rom_image.v"
echo "rom_image.v generated from line_follower.hex -> rtl/robot_soc/rom_image.v"
