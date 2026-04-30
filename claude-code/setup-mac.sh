#!/usr/bin/env bash
# Mac Claude Code setup — idempotent, safe to re-run
set -euo pipefail

REPO_URL="https://github.com/sasonov/hepto-dotfiles-public.git"
REPO_DIR="${HOME}/projects/hepto-dotfiles"
CLAUDE_DIR="${HOME}/.claude"

mkdir -p "$CLAUDE_DIR"

# 1. Clone or pull
if [ -d "${REPO_DIR}/.git" ]; then
    echo "Repo exists at $REPO_DIR — pulling latest..."
    (cd "$REPO_DIR" && git pull --ff-only)
else
    echo "Cloning hepto-dotfiles..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

# 2. Backup real dirs/files only
BACKUP_DIR="${CLAUDE_DIR}/backup.$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

backup_if_real() {
    local src="$1" dest="$2"
    if [ -e "$src" ] && [ ! -L "$src" ]; then
        cp -a "$src" "$dest" && echo "Backed up: $(basename "$src")"
    fi
}

backup_if_real "${CLAUDE_DIR}/skills"      "${BACKUP_DIR}/skills"
backup_if_real "${CLAUDE_DIR}/CLAUDE.md"   "${BACKUP_DIR}/CLAUDE.md"
backup_if_real "${CLAUDE_DIR}/commands"    "${BACKUP_DIR}/commands"
backup_if_real "${CLAUDE_DIR}/settings.json" "${BACKUP_DIR}/settings.json"

# 3. Replace with symlinks
rm -rf "${CLAUDE_DIR}/skills"
ln -s "${REPO_DIR}/skills" "${CLAUDE_DIR}/skills"

rm -rf "${CLAUDE_DIR}/commands"
ln -s "${REPO_DIR}/claude-code/commands" "${CLAUDE_DIR}/commands"

rm -f "${CLAUDE_DIR}/CLAUDE.md"
ln -s "${REPO_DIR}/CLAUDE.md" "${CLAUDE_DIR}/CLAUDE.md"

echo "✅ Symlinks created. ~/.claude now reads from ${REPO_DIR}"

# 4. Install plugins and tools (idempotent — skips if already installed)
if command -v claude &>/dev/null; then
    echo ""
    echo "Installing Claude Code plugins..."
    claude plugin marketplace add anthropics/skills 2>/dev/null || true
    claude plugin install document-skills@anthropic-agent-skills 2>/dev/null || echo "  (document-skills already installed)"
fi

if ! command -v repomix &>/dev/null && command -v npm &>/dev/null; then
    echo ""
    echo "Installing repomix..."
    npm install -g repomix || echo "  npm not available; skip repomix"
fi

echo ""
echo "Install LaunchAgent for auto-sync:"
echo '  cp "${HOME}/projects/hepto-dotfiles/claude-code/data/com.hepto.claude-sync.plist" ~/Library/LaunchAgents/'
echo '  launchctl load ~/Library/LaunchAgents/com.hepto.claude-sync.plist'
