#!/usr/bin/env bash
# Install hepto-dotfiles into Claude Code by symlinking config files
# Safe to re-run — checks for existing links/files first
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"

echo "=== Installing hepto-dotfiles into Claude Code ==="

# 1. CLAUDE.md → global context
if [ -L "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "  ✓ CLAUDE.md already symlinked"
elif [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "  ⚠ CLAUDE_DIR/CLAUDE.md exists (not a symlink) — backing up"
    mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.backup.$(date +%s)"
    ln -s "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "  ✓ CLAUDE.md symlinked"
else
    ln -s "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "  ✓ CLAUDE.md symlinked"
fi

# 2. Custom commands → ~/.claude/commands/
mkdir -p "$CLAUDE_DIR/commands"
for cmd in "$REPO_DIR/claude-code/commands/"*.md; do
    [ -f "$cmd" ] || continue
    cmd_name=$(basename "$cmd")
    if [ -L "$CLAUDE_DIR/commands/$cmd_name" ]; then
        echo "  ✓ commands/$cmd_name already symlinked"
    else
        ln -sf "$cmd" "$CLAUDE_DIR/commands/$cmd_name"
        echo "  ✓ commands/$cmd_name symlinked"
    fi
done

# 3. Settings — merge rather than overwrite
if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
    echo "  ⚠ settings.local.json exists — not overwriting (manual merge needed)"
    echo "    Template at: $REPO_DIR/claude-code/settings.local.json"
else
    ln -s "$REPO_DIR/claude-code/settings.local.json" "$CLAUDE_DIR/settings.local.json"
    echo "  ✓ settings.local.json symlinked"
fi

# 4. Project-specific CLAUDE.md for home directory
PROJECT_CLAUDE="$CLAUDE_DIR/projects/-home-elias/CLAUDE.md"
if [ -f "$PROJECT_CLAUDE" ]; then
    echo "  ℹ Project CLAUDE.md exists at $PROJECT_CLAUDE"
    echo "    Add this line at the top to reference hepto-dotfiles:"
    echo "    See: $REPO_DIR/CLAUDE.md for the Superpowers workflow"
else
    mkdir -p "$(dirname "$PROJECT_CLAUDE")"
    echo "See: $REPO_DIR/CLAUDE.md for the Superpowers workflow" > "$PROJECT_CLAUDE"
    echo "  ✓ Project CLAUDE.md created (minimal — add server context as needed)"
fi

echo ""
echo "=== Install complete ==="
echo "Claude Code will now read the Superpowers workflow on every session."
echo "Available commands: /brainstorm, /write-plan, /review, /verify, /caveman"