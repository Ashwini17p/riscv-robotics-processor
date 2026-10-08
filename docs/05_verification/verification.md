# Verification

## Instruction-level testbench

`tb/.test/tb_1c.v` instantiates `t1_riscv_cpu`, runs `rv32i_test_1c.hex` (79 words) and, as each instruction retires,
compares the architectural result (register write-back value, store address / data, branch / jump behaviour) with the
expected value. Branch instructions are tested with small loops so both the taken and not-taken paths execute.

Result: **38 checks, 0 faulty instructions** (`No errors encountered, congratulations!`).

## Unit testbenches (`tb/unit`)

| Bench | Checks | Waveform |
|---|---|---|
| `alu_tb.sv` | each operation, signed / unsigned compare, shift corner cases, overflow wrap | `images/alu_sim.png` |
| `pc_tb.sv` | reset value, +4 progression | `images/pc_sim.png` |
| `register_file_tb.sv` | write / read, multiple writes, `x0` stays 0, same-register read | `images/register_file_sim.png` |

## Reproduce

```bash
./simulation/run_t1c.sh
./simulation/run_unit_tests.sh
```

## Robotics extension

| Bench | Scope |
|---|---|
| `tb_robotics_unit/mmio/reflex/motor_pwm/top` | each block and the standalone subsystem (20 checks) |
| `robot_soc_isa_tb` + `programs/test/rbt_isa_test.S` | the CPU executes `RSENSOR`, `MOTORCMD`, `ROBOTSTEP`, register-map reads/writes, GPIO and `lui`, self-checking |
| `t1_wrapper_rbt` + `tb_1c` | regression: the robotics core still passes the original 38 checks |
| `robot_bench_tb` | four implementations vs. one reference model on 24 sensor transitions; also measures latency and CPU load |
| `fpga_top_smoke_tb` | Basys 3 top in free-run mode: PWM duty on the motor pins for four sensor cases |

```bash
./simulation/run_robotics.sh
```

## Known gaps

- **`lui` with a non-zero register in the rs1 field returns a wrong value in `rtl/t1_riscv_cpu`** (see Known issues in
  `docs/02_architecture/single_cycle_core.md`). It is fixed in `rtl/robot_cpu` and covered by `rbt_isa_test.S`.
- No hardware measurements of the robot yet; every robotics result is from RTL simulation.
- Checking is directed, not random; there is no functional-coverage collection yet.
- Loads / stores are tested at a few addresses; misaligned accesses are out of scope (undefined behaviour).
- The datapath still contains `$display` debug traces (`MEM TRACE`, `LOAD DEBUG`); they are simulation-only but should be
  guarded or removed before synthesis-focused releases.
- Next: a constrained-random instruction generator checked against a reference model, and the same checks on the
  pipelined core.
