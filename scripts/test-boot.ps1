# BeetrootOS - Automated QEMU Boot Verification (PowerShell)
# Usage: .\scripts\test-boot.ps1 [-Release]

param(
    [switch]$Release
)

$ErrorActionPreference = "Stop"

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
    Write-Error "qemu-system-riscv64 not found."
    exit 1
}

$tempLog = [System.IO.Path]::GetTempFileName()

try {
    Write-Host "==> Spawning QEMU with OpenSBI to verify boot sequence and UART console..." -ForegroundColor Yellow
    $p = Start-Process -FilePath $qemuBin -ArgumentList "-machine virt -bios default -nographic -serial file:$tempLog -kernel $kernelBin" -PassThru

    # Wait up to 5 seconds for kernel to boot and print diagnostics
    $timeout = 5
    $booted = $false
    for ($i = 0; $i -lt $timeout * 10; $i++) {
        Start-Sleep -Milliseconds 100
        if (Test-Path $tempLog) {
            $content = Get-Content $tempLog -Raw -ErrorAction SilentlyContinue
            if ($content -match "Milestone 3 \(Console and Diagnostics\) verified successfully!") {
                $booted = $true
                break
            }
        }
    }

    if (-not $p.HasExited) {
        Stop-Process -Id $p.Id -Force
    }

    $logOutput = Get-Content $tempLog -Raw
    Write-Host "`n----- QEMU Boot Log Output -----" -ForegroundColor DarkGray
    Write-Host $logOutput
    Write-Host "--------------------------------`n" -ForegroundColor DarkGray

    # Validate output elements
    $checks = @(
        @{ Name = "Milestone 3 Completion Marker"; Pattern = "Milestone 3 \(Console and Diagnostics\) verified successfully!" },
        @{ Name = "Primary Hart ID Formatting"; Pattern = "Primary Hart ID\s+:\s+\d+\s+\(0x[0-9a-fA-F]+\)" },
        @{ Name = "DTB Address Formatting"; Pattern = "Device Tree \(DTB\)\s+:\s+0x[0-9a-fA-F]+" },
        @{ Name = "Kernel Range Formatting"; Pattern = "Kernel Memory Range:\s+0x[0-9a-fA-F]+\s+->\s+0x[0-9a-fA-F]+" },
        @{ Name = "BSS Zeroing Test"; Pattern = "BSS zeroing test\s+:\s+PASSED" },
        @{ Name = "BSS Write Test"; Pattern = "BSS write test\s+:\s+PASSED" }
    )

    $allPassed = $true
    foreach ($chk in $checks) {
        if ($logOutput -match $chk.Pattern) {
            Write-Host "  [PASS] $($chk.Name)" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $($chk.Name)" -ForegroundColor Red
            $allPassed = $false
        }
    }

    if ($booted -and $allPassed) {
        Write-Host "`n==> SUCCESS: BeetrootOS UART console and formatted diagnostics verified!" -ForegroundColor Green
        exit 0
    } else {
        Write-Error "`n==> FAILURE: Required output was missing or incorrect."
        exit 1
    }
} finally {
    if (Test-Path $tempLog) {
        Remove-Item $tempLog -Force -ErrorAction SilentlyContinue
    }
}
