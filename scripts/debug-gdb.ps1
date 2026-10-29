# BeetrootOS - Attach GDB (PowerShell)
# Usage: .\scripts\debug-gdb.ps1

$ErrorActionPreference = "Stop"

$kernelBin = "target/riscv64gc-unknown-none-elf/debug/beetroot-os"

if (-not (Test-Path $kernelBin)) {
    Write-Host "Kernel binary not found. Building debug binary..."
    cargo build
}

# Search for suitable RISC-V GDB executable
$gdbCandidates = @(
    "riscv64-unknown-elf-gdb",
    "riscv-none-elf-gdb",
    "gdb-multiarch",
    "gdb"
)

$gdbBin = $null
foreach ($name in $gdbCandidates) {
    $found = (Get-Command $name -ErrorAction SilentlyContinue).Source
    if ($found) {
        $gdbBin = $found
        break
    }
}

if (-not $gdbBin) {
    Write-Warning "No RISC-V compatible GDB binary was found in PATH."
    Write-Host "Recommended options for Windows:"
    Write-Host "  1. Download xPack GNU RISC-V Embedded GCC (includes riscv-none-elf-gdb.exe)"
    Write-Host "  2. Or use WSL2 / MSYS2 with gdb-multiarch"
    exit 1
}

Write-Host "==> Launching GDB ($gdbBin) connecting to localhost:1234..." -ForegroundColor Green
& $gdbBin -ex "target remote :1234" -ex "file $kernelBin" -ex "set architecture riscv:rv64"

