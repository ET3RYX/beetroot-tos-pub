# BeetrootOS Architecture

BeetrootOS is a small, Unix-like, monolithic operating system kernel written in Rust for the 64-bit RISC-V architecture (`RV64GC`), designed for execution on the QEMU `virt` machine platform under OpenSBI firmware.

## 1. System Overview

- **Kernel Model:** Monolithic kernel executing in Supervisor Mode (`S-mode`).
- **Target Platform:** QEMU `virt` board (`qemu-system-riscv64 -machine virt`).
- **Memory Model:** Physical memory direct addressing during early boot, transitioning to Sv39 virtual memory (3-level page tables, 4 KiB pages).
- **Core Philosophy:** Educational clarity, explicit hardware abstractions, minimal `#![no_std]` footprint, and strict empirical verification.

```
+---------------------------------------------------------------+
|                      User Applications                        |
+---------------------------------------------------------------+
                             | (ecall / syscalls)
                             v
+---------------------------------------------------------------+
|                 BeetrootOS Kernel (S-mode)                    |
|                                                               |
|  +---------------------+  +--------------------------------+  |
|  | Process Management  |  | Virtual Memory Management      |  |
|  | - Task State        |  | - Sv39 3-level page tables     |  |
|  | - Context Switch    |  | - Address space isolation      |  |
|  | - Scheduler         |  | - Frame allocator (4 KiB)      |  |
|  +---------------------+  +--------------------------------+  |
|                                                               |
|  +---------------------+  +--------------------------------+  |
|  | Trap Handling       |  | Console & Device Drivers       |  |
|  | - stvec vector      |  | - 16550A UART MMIO driver      |  |
|  | - Exception dispatch|  | - print! / println! formatting |  |
|  | - Timer ticks       |  | - Diagnostic panic handler     |  |
|  +---------------------+  +--------------------------------+  |
|                                                               |
|  +---------------------------------------------------------+  |
|  | Architecture Abstraction Layer (`src/arch/riscv64`)     |  |
|  | - Assembly boot entry (_start) & 64 KiB stack setup     |  |
|  | - BSS zeroing loop                                      |  |
|  | - OpenSBI SBI ecall wrappers                            |  |
|  +---------------------------------------------------------+  |
+---------------------------------------------------------------+
                             | (SBI ecalls)
                             v
+---------------------------------------------------------------+
|                   OpenSBI Firmware (M-mode)                   |
+---------------------------------------------------------------+
                             |
                             v
+---------------------------------------------------------------+
|               QEMU `virt` Hardware Platform                   |
|   RAM (0x8000_0000+), UART (0x1000_0000), CLINT, PLIC         |
+---------------------------------------------------------------+
```

## 2. Physical Memory Map on QEMU `virt`

| Address Range | Device / Memory | Description |
|---|---|---|
| `0x0000_1000` - `0x0001_1000` | QEMU Boot ROM | Reset vector and device tree setup |
| `0x0200_0000` - `0x0201_0000` | CLINT / ACLINT | Core local interruptor (timer & IPI) |
| `0x0c00_0000` - `0x1000_0000` | PLIC | Platform-level interrupt controller |
| `0x1000_0000` - `0x1000_0100` | 16550A UART | Serial communication console (MMIO) |
| `0x1000_1000` - `0x1000_8000` | VirtIO MMIO | VirtIO block device and peripherals |
| `0x8000_0000` - `0x8020_0000` | OpenSBI DRAM | Machine-mode firmware memory (2 MB) |
| `0x8020_0000` - `0x8020_xxxx` | Kernel ELF | BeetrootOS code, read-only data, static BSS |
| `0x8020_xxxx` - `0x8800_0000+`| Free DRAM | Physical frame pool for page allocation |

## 3. 16550A UART Console Architecture

The kernel uses a dedicated, volatile memory-mapped driver for the 16550A UART peripheral at `0x1000_0000`:

- **Registers (1-byte offsets):**
  - Offset `0`: RBR (Receive Buffer, Read) / THR (Transmit Holding, Write) / DLL (Baud Divisor Low, DLAB=1).
  - Offset `1`: IER (Interrupt Enable, DLAB=0) / DLM (Baud Divisor High, DLAB=1).
  - Offset `2`: FCR (FIFO Control, Write) / IIR (Interrupt Ident, Read).
  - Offset `3`: LCR (Line Control, Read/Write).
  - Offset `4`: MCR (Modem Control, Read/Write).
  - Offset `5`: LSR (Line Status, Read).
- **Volatile MMIO Access:** Uses `core::ptr::read_volatile` and `core::ptr::write_volatile` to prevent compiler reordering or dead-store elimination.
- **Polling Transmission:** Polls Bit 5 (`THRE`, Transmitter Holding Register Empty) of LSR before writing to THR.
- **Line Ending:** Automatically emits `\r` before each `\n` to guarantee proper CRLF wrapping on serial terminals.
- **Formatting Interface:** Implements `core::fmt::Write` on a zero-sized `ConsoleWriter`, powering `#![no_std]` `print!` and `println!` macros without dynamic heap allocation.

