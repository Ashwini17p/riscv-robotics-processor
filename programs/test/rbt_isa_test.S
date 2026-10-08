# rbt_isa_test.S - self-checking test of the robotics custom instructions, register map and GPIO.
#   The testbench holds sensors = 00100 (center), obstacle = 0, gpio_in = 0xA3.
#   Result: GPIO_OUT = 0x80 when every check passed, 0x80 + (number of failed checks) otherwise.
        .include "rbt_regs.inc"

        .macro check ra, rb
        beq     \ra, \rb, 1f
        addi    s1, s1, 1
1:
        .endm

        .text
        .globl _start
_start:
        li      s0, MMIO_BASE
        li      s1, 0                       # failed-check counter

        # --- RSENSOR instruction and SENSOR register agree with the pins
        li      t0, 4
        rsensor a0
        check   a0, t0
        lw      a1, SENSOR(s0)
        check   a1, t0

        # --- MOTORCMD updates both motor registers
        li      a2, 45
        li      a3, 90
        motorcmd a2, a3
        lw      a4, LEFT_MOTOR(s0)
        check   a4, a2
        lw      a5, RIGHT_MOTOR(s0)
        check   a5, a3

        # --- memory-mapped write / read back
        li      t1, 11
        sw      t1, LEFT_MOTOR(s0)
        lw      t2, LEFT_MOTOR(s0)
        check   t2, t1

        # --- ROBOTSTEP on the center pattern: rd = {70, 70}, both motor registers updated
        robotstep a6
        li      t3, 0x4646
        check   a6, t3
        lw      t4, LEFT_MOTOR(s0)
        li      t5, 70
        check   t4, t5
        lw      t4, RIGHT_MOTOR(s0)
        check   t4, t5

        # --- reflex control / status (no obstacle present)
        li      t0, 1
        sw      t0, CONTROL(s0)
        lw      t1, CONTROL(s0)
        check   t1, t0
        lw      t1, STATUS(s0)
        check   t1, x0

        # --- GPIO
        li      t0, 0x0F
        sw      t0, GPIO_DIR(s0)
        li      t0, 0x05
        sw      t0, GPIO_OUT(s0)
        lw      t1, GPIO_OUT(s0)
        check   t1, t0
        lw      t1, GPIO_IN(s0)
        li      t2, 0xA3
        check   t1, t2

        # --- data RAM still works next to the MMIO window
        li      t0, 0x1234
        sw      t0, 16(x0)
        lw      t1, 16(x0)
        check   t1, t0

        # --- lui: operand A must be 0 even when instruction bits [19:15] name a non-zero register
        li      s2, 5
        lui     t0, 0x00028                 # imm bits [7:3] = 5 -> instr[19:15] = x5 region
        li      t1, 0x28000
        check   t0, t1

        # --- report
        li      t0, 0x80
        add     t0, t0, s1
        sw      t0, GPIO_OUT(s0)
done:
        j       done
