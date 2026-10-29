#!/usr/bin/env bash
# BeetrootOS - Run in QEMU (Bash / WSL / Linux / macOS)
# Usage: ./scripts/run-qemu.sh [--release] [--debug]

set -e

RELEASE=0
DEBUG=0

for arg in "$@"; do
    case "$arg" in
        --release) RELEASE=1 ;;
        --debug)   DEBUG=1 ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

if [ "$RELEASE" -eq 1 ]; then
    PROFILE="release"
    BUILD_ARG="--release"
else
    PROFILE="debug"
    BUILD_ARG=""
fi

echo "==> Building BeetrootOS ($PROFILE profile)..."
cargo build $BUILD_ARG

KERNEL="target/riscv64gc-unknown-none-elf/$PROFILE/beetroot-os"

if ! command -v qemu-system-riscv64 &> /dev/null; then
    echo "Error: qemu-system-riscv64 not found in PATH."
    echo "Install via: sudo apt install qemu-system-misc (Ubuntu/Debian) or brew install qemu (macOS)"
    exit 1
fi

QEMU_ARGS=(
    -machine virt
    -bios default
    -nographic
    -serial mon:stdio
    -kernel "$KERNEL"
)

if [ "$DEBUG" -eq 1 ]; then
    echo "==> Waiting for GDB on :1234 (halted at reset)..."
    QEMU_ARGS+=(-s -S)
else
    echo "==> Launching BeetrootOS in QEMU (Press Ctrl+A then X to exit)..."
fi

qemu-system-riscv64 "${QEMU_ARGS[@]}"

