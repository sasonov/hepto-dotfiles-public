# Root bootstrap: clone hepto-dotfiles and set up Claude Code (Windows)
$ErrorActionPreference = 'Stop'

$Repo = 'https://github.com/sasonov/hepto-dotfiles-public.git'
$Dest = Join-Path $env:USERPROFILE 'projects\hepto-dotfiles-public'
$AutoSync = [bool]$env:HEPTO_AUTO_SYNC

# Clone if not present
if (-not (Test-Path (Join-Path $Dest '.git'))) {
    Write-Host 'Cloning hepto-dotfiles...'
    git clone $Repo $Dest
} else {
    Write-Host "Repository already exists at $Dest, pulling latest..."
    git -C $Dest pull --rebase
}

# Run Windows setup
$SetupFlags = @()
if ($AutoSync) { $SetupFlags += '-AutoSync' }

& powershell -ExecutionPolicy Bypass -File (Join-Path $Dest 'claude-code\setup-windows.ps1') @SetupFlags

Write-Host ''
Write-Host 'Done! Claude Code is configured with hepto-dotfiles.'
Write-Host "   Repo: $Dest"
Write-Host "   Run 'claude' to start coding."