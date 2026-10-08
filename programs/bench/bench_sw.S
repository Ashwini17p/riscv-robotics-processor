# bench_sw.S - baseline: NO robotics hardware used. GPIO pins only.
#   * sensors and the obstacle input are read through GPIO_IN ([4:0] sensors, [5] obstacle)
#   * both motors are driven by software PWM on GPIO_OUT[0] (left) and GPIO_OUT[1] (right)
#   * 32 PWM steps x 8 cycles = 256-cycle period, same as the hardware PWM
        .include "rbt_regs.inc"
        .text
        .globl _start
_start:
        li      s0, MMIO_BASE
        li      t0, 3
        sw      t0, GPIO_DIR(s0)            # GPIO[1:0] are outputs
        li      s7, 256
loop:
ctl_start:
        lw      a0, GPIO_IN(s0)
        andi    t0, a0, 32
        bnez    t0, st_stop                 # obstacle -> stop (software emergency stop)
        andi    a0, a0, 31
        .include "steer_core.inc"
ctl_end:
pwm_start:
        li      s8, 0
pwm_step:
        sltu    t1, s8, s4                  # left on?
        sltu    t2, s8, s5                  # right on?
        slli    t2, t2, 1
        or      t1, t1, t2
        sw      t1, GPIO_OUT(s0)
        addi    s8, s8, 8
        nop
        bltu    s8, s7, pwm_step
pwm_end:
        j       loop
