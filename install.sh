#!/usr/bin/env bash
# Root bootstrap: clone hepto-dotfiles and set up Claude Code
set -euo pipefail

REPO="https://github.com/sasonov/hepto-dotfiles-public.git"
DEST="${HOME}/projects/hepto-dotfiles-public"
AUTO_SYNC=false

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --auto-sync|-s) AUTO_SYNC=true ;;
  esac
done

# Clone if not present
if [ ! -d "$DEST/.git" ]; then
  echo "Cloning hepto-dotfiles..."
  git clone "$REPO" "$DEST"
else
  echo "Repository already exists at $DEST, pulling latest..."
  git -C "$DEST" pull --rebase
fi

# Dispatch to platform-specific setup
SETUP_FLAGS=""
if [ "$AUTO_SYNC" = true ]; then
  SETUP_FLAGS="--auto-sync"
fi

if [ -f "$DEST/install.sh" ]; then
  # Already running from install.sh, call the platform setup directly
  if [[ "$OSTYPE" == "darwin"* ]]; then
    bash "$DEST/claude-code/setup-mac.sh" $SETUP_FLAGS
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    bash "$DEST/claude-code/setup-pc.sh" $SETUP_FLAGS
  else
    # Linux — try systemd, fall back to setup-pc
    if command -v systemctl &>/dev/null; then
      bash "$DEST/claude-code/setup-systemd.sh" $SETUP_FLAGS
    else
      bash "$DEST/claude-code/setup-pc.sh" $SETUP_FLAGS
    fi
  fi
else
  echo "ERROR: install.sh not found in clone. Something went wrong."
  exit 1
fi

echo ""
echo "✅ Done! Claude Code is configured with hepto-dotfiles."
echo "   Repo: $DEST"
echo "   Run 'claude' to start coding."