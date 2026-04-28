# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

## Hepto Principles

- User wants an **opinionated agent** — push back when you know better.
- **Build from reference, not forks** — own every line of code.
- **Never silent** — progress updates between steps.
- **Autonomous but transparent** — state plans before acting.
- **English only** in all communication.

## Workflows

| When | Read |
|------|------|
| Coding (new feature / bugfix) | `skills/superpowers/SKILL.md` |
| Debugging | `skills/software-development/systematic-debugging/SKILL.md` |
| Writing a plan | `skills/software-development/writing-plans/SKILL.md` |
| Code review | `skills/software-development/requesting-code-review/SKILL.md` |
|| Output compression | `/caveman lite|full|ultra` or say "caveman mode" |
| Session memory | claude-mem plugin (auto-installed) |

---

## Installed Tools & Plugins

### repomix — Context Packing
Globally available as `repomix`. Use whenever you need to share or analyze an entire codebase in one shot.

| Task | Command |
|------|---------|
| Pack current repo for AI context | `repomix --style markdown --compress` |
| Output to clipboard | `repomix --style markdown --compress --copy` |
| Specific directory | `repomix --style markdown --compress path/to/dir` |
| Remote repo | `repomix --remote user/repo --style markdown --compress` |
| Include git diffs | `repomix --style markdown --include-diffs` |

**When to reach for it:**
- Submitting a full repo to an LLM API (kimi.ai, OpenAI web, etc.)
- Sharing codebases across machines or team members
- Generating project documentation from all source files
- Bug reports that need inline code context

**Format preference:** `--style markdown` for human readability. `--compress` tree-sitter extraction for minimal tokens when sending to APIs.

### Document Skills (Claude Code plugins)
Installed via `claude plugin install document-skills@anthropic-agent-skills`. These generate actual binary documents, not plain text stubs.

| Document | Invoke with |
|----------|-------------|
| Word (.docx) | "Use the **docx** skill to..." |
| PDF | "Use the **pdf** skill to..." |
| PowerPoint (.pptx) | "Use the **pptx** skill to..." |
| Excel (.xlsx) | "Use the **xlsx** skill to..." |

Also installed: **claude-api** skill for Claude SDK guidance.

### claude-mem
Session memory persistence (auto-installed). Enables cross-session recall of project decisions and context.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
