# autonomous.S - robot demo with the CPU out of the control loop (AUTO mode)
        .include "rbt_regs.inc"
        .text
        .globl _start
_start:
        li      s0, MMIO_BASE
        li      t0, 1
        sw      t0, CONTROL(s0)
        sw      t0, AUTO(s0)
idle:
        j       idle
