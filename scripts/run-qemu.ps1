# BeetrootOS - Run in QEMU (PowerShell)
# Usage: .\scripts\run-qemu.ps1 [-Release] [-DebugMode]

param(
    [switch]$Release,
    [switch]$DebugMode
)

$ErrorActionPreference = "Stop"

# Determine target binary
$profile = if ($Release) { "release" } else { "debug" }
$buildArg = if ($Release) { "--release" } else { "" }

Write-Host "==> Building BeetrootOS ($profile profile)..." -ForegroundColor Cyan
if ($buildArg) {
    cargo build $buildArg
} else {
    cargo build
}

$kernelBin = "target/riscv64gc-unknown-none-elf/$profile/beetroot-os"

if (-not (Test-Path $kernelBin)) {
    Write-Error "Kernel binary not found at $kernelBin"
    exit 1
}

# Check for QEMU in PATH or standard installation paths
$qemuBin = (Get-Command qemu-system-riscv64 -ErrorAction SilentlyContinue).Source
if (-not $qemuBin) {
    $candidates = @(
        "C:\Program Files\qemu\qemu-system-riscv64.exe",
        "$env:LOCALAPPDATA\Programs\qemu\qemu-system-riscv64.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $qemuBin = $cand
            break
        }
    }
}

if (-not $qemuBin) {
    Write-Warning "qemu-system-riscv64 was not found in PATH or standard locations."
    Write-Host "Please install QEMU using winget or add it to PATH:"
    Write-Host "  winget install SoftwareFreedomConservancy.QEMU"
    exit 1
}

$qemuArgs = @(
    "-machine", "virt",
    "-bios", "default",
    "-nographic",
    "-serial", "mon:stdio",
    "-kernel", $kernelBin
)

if ($DebugMode) {
    Write-Host "==> Launching QEMU in debug mode (waiting for GDB on :1234)..." -ForegroundColor Yellow
    $qemuArgs += @("-s", "-S")
} else {
    Write-Host "==> Launching BeetrootOS in QEMU (Press Ctrl+A then X to exit)..." -ForegroundColor Green
}

& $qemuBin @qemuArgs

