#!/usr/bin/env bash
# BeetrootOS - Attach GDB (Bash / WSL / Linux / macOS)
# Usage: ./scripts/debug-gdb.sh

set -e

KERNEL="target/riscv64gc-unknown-none-elf/debug/beetroot-os"

if [ ! -f "$KERNEL" ]; then
    echo "Kernel binary not found. Building debug binary..."
    cargo build
fi

GDB=""
for cand in riscv64-unknown-elf-gdb riscv-none-elf-gdb gdb-multiarch gdb; do
    if command -v "$cand" &> /dev/null; then
        GDB="$cand"
        break
    fi
done

if [ -z "$GDB" ]; then
    echo "Error: No RISC-V compatible GDB found."
    echo "Install via: sudo apt install gdb-multiarch (Ubuntu/Debian)"
    exit 1
fi

echo "==> Launching GDB ($GDB) connecting to localhost:1234..."
$GDB -ex "target remote :1234" -ex "file $KERNEL" -ex "set architecture riscv:rv64"

