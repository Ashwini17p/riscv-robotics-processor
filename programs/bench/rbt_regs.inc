# rbt_regs.inc - robotics subsystem register map and custom-0 instruction macros
        .equ MMIO_BASE,     0x40000000

        .equ SENSOR,        0x00        # RO  [4:0] line sensors {far-left, left, center, right, far-right}
        .equ LEFT_MOTOR,    0x04        # RW  [7:0] left motor duty  (0..255)
        .equ RIGHT_MOTOR,   0x08        # RW  [7:0] right motor duty (0..255)
        .equ CONTROL,       0x0C        # RW  [0]  hardware reflex enable (obstacle -> stop)
        .equ STATUS,        0x10        # RO  [0]  reflex active
        .equ GPIO_OUT,      0x14        # RW  [7:0]
        .equ GPIO_DIR,      0x18        # RW  [7:0] 1 = output
        .equ GPIO_IN,       0x1C        # RO  [7:0]
        .equ AUTO,          0x20        # RW  [0]  autonomous hardware line-follow

# custom-0 instructions (opcode 0x0b, R-type, funct7 = 0)
        .macro rsensor rd                   # rd <= {27'b0, sensors}
        .insn r 0x0b, 0, 0, \rd, x0, x0
        .endm

        .macro robotstep rd                 # line-follow step: sensors -> both motor commands; rd <= {left,right}
        .insn r 0x0b, 1, 0, \rd, x0, x0
        .endm

        .macro motorcmd rs1, rs2            # left <= rs1[7:0], right <= rs2[7:0]
        .insn r 0x0b, 2, 0, x0, \rs1, \rs2
        .endm
