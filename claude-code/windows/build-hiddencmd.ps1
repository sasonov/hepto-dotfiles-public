# build-hiddencmd.ps1 — Build the GUI-subsystem cmd.exe wrapper
#
# This compiles hiddencmd.cpp into a Windows GUI subsystem binary.
# The resulting executable doesn't create a console window when spawned,
# which is the workaround for the Claude Code Windows console flashing bug.
#
# Prerequisites: MinGW-w64 g++ must be on PATH
#   Install via: winget install mingw
#   Or via: choco install mingw
#   Or via: scoop install mingw

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceFile = Join-Path $scriptDir "hiddencmd.cpp"
$outputFile = Join-Path $scriptDir "hiddencmd.exe"

# Check if source exists
if (-not (Test-Path $sourceFile)) {
    Write-Host "Source file not found: $sourceFile" -ForegroundColor Red
    exit 1
}

# Check for g++ (MinGW-w64)
$gpp = Get-Command g++ -ErrorAction SilentlyContinue
if (-not $gpp) {
    Write-Host "g++ not found. Install MinGW-w64:" -ForegroundColor Red
    Write-Host "  winget install mingw" -ForegroundColor Yellow
    Write-Host "  choco install mingw" -ForegroundColor Yellow
    Write-Host "  scoop install mingw" -ForegroundColor Yellow
    exit 1
}

Write-Host "Building hiddencmd.exe with MinGW-w64..." -ForegroundColor Cyan
Write-Host "  g++: $($gpp.Source)" -ForegroundColor DarkGray

# Build as GUI subsystem (-Wl,-subsystem,windows) — this is critical!
# A GUI subsystem binary doesn't get a console allocated by Windows.
$buildCmd = "g++ -O2 -municode -Wl,-subsystem,windows -o `"$outputFile`" `"$sourceFile`" -lshell32"

Write-Host "  Command: $buildCmd" -ForegroundColor DarkGray

Invoke-Expression $buildCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $outputFile)) {
    Write-Host "Output file not created: $outputFile" -ForegroundColor Red
    exit 1
}

# Verify it's a GUI subsystem binary
$bytes = [System.IO.File]::ReadAllBytes($outputFile)
# PE header offset is at bytes 0x3C-0x3D
$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
# Subsystem field is at PE offset + 0x5C (in optional header)
$subsystem = [BitConverter]::ToUInt16($bytes, $peOffset + 0x5C)

$subsystemName = if ($subsystem -eq 2) { "Windows GUI" } elseif ($subsystem -eq 3) { "Windows Console" } else { "Unknown ($subsystem)" }

Write-Host ""
Write-Host "Build successful!" -ForegroundColor Green
Write-Host "  Output: $outputFile" -ForegroundColor DarkGray
Write-Host "  Size: $([Math]::Round((Get-Item $outputFile).Length / 1KB, 1)) KB" -ForegroundColor DarkGray
Write-Host "  Subsystem: $subsystemName" -ForegroundColor DarkGray

if ($subsystem -ne 2) {
    Write-Host ""
    Write-Host "WARNING: Subsystem is not GUI! This wrapper won't suppress console windows." -ForegroundColor Red
    Write-Host "Make sure -Wl,-subsystem,windows is in the build command." -ForegroundColor Yellow
    exit 1
}

# Installation instructions
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Copy hiddencmd.exe to %USERPROFILE%\.claude\windows\cmd.exe" -ForegroundColor White
Write-Host "     (MUST be named cmd.exe — Node.js checks for this name)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  2. Add to your PowerShell profile (notepad `$PROFILE):" -ForegroundColor White
Write-Host '     $env:COMSPEC = "$env:USERPROFILE\.claude\windows\cmd.exe"' -ForegroundColor DarkGray