//! BeetrootOS Kernel Main Entry
//!
//! Milestone 3: Console and Diagnostics.
//! Integrates 16550A UART driver with formatted `print!` / `println!` macros.

#![no_std]
#![no_main]

mod arch;
mod console;
mod drivers;

use core::panic::PanicInfo;

extern "C" {
    static skernel: u8;
    static ekernel: u8;
    static stext: u8;
    static etext: u8;
    static srodata: u8;
    static erodata: u8;
    static sdata: u8;
    static edata: u8;
    static sbss: u8;
    static ebss: u8;
    static boot_stack_bottom: u8;
    static boot_stack_top: u8;
}

/// Static variable allocated in `.bss` to verify that BSS was zeroed by `entry.s`.
static mut BSS_ZERO_CHECK: usize = 0;

/// Rust kernel entry point.
///
/// Called by `src/arch/riscv64/entry.s` with:
/// - `hart_id`: Hardware thread ID of the booting core (passed in `a0` by OpenSBI).
/// - `dtb_pa`: Physical address of the Device Tree Blob (passed in `a1` by OpenSBI).
#[no_mangle]
pub extern "C" fn rust_main(hart_id: usize, dtb_pa: usize) -> ! {
    // Initialize 16550A UART hardware console
    console::init();

    println!();
    println!("==================================================");
    println!("  BeetrootOS: Teaching-Grade RV64 Monolithic Kernel");
    println!("==================================================");
    println!("[boot] Entered rust_main() in Supervisor Mode.");

    // 1. Verify boot arguments preserved from OpenSBI
    println!("[boot] Primary Hart ID    : {} ({:#018x})", hart_id, hart_id);
    println!("[boot] Device Tree (DTB)  : {:#018x}", dtb_pa);

    // 2. Report linker section layout using formatted output
    let skernel_addr = core::ptr::addr_of!(skernel) as usize;
    let ekernel_addr = core::ptr::addr_of!(ekernel) as usize;
    println!("[boot] Kernel Memory Range: {:#018x} -> {:#018x}", skernel_addr, ekernel_addr);

    let stext_addr = core::ptr::addr_of!(stext) as usize;
    let etext_addr = core::ptr::addr_of!(etext) as usize;
    let srodata_addr = core::ptr::addr_of!(srodata) as usize;
    let erodata_addr = core::ptr::addr_of!(erodata) as usize;
    let sdata_addr = core::ptr::addr_of!(sdata) as usize;
    let edata_addr = core::ptr::addr_of!(edata) as usize;
    let sbss_addr = core::ptr::addr_of!(sbss) as usize;
    let ebss_addr = core::ptr::addr_of!(ebss) as usize;
    let stack_bot = core::ptr::addr_of!(boot_stack_bottom) as usize;
    let stack_top = core::ptr::addr_of!(boot_stack_top) as usize;

    println!("[boot] Section Boundaries:");
    println!("       .text      : {:#018x} -> {:#018x}", stext_addr, etext_addr);
    println!("       .rodata    : {:#018x} -> {:#018x}", srodata_addr, erodata_addr);
    println!("       .data      : {:#018x} -> {:#018x}", sdata_addr, edata_addr);
    println!("       .bss       : {:#018x} -> {:#018x}", sbss_addr, ebss_addr);
    println!("       boot_stack : {:#018x} -> {:#018x} (64 KiB)", stack_bot, stack_top);

    // 3. Verify BSS zeroing and writability
    unsafe {
        if BSS_ZERO_CHECK == 0 {
            println!("[boot] BSS zeroing test   : PASSED (BSS_ZERO_CHECK == 0)");
            // Mutate variable to verify writability
            BSS_ZERO_CHECK = 0xbeef_cafe;
            if BSS_ZERO_CHECK == 0xbeef_cafe {
                println!("[boot] BSS write test     : PASSED (BSS_ZERO_CHECK == 0xbeefcafe)");
            }
        } else {
            println!("[boot] BSS zeroing test   : FAILED!");
        }
    }

    println!("[boot] Milestone 3 (Console and Diagnostics) verified successfully!");
    println!("==================================================\n");

    // Park core awaiting interrupts (or next milestones)
    loop {
        unsafe {
            core::arch::asm!("wfi");
        }
    }
}

/// Panic handler required by `#![no_std]`.
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    println!("  KERNEL PANIC");
    println!("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    if let Some(location) = info.location() {
        println!("Location: {}:{}", location.file(), location.line());
    } else {
        println!("Location: unknown");
    }
    println!("Message : {}", info.message());
    println!("Halting system.");

    loop {
        unsafe {
            core::arch::asm!("wfi");
        }
    }
}
