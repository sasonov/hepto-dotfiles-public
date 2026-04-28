#!/usr/bin/env bash
# Install systemd user service + timer for auto-sync
set -euo pipefail

REPO_DIR="${HOME}/projects/hepto-dotfiles-public"
SERVICE_DIR="${HOME}/.config/systemd/user"

mkdir -p "$SERVICE_DIR"

cat > "$SERVICE_DIR/claude-sync.service" <<EOF
[Unit]
Description=Claude Code dotfiles sync

[Service]
Type=oneshot
WorkingDirectory=${REPO_DIR}
ExecStart=${REPO_DIR}/claude-code/sync.sh
EOF

cat > "$SERVICE_DIR/claude-sync.timer" <<EOF
[Unit]
Description=Run Claude Code dotfiles sync every 5 min

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now claude-sync.timer

echo "✅ Timer active. Check: systemctl --user status claude-sync.timer"