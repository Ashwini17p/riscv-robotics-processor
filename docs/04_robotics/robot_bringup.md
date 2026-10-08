# Robot bring-up on the Basys 3

Top level: `fpga/basys3_robot/riscv_robot_fpga_top.v`, constraints `basys3_robot.xdc`.
Verified in simulation only (`tb/robotics/fpga_top_smoke_tb.v`); **cross-check the pin numbers against the Digilent
Basys 3 master XDC and your wiring before applying power to a robot.**

## Wiring

| Basys 3 | Signal | Connect to |
|---|---|---|
| Pmod JA1..JA4, JA7 | `sensor_pin[0..4]` = far-right, right, center, left, far-left | five digital IR line sensors (3.3 V logic) |
| Pmod JA8 | `obstacle_pin` | digital IR obstacle sensor |
| Pmod JB1 / JB4 | left / right PWM | H-bridge enable (EN) inputs |
| Pmod JB2, JB3 / JB7, JB8 | direction inputs (fixed forward: 1, 0) | H-bridge IN1, IN2 / IN3, IN4 |
| Pmod JC1..JC8 | `gpio[7:0]` | spare I/O |
| BTNC | reset | |
| BTNU | single step (when SW0 = 0) | |
| SW0 | 1 = free-run, 0 = single-step | |
| LEDs | `{left PWM, reflex active, obstacle, sensors[4:0]}` | |

Power the motors from their own supply with a common ground; never drive a motor from a Pmod pin.

## Build

```bash
./programs/build.sh                                      # (re)assemble programs/hex/*.hex
vivado -mode batch -source fpga/basys3_robot/create_project.tcl
```

Then run synthesis, implementation and bitstream generation in Vivado. The program image is
`programs/hex/line_follower.hex` (generic `HEX_FILE`); `programs/hex/autonomous.hex` runs the CPU-free mode.

## First power-up checklist

1. Wheels off the ground. SW0 = 0 (single-step), press BTNU a few times, watch the LEDs follow the sensors.
2. SW0 = 1 and cover the sensors one at a time: the PWM LED duty should change per the steering table.
3. Trigger the obstacle sensor: both PWM outputs must drop to 0 at once (reflex LED on).
4. Only then put the robot on the track.

## Tuning

- PWM frequency = CPU clock / 256: 24.4 kHz at the default `DIV_BIT = 3`. Lower `DIV_BIT` for faster CPU / PWM.
- Speeds live in `rtl/robotics/robotics_unit.v` (steering table) or in your own program through `MOTORCMD` / `sw`.
- Active-low sensor modules need an inverter on the input (the synchronizer has an `invert` port, tied off today).
