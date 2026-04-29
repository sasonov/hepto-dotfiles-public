# Claude Code Windows Console Flash Fix

## Problem

Claude Code spawns visible PowerShell/console windows on Windows. Known upstream bug ([#27115](https://github.com/anthropics/claude-code/issues/27115), [#28138](https://github.com/anthropics/claude-code/issues/28138), [#51867](https://github.com/anthropics/claude-code/issues/51867)).

## Fix

GUI-subsystem `cmd.exe` wrapper. Windows doesn't allocate `conhost.exe` for GUI binaries, so no console window appears.

**Setup via `setup-pc.sh`** (automatic on Windows):

```powershell
# From Git Bash — builds + installs + configures PS profile
bash claude-code/setup-pc.sh
```

**Manual install** (if setup-pc.sh doesn't work):

```powershell
# 1. Build (needs MinGW-w64: winget install mingw)
cd claude-code/windows
powershell -ExecutionPolicy Bypass -File build-hiddencmd.ps1

# 2. Install (MUST be named cmd.exe — Node.js checks this)
mkdir -Force "$env:USERPROFILE\.claude\windows"
copy hiddencmd.exe "$env:USERPROFILE\.claude\windows\cmd.exe"

# 3. Add to PowerShell profile (notepad $PROFILE)
$env:COMSPEC = "$env:USERPROFILE\.claude\windows\cmd.exe"
```

## Files

| File | Purpose |
|------|---------|
| `hiddencmd.cpp` | C++ source — GUI-subsystem cmd.exe wrapper |
| `build-hiddencmd.ps1` | Build script (MinGW-w64) |
