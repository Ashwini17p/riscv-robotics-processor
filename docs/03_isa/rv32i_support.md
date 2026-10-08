# RV32I instruction coverage

37 instructions implemented and tested. Not implemented: `FENCE`, `ECALL`, `EBREAK` (no CSR / privileged support).

| Group | Instructions |
|---|---|
| Register-immediate ALU | `addi` `slti` `sltiu` `xori` `ori` `andi` `slli` `srli` `srai` |
| Register-register ALU | `add` `sub` `sll` `slt` `sltu` `xor` `srl` `sra` `or` `and` |
| Upper immediates | `lui` `auipc` |
| Loads | `lb` `lh` `lw` `lbu` `lhu` |
| Stores | `sb` `sh` `sw` |
| Branches | `beq` `bne` `blt` `bge` `bltu` `bgeu` |
| Jumps | `jal` `jalr` |

The testbench reports 38 checks: the 37 instructions above plus a dedicated check that `addi` targeting `x0` leaves `x0` at zero.
Test programs: `rtl/t1_riscv_cpu/code/rv32i_test_1c.s` (full set) and `rv32i_test_1b.s` (earlier subset).
