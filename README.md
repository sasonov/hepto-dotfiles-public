# Hepto Dotfiles — Universal Coding Agent Configuration

Skills, learnings, CLAUDE.md, and sync tooling for any AI coding agent (Claude Code, Codex, Cursor, OpenCode).

## Quick Start (Claude Code)

```bash
cd ~/hepto-dotfiles
bash scripts/install.sh
```

This symlinks:
- `CLAUDE.md` → `~/.claude/CLAUDE.md` (global agent context)
- `claude-code/commands/` → `~/.claude/commands/` (custom slash commands)
- `claude-code/settings.local.json` → `~/.claude/settings.local.json` (permissions)

After install, Claude Code will:
1. Read `CLAUDE.md` on every session start
2. Have `/brainstorm`, `/write-plan`, `/review`, `/verify`, `/caveman` commands
3. Follow the Superpowers workflow: Brainstorm → Plan → Build (TDD) → Five-Axis Review → Finish

## What's Here

```
hepto-dotfiles/
├── CLAUDE.md                    # 📍 THE key file — agent reads this first
├── skills/                      # All custom/modified skills
│   ├── superpowers/              # Main workflow (Phase 1-5)
│   │   ├── SKILL.md
│   │   └── references/           # brainstorming, TDD, debugging, etc.
│   ├── software-development/     # Coding-specific skills
│   │   ├── writing-plans/
│   │   ├── requesting-code-review/
│   │   ├── subagent-driven-development/
│   │   ├── test-driven-development/
│   │   ├── systematic-debugging/
│   │   ├── caveman-output/           # Output token compression (50% savings)
│   │   └── ...
│   ├── compression-evolution/    # Meta/self-improvement skills
│   ├── deltamem-heuristics/
│   ├── trajectory-learning/
│   └── ...
├── learnings/                   # Trajectory learnings (injected into Hermes)
├── claude-code/                 # Claude Code specific config
│   ├── commands/                # /brainstorm, /write-plan, /review, /verify, /caveman
│   ├── settings.local.json      # Permission template
│   └── templates/               # Project-specific CLAUDE.md templates
├── scripts/
│   ├── install.sh               # Symlink everything into place
│   └── sync-from-hermes.sh      # One-way sync from live ~/skills/
└── README.md
```

## The Workflow

Every coding task follows the **Superpowers Pipeline**:

```
Idea → Brainstorm → Plan (vertical-sliced, phased) → Build (TDD, one phase at a time) → Five-Axis Review → Finish Branch
```

Key patterns enforced:
- **Vertical slicing** — each task is a full-stack feature slice, not a horizontal layer
- **TDD** — red → green → refactor, always
- **Phase gates** — build one phase at a time, never all at once
- **Five-axis review** — correctness, readability, architecture, security, performance
- **No agent verifies its own work** — independent reviewer required

## Syncing from Live Hermes

After updating skills in `~/skills/`:

```bash
cd ~/hepto-dotfiles
bash scripts/sync-from-hermes.sh
git add -A && git commit -m "sync: skills and learnings from hermes"
git push
```

## For Other Agents

**Cursor:** Copy `CLAUDE.md` to project root as `.cursorrules`  
**Codex:** Copy `CLAUDE.md` to project root as `AGENTS.md`  
**OpenCode:** Copy `CLAUDE.md` to project root  

The skills files are plain Markdown — any agent can read them.

## Related Repos

- **[hepto-hermes-extensions](https://github.com/sasonov/hepto-hermes-extensions)** — Hermes Agent core patches (upstream sync)