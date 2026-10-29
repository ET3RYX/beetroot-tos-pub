# Memory Management Subsystem (`src/memory`)

This module manages physical frames and Sv39 virtual memory translation.

## Planned Architecture
- **Physical Memory:**
  - Page frame size: 4096 bytes (4 KiB).
  - Physical memory tracker: simple bitmap or free-list frame allocator managing available DRAM past the kernel image.
- **Virtual Memory:**
  - RV64 Sv39 paging (3-level page table, 39-bit virtual address space, 56-bit physical address space).
  - Page table entry (PTE) flags: `V` (valid), `R` (read), `W` (write), `X` (execute), `U` (user), `A` (accessed), `D` (dirty).
  - Kernel memory mapping: direct physical mapping (identity map) and higher-half mapping options.

## Milestone Activation
- Physical Memory: **Milestone 5**
- Virtual Memory (Sv39): **Milestone 6**

