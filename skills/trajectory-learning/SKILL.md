---
name: trajectory-learning
description: "Extract structured learnings from task trajectories — strategy tips, recovery patterns, optimization insights. Automatically generates and maintains a learnings database that gets injected into future sessions for similar tasks."
triggers:
  - "post-mortem"
  - "what went wrong"
  - "extract learnings"
  - "learn from this"
  - "trajectory learning"
  - "after action review"
---

# Trajectory-Informed Learning System

Based on IBM Research (arXiv:2603.10600): Extracting structured learnings from execution trajectories yields 28.5pp improvement (149% relative) on complex tasks. This skill implements that insight for Hermes Agent.

## Overview

When a task struggles, fails, or succeeds after difficulty, this skill extracts three types of tips:

1. **Strategy tips** — What approach worked and when to use it
2. **Recovery tips** — How to recover from specific errors/failures  
3. **Optimization tips** — How to do things better/faster than the default approach

These tips are stored in `~/.hermes/learnings/` as markdown files, organized by category. Before starting similar tasks, relevant learnings are injected into context.

## When to Use

### Automatic Triggers
- After `delegate_task` completes with errors or warnings
- After a task required 5+ iterations to succeed
- After a task explicitly fails
- After `systematic-debugging` skill completes

### Manual Triggers  
- User says "extract learnings", "post-mortem", "what went wrong"
- User asks "what did we learn from this?"
- After any extended debugging session

## Architecture

```
~/.hermes/learnings/
├── _index.md              # Topic index for quick lookup
├── devops.md              # Infrastructure, deployment, networking
├── coding.md              # Code patterns, debugging, architecture
├── research.md            # Research pipeline, web extraction
├── tools.md               # Tool-specific tips (terminal, browser, etc.)
├── general.md             # Cross-cutting patterns
└── skill-proposals/       # Loop 3 skill improvement proposals (auto-created)
```

**IMPORTANT**: These are flat `.md` files, NOT subdirectories. The directory listing above shows the actual structure.

Each learning file is a markdown file with this structure:

```markdown
# [Category] Learnings

## Strategy Tips
- **[Pattern]**: [Description] → [When to use] → [Expected benefit]
- ...

## Recovery Tips
- **[Error/Signal]**: [Root cause] → [Fix] → [Prevention]
- ...

## Optimization Tips  
- **[Default approach]**: [Better approach] → [Why it's better] → [When applicable]
- ...
```

## Extraction Process

### Step 1: Gather Trajectory Data
- Review the conversation history for the struggling task
- Identify: what was attempted, what failed, what worked eventually, what was tried but abandoned

### Step 2: Classify the Difficulty
- **Easy success** (1-2 iterations): Skip — not enough signal to extract
- **Moderate struggle** (3-5 iterations): Extract 1-2 key learnings
- **Hard failure** (5+ iterations or explicit failure): Full extraction — all three tip types

### Step 3: Extract Tips

For each difficulty level:

**Strategy Tips** — "When X, try Y"
- What approach eventually worked?
- What was the key insight that unlocked progress?
- What conditions made this approach necessary?

**Recovery Tips** — "If error Z, the fix is W"  
- What errors occurred? What was the root cause?
- What fix resolved it? How could it be prevented?
- Were there misleading error messages? What did they actually mean?

**Optimization Tips** — "Instead of A, approach B is faster"
- What was the slow/wasteful approach? What's faster?
- What tools or techniques could have been used earlier?
- What information was missing that would have helped?

### Step 4: Write to Learnings Database
- Append to the appropriate category file in `~/.hermes/learnings/`
- Update `_index.md` with topic keywords for quick retrieval
- Keep entries concise (1-2 lines each) — these get injected into future context

### Step 5: Validate
- Check that new tips don't contradict existing ones
- Check that tips are specific enough to be actionable (not vague platitudes)
- Remove any tips that are overly specific to a one-time event

## Injection Into Future Sessions

When starting a task in a category that has learnings, inject the relevant tips as a user message (not system — preserves prompt caching):

```
[LEARNINGS — devops]: 
- **WireGuard DNAT**: If FORWARD chain shows 0 packets after DNAT, switch from MASQUERADE to SNAT → Fixes asymmetric routing on CGNAT setups
- **Nginx 502**: After docker restart, check if container is actually listening before debugging nginx → `docker logs` + `ss -tlnp`
```

Only inject 3-5 most relevant tips per session (each tip is ~1 line). Inject as a user message near the start.

## Integration with Other Skills

- **systematic-debugging**: After debugging completes, suggest trajectory-learning extraction
- **superpowers**: Failed subagent tasks should trigger extraction
- **ai-research-pipeline**: Research failures (like the delegate_task timeout) should be extracted as recovery tips
- **ACON compression evolution** (future): Compression failures should feed back as optimization tips

## Key Principles

1. **Signal over noise**: Only extract learnings from non-trivial experiences. Don't clutter the database with obvious tips.
2. **Specificity**: "If WireGuard DNAT shows 0 FORWARD packets, use SNAT instead of MASQUERADE" beats "check your firewall rules".
3. **Bounded size**: Each category file should stay under 200 lines. Prune stale entries quarterly.
4. **No duplication**: Check existing learnings before adding. Merge similar tips.
5. **Learning, not logging**: Focus on transferable patterns, not session-specific details.

## Cron Job for Automatic Extraction

A nightly cron job can scan recent session histories for struggling tasks and extract learnings. However, this requires careful implementation to avoid extracting noise. Start with manual/triggered extraction first.

## Pitfalls

- **Over-extraction**: Don't extract from every minor hiccup. Only from genuine learning moments.
- **Vague tips**: "Be careful with networking" is useless. "After changing iptables rules, always verify FORWARD chain counters" is useful.
- **Stale learnings**: Software changes. A recovery tip from 6 months ago may no longer apply. Prune quarterly.
- **Context bloat**: Only inject 3-5 most relevant tips. Too many tips = noise = context rot.
- **Contradictions**: Always check existing learnings before adding. If new evidence contradicts an old tip, update it.
- **Write-only trap**: Learnings MUST be consumed, not just written. Currently Hermes does not auto-inject learnings into context. Until this is implemented as a code change to `prompt_builder.py`, you must manually read relevant learnings at the start of sessions and inject them as context. If you write learnings but never read them, the system is a write-only black hole.