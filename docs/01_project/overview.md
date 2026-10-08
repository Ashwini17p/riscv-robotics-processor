# Project overview

**Goal.** Design, verify and deploy a small RV32I processor that is simple enough to reason about end to end and that can
later control robotics hardware.

**Approach.** Build the CPU incrementally: a single-cycle reference core first (functionally complete, fully tested),
then a 5-stage pipelined version, then memory-mapped peripherals. Every stage is verified in simulation before it is
taken to the FPGA.

| Stage | Status |
|---|---|
| Single-cycle RV32I core, 38 / 38 instruction checks | done |
| SystemVerilog blocks: ALU, PC, register file + unit tests | done |
| Basys 3 bring-up (single-step clock, ILA, bitstream) | done |
| 5-stage pipeline (forwarding, load-use stall, branch flush) | in progress |
| Robotics subsystem: custom instructions, MMIO, PWM, reflex, autonomous mode, benchmark | done (simulation) |
| Robot run on hardware | next |

**Tool flow.** Icarus Verilog / ModelSim for simulation, Vivado 2025.1 for synthesis, implementation and ILA debug.
