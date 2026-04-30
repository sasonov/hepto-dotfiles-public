#!/usr/bin/env bash
# PC (WSL or native Linux) Claude Code setup — idempotent, safe to re-run
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
    claude plugin marketplace add anthropics/skills 2>/dev/null || true
    claude plugin install document-skills@anthropic-agent-skills 2>/dev/null || echo "  (document-skills already installed)"
fi

if ! command -v repomix &>/dev/null && command -v npm &>/dev/null; then
    echo ""
    echo "Installing repomix..."
    npm install -g repomix || echo "  npm not available; skip repomix"
fi

# 5. Windows console flash fix
#    Builds GUI-subsystem cmd.exe wrapper and configures PowerShell profile.
#    On Windows (Git Bash), g++ from MinGW-w64 is required.
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || -n "$WINDIR" ]]; then
    echo ""
    echo "Windows detected — setting up console flash fix..."

    WINDOWS_DIR="${CLAUDE_DIR}/windows"
    mkdir -p "$WINDOWS_DIR"
    WRAPPER="${WINDOWS_DIR}/cmd.exe"

    if [ -f "$WRAPPER" ]; then
        echo "  Wrapper already installed at ${WRAPPER}"
    else
        # Try to build from source
        SOURCE="${REPO_DIR}/claude-code/windows/hiddencmd.cpp"
        BUILD_PS="${REPO_DIR}/claude-code/windows/build-hiddencmd.ps1"

        if [ -f "$SOURCE" ] && command -v g++ &>/dev/null; then
            echo "  Building wrapper from source..."
            g++ -O2 -municode -Wl,-subsystem,windows -o "${WINDOWS_DIR}/hiddencmd.exe" "$SOURCE" -lshell32
            if [ -f "${WINDOWS_DIR}/hiddencmd.exe" ]; then
                mv "${WINDOWS_DIR}/hiddencmd.exe" "$WRAPPER"
                echo "  ✅ Built and installed wrapper."
            else
                echo "  ⚠️  Build failed. Run manually:"
                echo "     powershell -ExecutionPolicy Bypass -File ${BUILD_PS}"
                echo "     Then: cp hiddencmd.exe ${WRAPPER}"
            fi
        elif [ -f "$BUILD_PS" ]; then
            echo "  ⚠️  g++ not found. Install MinGW-w64 (winget install mingw), then run:"
            echo "     powershell -ExecutionPolicy Bypass -File ${BUILD_PS}"
            echo "     cp hiddencmd.exe ${WRAPPER}"
        fi
    fi

    # Configure PowerShell profile
    PS_PROFILE="$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
    COMSPEC_LINE='$env:COMSPEC = "$env:USERPROFILE\.claude\windows\cmd.exe"'

    if [ -f "$WRAPPER" ]; then
        mkdir -p "$(dirname "$PS_PROFILE")"
        if [ -f "$PS_PROFILE" ] && grep -qF '.claude\windows\cmd.exe' "$PS_PROFILE" 2>/dev/null; then
            echo "  PowerShell profile already configured."
        else
            echo "" >> "$PS_PROFILE"
            echo "# Claude Code console flash fix" >> "$PS_PROFILE"
            echo "$COMSPEC_LINE" >> "$PS_PROFILE"
            echo "  ✅ Added COMSPEC to PowerShell profile."
            echo "  Restart your terminal for it to take effect."
        fi
    fi
fi

# 6. Auto-sync: systemd user timer preferred, fall back to cron
if command -v systemctl &>/dev/null && systemctl --user &>/dev/null 2>&1; then
    echo ""
    echo "Systemd detected. To install auto-sync timer, run:"
    echo "  ${REPO_DIR}/claude-code/setup-systemd.sh"
else
    echo ""
    echo "Manual cron (run: crontab -e):"
    echo "  */5 * * * * ${REPO_DIR}/claude-code/sync.sh >/dev/null 2>&1"
fi
