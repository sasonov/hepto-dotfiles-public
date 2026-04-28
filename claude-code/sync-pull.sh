#!/usr/bin/env bash
# Pull-only sync for consumer machines (macOS / Linux)
set -euo pipefail

REPO_DIR="${1:-${HOME}/projects/hepto-dotfiles-public}"
cd "$REPO_DIR"

git pull --rebase 2>&1 | tee -a "${HOME}/.claude/sync.log"

# If skills/commands/CLAUDE.md changed, re-copy to ~/.claude/ on Windows
# (On macOS/Linux with symlinks, this is a no-op — changes are live already)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    CLAUDE_DIR="${HOME}/.claude"
    for dir in skills claude-code/commands; do
        src="$REPO_DIR/$dir"
        dest="$CLAUDE_DIR/$(basename "$dir")"
        if [ -d "$src" ]; then
            rm -rf "$dest"
            cp -a "$src" "$dest"
        fi
    done
    cp -f "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || true
fi

echo "Synced at $(date)" >> "${HOME}/.claude/sync.log"