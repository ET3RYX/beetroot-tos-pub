//! RV64 Architecture Subsystem
//!
//! Contains architecture-specific assembly, SBI calls, and processor primitives.

core::arch::global_asm!(include_str!("entry.s"));

pub mod sbi;

