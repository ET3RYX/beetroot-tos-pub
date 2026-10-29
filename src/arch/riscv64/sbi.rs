//! RISC-V Supervisor Binary Interface (SBI) Primitives
//!
//! Provides minimal wrappers around SBI `ecall` instructions for Supervisor-mode execution.

/// Legacy SBI extension ID for console character output.
#[allow(dead_code)]
const SBI_CONSOLE_PUTCHAR: usize = 1;

/// Legacy SBI extension ID for system shutdown.
#[allow(dead_code)]
const SBI_SHUTDOWN: usize = 8;

/// Issue a legacy SBI call with 3 arguments.
#[allow(dead_code)]
#[inline(always)]
fn sbi_call_legacy(eid: usize, arg0: usize, arg1: usize, arg2: usize) -> usize {
    let ret: usize;
    unsafe {
        core::arch::asm!(
            "ecall",
            inlateout("a0") arg0 => ret,
            in("a1") arg1,
            in("a2") arg2,
            in("a7") eid,
        );
    }
    ret
}

/// Write a single character to the debug console using OpenSBI.
#[allow(dead_code)]
#[inline(always)]
pub fn console_putchar(c: u8) {
    sbi_call_legacy(SBI_CONSOLE_PUTCHAR, c as usize, 0, 0);
}

/// Request system shutdown via OpenSBI legacy extension.
#[allow(dead_code)]
#[inline(always)]
pub fn shutdown() -> ! {
    sbi_call_legacy(SBI_SHUTDOWN, 0, 0, 0);
    loop {
        unsafe {
            core::arch::asm!("wfi");
        }
    }
}
