OUTPUT_ARCH(riscv)
ENTRY(_start)

/*
 * QEMU virt machine physical memory map:
 *   0x1000_0000: 16550A UART
 *   0x8000_0000: Base of DRAM
 *   0x8000_0000 - 0x8020_0000: OpenSBI firmware memory (M-mode)
 *   0x8020_0000: Kernel payload entry point (S-mode)
 */
BASE_ADDRESS = 0x80200000;

SECTIONS
{
    . = BASE_ADDRESS;
    skernel = .;

    stext = .;
    .text : {
        *(.text.entry)
        *(.text .text.*)
    }
    . = ALIGN(4K);
    etext = .;

    srodata = .;
    .rodata : {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    }
    . = ALIGN(4K);
    erodata = .;

    sdata = .;
    .data : {
        *(.data .data.*)
        *(.sdata .sdata.*)
    }
    . = ALIGN(4K);
    edata = .;

    sbss = .;
    .bss : {
        *(.bss.stack)
        *(.bss .bss.*)
        *(.sbss .sbss.*)
    }
    . = ALIGN(4K);
    ebss = .;

    ekernel = .;

    /DISCARD/ : {
        *(.eh_frame)
    }
}

