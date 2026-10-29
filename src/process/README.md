# Process and Scheduling Subsystem (`src/process`)

This module manages kernel contexts, task structures, and execution scheduling.

## Planned Architecture
- **Task Control Block (TCB / `Proc`):**
  - Unique Process Identifier (PID).
  - Process execution state (`Ready`, `Running`, `Blocked`, `Zombie`).
  - Kernel stack and Trap context.
  - Page table root address (`satp` configuration).
- **Context Switch:**
  - Callee-saved register preservation (`ra`, `sp`, `s0-s11`) via `switch.s`.
- **Scheduler:**
  - Preemptive round-robin scheduler driven by timer interrupts.

## Milestone Activation
- Kernel execution and cooperative scheduling: **Milestone 7**
- Process lifecycle, fork, and timer preemption: **Milestone 9**

