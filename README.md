# hepto-dotfiles

Opinionated Claude Code config — skills, commands, CLAUDE.md guidelines, and learnings. Clone it, run the setup, get a productive Claude Code environment.

## One-liner install

**macOS / Linux / WSL / Git Bash:**
```bash
curl -fsSL https://raw.githubusercontent.com/sasonov/hepto-dotfiles-public/main/install.sh | bash
```

**Windows PowerShell:**
```powershell
irm https://raw.githubusercontent.com/sasonov/hepto-dotfiles-public/main/install.ps1 | iex
```

## What it sets up

- **CLAUDE.md** — behavioral guidelines for Claude Code (simplicity-first, surgical changes, goal-driven)
- **Skills** — 30+ skills: superpowers workflow, TDD, systematic debugging, design review, caveman output compression, and more
- **Commands** — `/brainstorm`, `/review`, `/verify`, `/caveman`, `/write-plan`
- **Auto-sync** (optional) — keeps your dotfiles repo in sync across machines via LaunchAgent / systemd timer / Scheduled Task

## Setup scripts per platform

| Script | Platform | What it does |
|--------|----------|--------------|
| `claude-code/setup-mac.sh` | macOS | Symlinks to `~/.claude/`, installs plugins |
| `claude-code/setup-pc.sh` | Linux / Git Bash | Symlinks to `~/.claude/`, installs plugins |
| `claude-code/setup-systemd.sh` | Linux (systemd) | Installs sync timer unit |

Each script is idempotent — safe to re-run.

## Auto-sync

Off by default. Add `--auto-sync` to the install command:

```bash
curl -fsSL https://raw.githubusercontent.com/sasonov/hepto-dotfiles-public/main/install.sh | bash -s -- --auto-sync
```

On Windows: `$env:HEPTO_AUTO_SYNC='1'` before running the install command.

This registers a background job that pulls + pushes changes every 30 minutes.

## Customizing

- Edit `CLAUDE.md` to change behavioral guidelines
- Add skills under `skills/` — Claude Code picks them up automatically
- Add commands under `claude-code/commands/`
- Learnings go in `learnings/`

## Directory layout

```
├── CLAUDE.md                    # Behavioral guidelines
├── claude-code/
│   ├── commands/                # Slash commands
│   ├── setup-mac.sh            # macOS setup
│   ├── setup-pc.sh             # Linux/Git Bash setup
│   ├── setup-systemd.sh        # Systemd sync timer
│   └── sync.sh                  # Pull-rebase-push sync
├── install.sh                   # Root bootstrap (bash)
├── install.ps1                  # Root bootstrap (PowerShell)
├── learnings/                   # Agent learnings & tips
└── skills/                      # 30+ Claude Code skills
    ├── superpowers/             # Spec-first dev workflow
    ├── software-development/    # TDD, debugging, code review
    ├── design/                  # Logo, CIP, slides, icons
    ├── brand/                   # Brand guideline tools
    └── ...                      # More skill categories
```

## License

See individual skill directories for license info. Skills derived from open-source projects retain their original licenses.

---

*Built with Claude Code + Hermes Agent*