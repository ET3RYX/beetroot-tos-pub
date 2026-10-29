# RV64 Architecture Subsystem (`src/arch/riscv64`)

Target architecture: **RV64GC** (64-bit RISC-V with Integer, Multiplication/Division, Atomic, Single-precision float, Double-precision float, and Compressed instructions).

## Key Responsibilities
1. **Boot Entry & Stack Setup:** Assembly entry routine (`entry.s` / `_start`).
2. **CSR Access:** Safe Rust wrappers around inline assembly for Supervisor-mode CSRs.
3. **OpenSBI SBI Interface:** Implementation of SBI ecall standard (Console, Timer, Reset).
4. **Trap Low-Level Context:** Saving and restoring register state (`trap.s`).

