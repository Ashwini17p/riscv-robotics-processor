# bench_auto.S - autonomous mode: the CPU configures the subsystem once, then is free
        .include "rbt_regs.inc"
        .text
        .globl _start
_start:
        li      s0, MMIO_BASE
        li      t0, 1
        sw      t0, CONTROL(s0)             # hardware reflex
        sw      t0, AUTO(s0)                # hardware line-follow
idle:
        j       idle                        # the CPU is free for other work
