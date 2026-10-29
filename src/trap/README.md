# Trap and Interrupt Subsystem (`src/trap`)

This module handles hardware exceptions, device interrupts, and software system calls.

## Planned Architecture
- **Trap Entry Vector (`stvec`):**
  - Points to the trap entry assembly routine (`__trap_vector`).
  - Saves all 32 general-purpose registers into a `TrapFrame` on the kernel stack.
- **Trap Handling Dispatcher:**
  - Decodes `scause` to distinguish:
    - Synchronous Exceptions: Instruction/Data Page Fault, Illegal Instruction, Breakpoint, Environment Call from U-mode (`ecall`).
    - Asynchronous Interrupts: Supervisor Software Interrupt (SSIP), Supervisor Timer Interrupt (STIP), Supervisor External Interrupt (SEIP).
- **System Call Dispatcher:**
  - Validates user pointers and arguments passed in registers `a0-a7`.

## Milestone Activation
- Trap vectors and exception handling: **Milestone 4**
- System call dispatch: **Milestone 8**
- Interrupts (timer, UART): **Milestone 9**

