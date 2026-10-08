# bench_mmio.S - hardware PWM + hardware obstacle reflex, software steering via memory-mapped registers
        .include "rbt_regs.inc"
        .text
        .globl _start
_start:
        li      s0, MMIO_BASE
        li      t0, 1
        sw      t0, CONTROL(s0)             # hardware reflex: obstacle -> motors stop
loop:
ctl_start:
        lw      a0, SENSOR(s0)
        .include "steer_core.inc"
        sw      s4, LEFT_MOTOR(s0)
        sw      s5, RIGHT_MOTOR(s0)
ctl_end:
        j       loop
