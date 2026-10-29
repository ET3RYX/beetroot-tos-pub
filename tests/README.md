# BeetrootOS Testing Strategy

BeetrootOS uses a multi-tier testing strategy suitable for an educational operating system:

## 1. Host-Side Unit Tests
- Subsystems and data structures that do not rely on privileged RISC-V hardware instructions (e.g. physical frame bitmap/free lists, virtual address formatting, page table flags, circular buffers, process state machines) are written with standard Rust abstractions or conditionally enabled `std` harnesses.
- Run on host:
  ```powershell
  cargo test --target x86_64-pc-windows-msvc
  ```

## 2. QEMU Automated Boot & Smoke Tests
- In later milestones, automated tests launch QEMU with `-device test-exit` (or the SiFive test device `0x100000`) so the kernel can signal test success (`0x5555`) or failure (`0x3333`) directly to the host test runner script.
- Scripted execution verifies that early boot, UART printing, trap dispatch, and memory initialization complete successfully without hanging.

## 3. Host Integration Tests
- Integration tests in this directory (`tests/`) test modules through public interfaces and verify reproducible invariants across builds.

