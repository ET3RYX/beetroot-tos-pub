//! Kernel Console and Formatted Output Subsystem
//!
//! Provides `#![no_std]` formatted printing via standard Rust macros (`print!`, `println!`).
//!
//! # Architecture & Concurrency
//! - Primary Hardware Backend: 16550A UART MMIO driver at `0x1000_0000`.
//! - Concurrency Model: Currently runs on a single core (Hart 0) with interrupts disabled
//!   during early boot. No lock is required at this stage.
//! - Future Multi-Hart / Interrupt Consideration: When timer interrupts or multi-core SMP
//!   are introduced, console output must be guarded by an interrupt-disabling spinlock
//!   to prevent interleaved log messages.

use core::fmt::{self, Write};
use crate::drivers::uart::{Uart16550, UART_BASE_ADDR};

/// Global UART hardware instance.
static UART: Uart16550 = Uart16550::new(UART_BASE_ADDR);

/// Zero-sized console formatting adapter that implements `core::fmt::Write`.
pub struct ConsoleWriter;

impl Write for ConsoleWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for b in s.bytes() {
            UART.putc(b);
        }
        Ok(())
    }
}

/// Initializes the console hardware (16550A UART).
pub fn init() {
    unsafe {
        UART.init();
    }
}

/// Internal entry point for `print!` and `println!` macros.
///
/// Dispatches formatted arguments to `ConsoleWriter`. Errors are ignored
/// so printing within panic handlers cannot trigger recursive panics.
pub fn _print(args: fmt::Arguments) {
    let mut writer = ConsoleWriter;
    let _ = writer.write_fmt(args);
}

/// Prints formatted text to the kernel serial console.
#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => {
        $crate::console::_print(core::format_args!($($arg)*))
    };
}

/// Prints formatted text to the kernel serial console, followed by a newline.
#[macro_export]
macro_rules! println {
    () => {
        $crate::print!("\n")
    };
    ($($arg:tt)*) => {{
        $crate::console::_print(core::format_args!($($arg)*));
        $crate::console::_print(core::format_args!("\n"));
    }};
}

