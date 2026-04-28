#!/usr/bin/env bash
# PC (WSL or native Linux) Claude Code setup — idempotent, safe to re-run
set -euo pipefail

REPO_URL="https://github.com/sasonov/hepto-dotfiles-public.git"
REPO_DIR="${HOME}/projects/hepto-dotfiles-public"
CLAUDE_DIR="${HOME}/.claude"

mkdir -p "$CLAUDE_DIR"

# 1. Clone or pull
if [ -d "${REPO_DIR}/.git" ]; then
    echo "Repo exists at $REPO_DIR — pulling latest..."
    (cd "$REPO_DIR" && git pull --ff-only)
else
    echo "Cloning hepto-dotfiles-public..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
fi

# 2. Backup — only real dirs/files (skip existing symlinks)
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

# 3. Symlink — replace even old symlinks
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
    claude plugin marketplace add thedotmack/claude-mem 2>/dev/null || true
    claude plugin install claude-mem@thedotmack 2>/dev/null || echo "  (claude-mem already installed)"

    claude plugin marketplace add anthropics/skills 2>/dev/null || true
    claude plugin install document-skills@anthropic-agent-skills 2>/dev/null || echo "  (document-skills already installed)"
fi

if ! command -v repomix &>/dev/null && command -v npm &>/dev/null; then
    echo ""
    echo "Installing repomix..."
    npm install -g repomix || echo "  npm not available; skip repomix"
fi

# 5. Auto-sync (requires --auto-sync flag)
if [ "${1:-}" = "--auto-sync" ]; then
    if command -v systemctl &>/dev/null && systemctl --user &>/dev/null 2>&1; then
        bash "${REPO_DIR}/claude-code/setup-systemd.sh"
        echo "✅ Auto-sync systemd timer installed"
    else
        (crontab -l 2>/dev/null; echo "*/5 * * * * ${REPO_DIR}/claude-code/sync.sh >/dev/null 2>&1") | crontab -
        echo "✅ Auto-sync cron job installed (every 5 min)"
    fi
else
    echo ""
    echo "For auto-sync, re-run with: --auto-sync"
fi
