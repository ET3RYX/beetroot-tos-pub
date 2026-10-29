# BeetrootOS - RISC-V 64 Boot Entry Assembly
# Target: RV64 Supervisor Mode (booted via OpenSBI firmware)

    .section .text.entry, "ax"
    .globl _start

_start:
    # OpenSBI firmware enters here in Supervisor Mode (S-mode) with:
    #   a0 = hartid (hardware thread ID of the booting core)
    #   a1 = dtb_pa (physical address of the Device Tree Blob in DRAM)
    #
    # We must preserve a0 and a1 across early initialization so they
    # can be passed as arguments to rust_main(hart_id, dtb_pa).

    # 1. Initialize the boot stack pointer to the top of our 64 KiB stack.
    la sp, boot_stack_top

    # 2. Reset frame pointer (s0 / fp) to terminate GDB stack backtraces cleanly.
    mv fp, zero

    # 3. Zero the BSS section (sbss to ebss).
    # Both sbss and ebss are 4 KiB aligned by the linker script,
    # ensuring they are always multiples of 8 bytes.
    la t0, sbss
    la t1, ebss

clear_bss_loop:
    bgeu t0, t1, clear_bss_done
    sd zero, 0(t0)
    addi t0, t0, 8
    j clear_bss_loop

clear_bss_done:
    # 4. Jump to the Rust kernel entry point.
    # RISC-V calling convention:
    #   Argument 0 (hart_id): in a0 (preserved)
    #   Argument 1 (dtb_pa):  in a1 (preserved)
    call rust_main

    # 5. Fallback halt loop: if rust_main ever returns, park the core.
park_core:
    wfi
    j park_core

# ---------------------------------------------------------------------
# Boot Stack Allocation (64 KiB)
# ---------------------------------------------------------------------
    .section .bss.stack, "aw", @nobits
    .align 12
    .globl boot_stack_bottom
boot_stack_bottom:
    .space 65536
    .globl boot_stack_top
boot_stack_top:

