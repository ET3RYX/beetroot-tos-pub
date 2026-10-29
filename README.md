# BeetrootOS

A small, Unix-like, monolithic operating system kernel written in Rust for the 64-bit RISC-V architecture (`RV64GC`), running on the QEMU `virt` platform under OpenSBI firmware.

BeetrootOS is an educational operating system designed to explore operating-system architecture, hardware-software interfaces, design trade-offs, and systems programming through disciplined, test-driven incremental milestones.

---

## 2. Hardware & Boot Model

- **Architecture:** 64-bit RISC-V (`RV64GC` — integer, multiply/divide, atomics, single/double float, compressed instructions).
- **Execution Platform:** QEMU `virt` machine (`-machine virt`).
- **Privilege Mode:** Supervisor Mode (`S-mode`).
- **Firmware Boot Interface:** Booted via default OpenSBI firmware loaded at `0x8000_0000`. OpenSBI initializes Machine Mode (`M-mode`), delegates Supervisor traps, and passes control to the kernel at `0x8020_0000`:
  - Register `a0`: Hart ID (`0` for boot core).
  - Register `a1`: Physical memory address of the Device Tree Blob (DTB).
- **Console Device:** 16550A-compatible UART memory-mapped at `0x1000_0000`.

Detailed documentation:
- [System Architecture](docs/architecture.md)
- [RISC-V Privileged Boot Flow](docs/boot-flow.md)

---

## 3. Repository Layout

```
beetroot-os-public/
├── .cargo/
│   └── config.toml             # Target configuration (riscv64gc-unknown-none-elf) & rustflags
├── docs/
│   ├── architecture.md         # System architecture, components, and memory map
│   └── boot-flow.md            # RISC-V privilege modes and boot sequence details
├── linker/
│   └── riscv64-virt.ld         # Memory layout starting at 0x8020_0000 with 4 KiB aligned sections
├── scripts/
│   ├── run-qemu.ps1            # PowerShell launcher for QEMU (normal and debug modes)
│   ├── run-qemu.sh             # Bash launcher for QEMU (Linux / macOS / WSL)
│   ├── debug-gdb.ps1           # PowerShell GDB attach helper
│   ├── debug-gdb.sh            # Bash GDB attach helper
│   └── test-boot.ps1           # Automated PowerShell QEMU boot test runner
├── src/
│   ├── arch/                   # Architecture abstraction layer
│   │   ├── riscv64/            # RV64-specific assembly, CSRs, and SBI calls
│   │   │   ├── entry.s         # Boot entry point (_start) and 64 KiB stack allocation
│   │   │   ├── mod.rs          # Architecture module definition
│   │   │   └── sbi.rs          # OpenSBI firmware ecall wrappers
│   │   └── mod.rs
│   ├── drivers/                # Device drivers
│   │   ├── uart.rs             # 16550A UART MMIO driver (volatile polling, CRLF translation)
│   │   └── mod.rs
│   ├── console.rs              # core::fmt::Write adapter and print! / println! macros
│   └── main.rs                 # Kernel entry (rust_main), boot diagnostics, panic handler
├── tests/
│   └── README.md               # Testing strategy
├── .gitignore                  # Git ignore rules for build artifacts
├── Cargo.lock                  # Pinned dependency lockfile
├── Cargo.toml                  # Kernel package definition
└── README.md                   # Project overview and quick start guide
```

---

## 4. Prerequisites

To build and run BeetrootOS, install:

1. **Rust Toolchain:**
   - Stable Rust compiler (tested with Rust 1.95.0+).
   - RISC-V target:
     ```bash
     rustup target add riscv64gc-unknown-none-elf
     ```
   - LLVM tools (includes `rust-lld` linker):
     ```bash
     rustup component add llvm-tools-preview
     ```
2. **Binary Inspection Tools (Optional but Recommended):**
   ```bash
   cargo install cargo-binutils
   ```
3. **Emulator:**
   - **QEMU:** `qemu-system-riscv64` (version 8.0+ or 11.0+).
     - Windows: `winget install SoftwareFreedomConservancy.QEMU`
     - Ubuntu/Debian: `sudo apt install qemu-system-misc`
     - macOS: `brew install qemu`

---

## 5. Build, Run, and Test Instructions

### 1. Build the Kernel
```powershell
# Debug profile (generates target/riscv64gc-unknown-none-elf/debug/beetroot-os)
cargo build

# Release profile (with LTO and optimizations)
cargo build --release
```

### 2. Inspect the ELF Binary
```powershell
# Inspect memory section sizes and load addresses
cargo size --bin beetroot-os -- -A

# Disassemble kernel instructions
cargo objdump --bin beetroot-os -- -d
```

### 3. Run in QEMU
```powershell
# Using the PowerShell runner:
.\scripts\run-qemu.ps1

# Or run directly via QEMU CLI:
qemu-system-riscv64 -machine virt -bios default -nographic -serial mon:stdio -kernel target/riscv64gc-unknown-none-elf/debug/beetroot-os

# To exit QEMU at any time: Press Ctrl+A, then release and press X.
```

### 4. Run Automated Boot Test
An automated test script launches QEMU, captures serial output, and validates all boot markers:
```powershell
# Run automated verification test
powershell -ExecutionPolicy Bypass -File .\scripts\test-boot.ps1
```

Expected output:
```text
  [PASS] Milestone 3 Completion Marker
  [PASS] Primary Hart ID Formatting
  [PASS] DTB Address Formatting
  [PASS] Kernel Range Formatting
  [PASS] BSS Zeroing Test
  [PASS] BSS Write Test

==> SUCCESS: BeetrootOS UART console and formatted diagnostics verified!
```

---

## 6. Current Limitations

1. **Unbuffered UART:** Character output currently uses polling on the Transmitter Holding Register Empty (`THRE`) bit. Interrupt-driven buffering will be introduced in Milestone 9.
2. **Single-Hart Execution:** Currently executes on boot core (Hart 0); additional harts remain parked in OpenSBI until multi-core initialization.
3. **Paging Disabled:** Operates in physical memory addressing before virtual memory (Sv39 page tables) is enabled in Milestone 6.

