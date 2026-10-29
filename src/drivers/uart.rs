//! 16550A UART (Universal Asynchronous Receiver/Transmitter) Driver
//!
//! Provides a low-level, volatile MMIO driver for the National Semiconductor
//! 16550A-compatible UART on the RISC-V QEMU `virt` machine.
//!
//! # Hardware Overview (QEMU `virt`)
//! - Base Physical Address: `0x1000_0000`
//! - Register Width: 8 bits (byte-accessed at 1-byte offsets)
//!
//! # Register Map (Offsets from Base)
//! - `0x00` (R): Receiver Buffer Register (RBR) - received data byte
//! - `0x00` (W): Transmitter Holding Register (THR) - data byte to transmit
//! - `0x00` (RW, DLAB=1): Divisor Latch Low byte (DLL)
//! - `0x01` (RW, DLAB=0): Interrupt Enable Register (IER)
//! - `0x01` (RW, DLAB=1): Divisor Latch High byte (DLM)
//! - `0x02` (W): FIFO Control Register (FCR)
//! - `0x02` (R): Interrupt Identification Register (IIR)
//! - `0x03` (RW): Line Control Register (LCR)
//! - `0x04` (RW): Modem Control Register (MCR)
//! - `0x05` (R): Line Status Register (LSR)
//!
//! # Volatile Semantics
//! All register accesses MUST use `read_volatile` and `write_volatile`.
//! Hardware register state changes asynchronously with respect to CPU execution.
//! Non-volatile accesses could be hoisted out of polling loops or eliminated by
//! compiler dead-store elimination.

pub const UART_BASE_ADDR: usize = 0x1000_0000;

// Register bit masks
const LSR_THRE: u8 = 1 << 5; // Transmitter Holding Register Empty

pub struct Uart16550 {
    base: usize,
}

impl Uart16550 {
    /// Creates a new UART handle for the given base address.
    pub const fn new(base: usize) -> Self {
        Self { base }
    }

    /// Initializes the 16550A UART hardware.
    ///
    /// # Safety
    /// Must only be called once during early kernel initialization while MMU is disabled
    /// or when identity-mapped. `base` must point to valid 16550 MMIO registers.
    pub unsafe fn init(&self) {
        let ptr = self.base as *mut u8;

        // 1. Disable all interrupts (IER = 0)
        ptr.add(1).write_volatile(0x00);

        // 2. Enable Divisor Latch Access Bit (DLAB = 1 in LCR) to configure baud rate
        ptr.add(3).write_volatile(0x80);

        // 3. Set divisor to 38400 baud (divisor = 3 with standard 1.8432 MHz clock)
        ptr.add(0).write_volatile(0x03); // DLL
        ptr.add(1).write_volatile(0x00); // DLM

        // 4. Configure Line Control: 8 data bits, no parity, 1 stop bit (8N1), clear DLAB
        ptr.add(3).write_volatile(0x03);

        // 5. Enable and clear FIFOs (FCR: enable FIFO, clear TX/RX, 14-byte threshold)
        ptr.add(2).write_volatile(0x07);

        // 6. Enable modem control lines: DTR and RTS asserted (MCR)
        ptr.add(4).write_volatile(0x03);
    }

    /// Transmits a single byte via the UART.
    ///
    /// If `c` is a newline (`\n`), a carriage return (`\r`) is emitted first
    /// to ensure standard CRLF line termination on serial consoles.
    pub fn putc(&self, c: u8) {
        if c == b'\n' {
            self.write_byte_raw(b'\r');
        }
        self.write_byte_raw(c);
    }

    /// Polls the Line Status Register until the transmit buffer is empty,
    /// then writes `byte` to the Transmitter Holding Register.
    fn write_byte_raw(&self, byte: u8) {
        let ptr = self.base as *mut u8;
        unsafe {
            // Wait for Transmitter Holding Register Empty (THRE, bit 5)
            while (ptr.add(5).read_volatile() & LSR_THRE) == 0 {
                core::hint::spin_loop();
            }
            // Write byte to Transmitter Holding Register
            ptr.add(0).write_volatile(byte);
        }
    }
}

