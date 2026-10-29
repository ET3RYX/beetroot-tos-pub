# Architecture Layer (`src/arch`)

This module encapsulates all hardware-specific code, keeping architecture-independent kernel logic cleanly separated from processor internals.

## Directory Structure
- `riscv64/`: Implementation for the 64-bit RISC-V (RV64GC) architecture.
  - S-mode CSR register definitions and manipulation (`sstatus`, `stvec`, `satp`, `scause`, `sepc`, `stval`, `sie`, `sip`).
  - Low-level assembly primitives (context switching, trap vector entry/exit).
  - OpenSBI binary interface (SBI calls).

## Milestone Activation
- Activated in **Milestone 2** (Boot and early kernel) and **Milestone 4** (RISC-V architecture layer).

