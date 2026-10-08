# Benchmark: one task, four implementations

![Benchmark comparison](../../images/benchmark_comparison.png)

**Task.** Follow a line with five sensors and stop on an obstacle. The same 24 sensor transitions (including
obstacle on/off, line lost, junction and multi-sensor patterns) are applied to every implementation at random phases
of its control loop. Each one must match the same reference model on every transition (0 missed), so the comparison is
between *equally correct* implementations.

| | Implementation | Source |
|---|---|---|
| A | Software only: GPIO pins, software PWM, software obstacle check | `programs/bench/bench_sw.S` |
| B | Hardware PWM + hardware reflex, steering in software through the memory-mapped registers | `programs/bench/bench_mmio.S` |
| C | Hardware PWM + reflex, steering with the `ROBOTSTEP` custom instruction | `programs/bench/bench_custom.S` |
| D | Autonomous hardware mode, the CPU only configures it once | `programs/bench/bench_auto.S` |

## Results (simulation, cycle-accurate; CPI = 1 so cycles = instructions)

| Implementation | Program (words) | Decision path (instr.) avg [min-max] | Reaction latency, cycles avg / max | Reaction latency avg / max @ 6.25 MHz | CPU load of motor control @ 256-cycle period | Left-motor PWM duty, centre line (ideal 27.3 %) |
|---|---|---|---|---|---|---|
| A. Software only (GPIO + software PWM, software obstacle check) | 46 | 14 [5-18] | 188 / 291 | 30.08 us / 46.56 us | ~100 % (PWM loop never stops) | 25 % |
| B. Hardware PWM + reflex, software steering (memory-mapped) | 35 | 13 [6-17] | 19 / 37 | 3.04 us / 5.92 us | 5.1 % | 27 % |
| C. Hardware PWM + reflex, `ROBOTSTEP` custom instruction | 5 | 1 [1-1] | 4 / 5 | 0.64 us / 0.80 us | 0.4 % | 27 % |
| D. Autonomous hardware mode (CPU free) | 5 | 0 (none) | 3 / 3 | 0.48 us / 0.48 us | 0.0 % | 27 % |

*Time columns assume the default board CPU clock of 6.25 MHz; cycle counts are clock-independent.*

## How to read it

- **Reaction latency** - cycles from a sensor change until the motor command has the new value. A includes the rest of
  its software PWM period; D is just the synchronizer (2) plus the reflex register (1).
- **Decision path** - instructions between the start and end of one steering decision. B and A execute the same
  software table (13-14 instructions); `ROBOTSTEP` replaces it with **one** instruction.
- **CPU load** - share of CPU cycles consumed by motor control at one update per 256-cycle PWM period. In A the PWM
  loop itself never stops, so the CPU is fully occupied; in B-D PWM is hardware.
- **PWM duty** - the 70/255 command should give 27.3 %. Software PWM gives 25 % (quantisation and loop overhead) and
  has jitter; hardware PWM is exact.

## What the numbers do *not* say

- Moving steering from software (B) to `ROBOTSTEP` (C) saves **12-13 instructions per update**. Moving PWM into
  hardware (A -> B) saves far more: it frees the CPU entirely.
- These are simulation results on the RTL; no board or robot measurement is included here.
- B and C poll as fast as they can; a real program would run its loop at the control rate and use the free cycles.

## Reproduce

```bash
./simulation/run_robotics.sh        # runs everything and prints this table
python3 simulation/bench_chart.py build/robotics/bench.log images/benchmark_comparison.png
```
