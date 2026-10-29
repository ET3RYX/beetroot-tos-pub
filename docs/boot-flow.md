# RISC-V Privileged Architecture and Boot Flow

This document details the boot protocol, privilege transitions, and early initialization sequence for BeetrootOS.

## 1. RISC-V Privilege Modes

RISC-V defines three standard hardware privilege levels:

| Mode | Name | Privilege Level | Role in BeetrootOS |
|---|---|---|---|
| **M** | Machine Mode | Highest (untranslated physical memory) | OpenSBI firmware (hardware reset, PMP, timer delegation) |
| **S** | Supervisor Mode | Intermediate (address translation via `satp`) | BeetrootOS Monolithic Kernel |
| **U** | User Mode | Lowest (strict isolation) | User-space applications and tasks |

## 2. Boot Sequence on QEMU `virt` with OpenSBI

When QEMU launches with `-machine virt -bios default -kernel beetroot-os`:

1. **Hardware Reset (M-mode):**
   - Execution begins at the QEMU reset vector (`0x1000`).
   - Control transfers to OpenSBI loaded at `0x8000_0000`.

2. **OpenSBI Firmware Initialization (M-mode):**
   - Configures Physical Memory Protection (PMP) registers.
   - Initializes platform timers and serial controller.
   - Sets up Supervisor Mode execution environment.
   - Prepares boot arguments in registers:
     - `a0`: Hart ID (hardware thread ID, `0` for primary core).
     - `a1`: Physical memory address of the Device Tree Blob (DTB).
   - Jumps to the kernel entry payload at `0x8020_0000` in **Supervisor Mode (S-mode)**.

3. **Kernel Entry (`_start` in `src/arch/riscv64/entry.s`):**
   - **Stack Initialization:** Points `sp` to `boot_stack_top` (a 64 KiB stack allocated in `.section .bss.stack, "aw", @nobits`, 4 KiB aligned).
   - **Frame Pointer Reset:** Sets `fp` (`s0`) to 0 for clean debugger stack unwinding.
   - **BSS Clearing:** Clears all bytes from `sbss` to `ebss` using 8-byte stores (`sd zero, 0(t0)`).
   - **Argument Preservation:** Registers `a0` and `a1` remain unaltered during stack and BSS setup.
   - **Call Kernel:** Invokes `call rust_main` according to standard RISC-V calling conventions.

4. **Rust Kernel Main (`rust_main` in `src/main.rs`):**
   - Initializes the 16550A UART MMIO driver (`0x1000_0000`).
   - Reports preserved boot arguments (`hart_id` in `a0`, `dtb_pa` in `a1`).
   - Displays kernel memory range and section boundaries (`.text`, `.rodata`, `.data`, `.bss`, `boot_stack`).
   - Empirically verifies BSS zeroing and writability via static `BSS_ZERO_CHECK`.
   - Halts the core in an idle `wfi` loop awaiting interrupts.

