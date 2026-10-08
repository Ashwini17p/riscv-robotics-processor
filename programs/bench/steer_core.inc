# steer_core.inc - software version of the line-following table (identical to rtl/robotics/robotics_unit.v)
#   in : a0 = sensors [4:0]     out: s4 = left duty, s5 = right duty
        beqz    a0, st_stop                 # 00000 line lost -> stop
        li      t0, 31
        beq     a0, t0, st_center           # 11111 junction  -> straight
        andi    t0, a0, 16
        bnez    t0, st_far_left
        andi    t0, a0, 1
        bnez    t0, st_far_right
        andi    t0, a0, 8
        bnez    t0, st_left
        andi    t0, a0, 2
        bnez    t0, st_right
st_center:
        li      s4, 70
        li      s5, 70
        j       st_done
st_far_left:
        li      s4, 30
        li      s5, 80
        j       st_done
st_far_right:
        li      s4, 80
        li      s5, 30
        j       st_done
st_left:
        li      s4, 50
        li      s5, 75
        j       st_done
st_right:
        li      s4, 75
        li      s5, 50
        j       st_done
st_stop:
        li      s4, 0
        li      s5, 0
st_done:
