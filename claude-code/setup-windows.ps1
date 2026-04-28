# Windows Claude Code setup — copy strategy (no symlinks, no Dev Mode, no admin)
# Idempotent — safe to re-run
$ErrorActionPreference = 'Stop'

$RepoDir = Join-Path $env:USERPROFILE 'projects\hepto-dotfiles-public'
$ClaudeDir = Join-Path $env:USERPROFILE '.claude'

# Parse flags
$SyncOnly = $false
$AutoSync = $false
foreach ($arg in $args) {
    if ($arg -eq '-SyncOnly') { $SyncOnly = $true }
    if ($arg -eq '-AutoSync') { $AutoSync = $true }
}

if (-not $SyncOnly) {
    # 1. Clone or pull
    if (Test-Path (Join-Path $RepoDir '.git')) {
        Write-Host 'Repo exists — pulling latest...'
        git -C $RepoDir pull --ff-only
    } else {
        Write-Host 'Cloning hepto-dotfiles-public...'
        New-Item -ItemType Directory -Force -Path (Split-Path $RepoDir) | Out-Null
        git clone 'https://github.com/sasonov/hepto-dotfiles-public.git' $RepoDir
    }

    # 2. Backup existing files
    $BackupDir = Join-Path $ClaudeDir "backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

    function Backup-IfReal($Src, $Dest) {
        if ((Test-Path $Src) -and -not (Get-Item $Src).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) {
            Copy-Item -Recurse -Force $Src $Dest
            Write-Host "Backed up: $(Split-Path $Src -Leaf)"
        }
    }

    Backup-IfReal (Join-Path $ClaudeDir 'skills') (Join-Path $BackupDir 'skills')
    Backup-IfReal (Join-Path $ClaudeDir 'CLAUDE.md') (Join-Path $BackupDir 'CLAUDE.md')
    Backup-IfReal (Join-Path $ClaudeDir 'commands') (Join-Path $BackupDir 'commands')

    # 3. Copy (Windows: no symlinks needed)
    Write-Host 'Copying files to ~/.claude/...'
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

    # Skills
    $SkillsDest = Join-Path $ClaudeDir 'skills'
    if (Test-Path $SkillsDest) { Remove-Item -Recurse -Force $SkillsDest }
    Copy-Item -Recurse (Join-Path $RepoDir 'skills') $SkillsDest

    # Commands
    $CmdsDest = Join-Path $ClaudeDir 'commands'
    if (Test-Path $CmdsDest) { Remove-Item -Recurse -Force $CmdsDest }
    Copy-Item -Recurse (Join-Path $RepoDir 'claude-code\commands') $CmdsDest

    # CLAUDE.md
    Copy-Item -Force (Join-Path $RepoDir 'CLAUDE.md') (Join-Path $ClaudeDir 'CLAUDE.md')

    Write-Host 'Done. ~/.claude now has hepto-dotfiles content.'

    # 4. Install plugins (if claude CLI is available)
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host ''
        Write-Host 'Installing Claude Code plugins...'
        claude plugin marketplace add thedotmack/claude-mem 2>$null
        claude plugin install claude-mem@thedotmack 2>$null
        claude plugin marketplace add anthropics/skills 2>$null
        claude plugin install document-skills@anthropic-agent-skills 2>$null
    }

    # 5. Install repomix
    if (-not (Get-Command repomix -ErrorAction SilentlyContinue) -and (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Host ''
        Write-Host 'Installing repomix...'
        npm install -g repomix
    }
}

# 6. Auto-sync via Scheduled Task
if ($AutoSync) {
    $TaskName = 'HeptoClaudeSync'
    $ScriptPath = Join-Path $RepoDir 'claude-code\sync-pull.ps1'

    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    $Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30)
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description 'Sync hepto-dotfiles' -Force | Out-Null
    Write-Host 'Auto-sync Scheduled Task installed (every 30 min)'
} elseif (-not $SyncOnly) {
    Write-Host ''
    Write-Host 'For auto-sync, re-run with: -AutoSync'
}