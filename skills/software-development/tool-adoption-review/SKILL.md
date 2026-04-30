---
name: tool-adoption-review
description: "Evaluate an external tool, library, pattern, or approach for adoption into your workflow. Goes beyond marketing claims to verify real performance, map against existing infrastructure, and produce a nuanced adoption recommendation."
triggers:
  - "should we use"
  - "evaluate this tool"
  - "check if we can use"
  - "is this worth adopting"
  - "review this for integration"
---

# Tool Adoption Review

When evaluating whether to adopt an external tool, library, pattern, or approach, follow this systematic process to go beyond marketing claims and produce an honest assessment.

## Step 1: Find the Source

- Locate the primary repo/docs (GitHub, npm, PyPI, etc.)
- Identify the canonical source of truth — README claims, but also actual code and eval data
- Check stars, activity, maintenance status (`gh api repos/OWNER/REPO`)

## Step 2: Get Real Code, Not Hype

- Download actual configuration files (CLAUDE.md, SKILL.md, config files)
- Read the implementation, not just the README
- Look for edge cases the marketing doesn't mention

## Step 3: Verify Claims with Data

- Find benchmark/eval data in the repo (often in `benchmarks/`, `evals/`, `tests/`)
- Parse raw data — don't trust summary statistics from the author
- **Critical**: Always find the control arm. Compare against the fair baseline, not a straw man
  - Example: Caveman claims "75% token reduction" vs raw baseline, but vs "Answer concisely" control it's only 53%
  - Example: "Answer concisely" actually made responses LONGER — proving generic instructions don't work
- Compute your own ratios from the raw data

## Step 4: Map Against Existing Infrastructure

- Check what you already have that overlaps (skills, tools, config, habits)
- Identify the actual gap — what does this tool provide that you don't already have?
- Check for conflicts — would this contradict existing rules or patterns?

## Step 5: Assess Integration Points

- Where would this live? (system prompt, skill, CLAUDE.md, tool config)
- What's the ongoing maintenance cost? (input token overhead, context window usage)
- What's the failure mode? (what breaks if this is wrong or too aggressive)
- Does the tool have safety mechanisms? (Caveman's auto-clarity for dangerous ops is a good pattern)

## Step 6: Produce Nuanced Recommendation

Format as:

1. **What it claims** vs **what the data actually shows**
2. **What we already have** that overlaps
3. **The real gap** it fills
4. **Where to adopt** (specific integration points)
5. **Where NOT to adopt** (contexts where it would hurt)
6. **Verdict**: adopt fully, adopt selectively, or skip

## Step 7: Check for Architectural Patterns Worth Extracting

Sometimes the tool itself isn't worth adopting, but its architecture is:
- **Evaluation method**: Does it have a good eval framework? (Caveman's three-arm design: baseline, terse control, treatment —隔离es the skill's contribution from generic terseness)
- **Integration hooks**: How does it inject into sessions? (Superpowers uses Claude Code hooks/SessionStart; Hermes uses skill list in system prompt + learnings injection)
- **Safety mechanisms**: Does it have patterns for exiting compression/automation? (Caveman's auto-clarity for destructive ops)

## Step 0: Verify the Tool Actually Exists (Pre-Step)

When a user names a tool loosely (e.g., "claudemem", "cavemem", "token savior"):

1. **Search name variants** — the real repo often differs slightly from the user's recollection
2. **Check if it's already in your repo** — don't install duplicates
3. **Distrust viral lists** — AI-generated "top 10 tools" posts often fabricate repos, inflate star counts, or misattribute features. Verify every tool independently with `gh api repos/OWNER/REPO` or web search.
4. **Map which agent ecosystem it belongs to** — Claude Code (plugins, MCP, hooks), Hermes (skills + tools), Cursor, or standalone CLI. Don't force-install a Claude Code plugin into a Hermes workflow.

**Example from experience:** A viral "top 10 Claude plugins" list listed "Context Mode" by zilliztech, "Claude Token Efficient" by drona23, and "Token Savior" by mibayy — none of these exist as described or have fabricated stats. Always verify independently.

## Fetching GitHub Repo Files for Review

When reviewing repos, use `gh api repos/OWNER/REPO/contents/PATH`:
- Files return `{content: base64}` — decode with `base64 -d`
- Directories return `[{name, type, ...}]` — list with `--jq '.[].name'`
- ZIP archives (`.skill` files) need unzipping — prefer fetching the underlying `skills/NAME/SKILL.md` directly
- For eval data, check `benchmarks/`, `evals/`, `tests/` directories

## Pitfalls

- **Straw man baselines**: Many benchmarks compare against "no system prompt" which inflates savings. Always compare against the fair baseline (e.g., "Answer concisely").
- **Input token cost**: Tools that add rules to every prompt increase input tokens. Output savings must exceed input cost.
- **Context-dependent utility**: A tool that saves 50% in verbose coding contexts may save 0% in already-terse interfaces (like Telegram).
- **The "just be brief" fallacy**: Generic terseness instructions often don't work or backfire. Specific structural rules (drop articles, use fragments) are what actually compress output.
- **Binary vs skill packaging**: A tool that's a single binary/config is easier to adopt than one requiring hooks, CI, or multi-file sync. Weight maintenance cost accordingly.
- **Three-arm eval design**: When a tool claims performance improvements, look for: baseline (no instruction), control (generic instruction like "be concise"), treatment (the tool/skill). The honest delta is treatment vs control, not treatment vs baseline.