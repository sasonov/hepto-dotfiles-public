# Pull-only sync for consumer machines (Windows)
$ErrorActionPreference = 'Stop'

$RepoDir = Join-Path $env:USERPROFILE 'projects\hepto-dotfiles-public'
$ClaudeDir = Join-Path $env:USERPROFILE '.claude'

git -C $RepoDir pull --rebase 2>&1 | Out-File -Append (Join-Path $ClaudeDir 'sync.log')

# Re-copy files (no symlinks on Windows)
$SkillsSrc = Join-Path $RepoDir 'skills'
$SkillsDest = Join-Path $ClaudeDir 'skills'
if (Test-Path $SkillsDest) { Remove-Item -Recurse -Force $SkillsDest }
Copy-Item -Recurse $SkillsSrc $SkillsDest

$CmdsSrc = Join-Path $RepoDir 'claude-code\commands'
$CmdsDest = Join-Path $ClaudeDir 'commands'
if (Test-Path $CmdsDest) { Remove-Item -Recurse -Force $CmdsDest }
Copy-Item -Recurse $CmdsSrc $CmdsDest

Copy-Item -Force (Join-Path $RepoDir 'CLAUDE.md') (Join-Path $ClaudeDir 'CLAUDE.md')

"Synced at $(Get-Date)" | Out-File -Append (Join-Path $ClaudeDir 'sync.log')