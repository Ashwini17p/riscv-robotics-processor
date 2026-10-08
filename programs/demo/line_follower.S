# line_follower.S - demo for the robot: one custom instruction per control step
#   5 line sensors + obstacle sensor -> 2 motors (8-bit PWM). Obstacle stop is a hardware reflex.
        .include "rbt_regs.inc"
        .text
        .globl _start
_start:
        li      s0, MMIO_BASE
        li      t0, 1
        sw      t0, CONTROL(s0)             # obstacle -> motors stop, in hardware
follow:
        robotstep a0                        # sense, steer, drive
        j       follow
