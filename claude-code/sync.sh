#!/usr/bin/env bash
# Auto-sync: pull before push, rebase to keep linear history

set -euo pipefail

REPO_DIR="${1:-${HOME}/projects/hepto-dotfiles-public}"
LOG="${HOME}/.claude/sync.log"

cd "$REPO_DIR"

# Pull first to catch changes from other machines
git pull --rebase 2>&1 | tee -a "$LOG"

# Commit if anything changed (skills, commands, CLAUDE.md)
if [ -n "$(git status --short skills/ claude-code/commands/ CLAUDE.md)" ]; then
    git add skills/ claude-code/commands/ CLAUDE.md
    git commit -m "auto-sync: $(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>&1 | tee -a "$LOG"
    git push 2>&1 | tee -a "$LOG"
fi

echo "Synced at $(date)" >> "$LOG"
