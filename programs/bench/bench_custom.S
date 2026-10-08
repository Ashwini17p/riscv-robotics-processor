# bench_custom.S - hardware PWM + reflex, steering with the ROBOTSTEP custom instruction
        .include "rbt_regs.inc"
        .text
        .globl _start
_start:
        li      s0, MMIO_BASE
        li      t0, 1
        sw      t0, CONTROL(s0)             # hardware reflex
loop:
ctl_start:
        robotstep a0                        # read sensors, steer, update both motors - one instruction
ctl_end:
        j       loop
