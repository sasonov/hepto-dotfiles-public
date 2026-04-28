---
name: multi-model-system-review
description: "Use 2-3 different AI models as independent reviewers to audit a system (skills, configs, code, documentation). Each model finds different issues. Synthesize findings into a prioritized fix list, then implement the fixes. Proven to catch critical bugs that a single reviewer misses."
triggers:
  - "review the system"
  - "audit the system"
  - "fresh eyes on"
  - "check for issues"
  - "find problems with"
  - "multi-model review"
---

# Multi-Model System Review

Use 2-3 different AI models as independent reviewers to audit a system. Each model catches different issues. Synthesize findings, deduplicate, and prioritize fixes.

## When to Use

- After building a complex multi-file system (skills, configs, code)
- Before deploying changes that touch core infrastructure
- When you suspect issues but can't pinpoint them
- As a quality gate before committing to main

## Process

### Phase 1: Dispatch Reviewers

Two dispatch patterns, depending on the task:

**Pattern A: Parallel (all at once)** — Best for design docs, proposals, security reviews.
Run 2-3 subagents simultaneously with the same prompt. Synthesize afterwards.

**Pattern B: Staggered (2 parallel + 1 synthesis checker)** — Best for post-build QA of AI-built artifacts.
1. Run 2 models in parallel with the full review prompt
2. After both complete, run a 3rd model with BOTH previous reports PLUS the actual files
3. The 3rd reviewer confirms/rejects each finding from the first two AND discovers what they missed
4. Weight confirmed findings (found by 2+ reviewers) higher in the final report

**Why Pattern B works**: The 3rd reviewer has the benefit of knowing what was already found, so it can look deeper. In practice, the 3rd reviewer confirmed 10/10 findings from the first two AND found 7 additional issues they both missed, including 3 critical ones (dead cron loop, invisible learnings, impossible compression logging).

**Review criteria to include:**
   - Critical issues (things that will break)
   - Hallucinations (facts that are wrong or unverifiable)
   - Missing prerequisites (files/dirs/hooks that are referenced but don't exist)
   - Inconsistencies (contradictions between components)
   - Practical problems (works in theory, fails in practice)
   - Specific improvements (with file names and line numbers)

### Phase 2: Synthesize Findings

1. **Deduplicate** — issues found by multiple reviewers get higher priority
2. **Classify** — critical/high/medium/low by what will actually break vs theoretical
3. **Verify** — check each finding against the actual codebase yourself, don't trust reviewers blindly
   - Example: One reviewer claimed "ai-research-pipeline skill doesn't exist" but it was in a subdirectory they missed
4. **Reject false findings** — models sometimes hallucinate issues

### Phase 3: Fix in Priority Order

Fix in this order:
1. **Critical code bugs** (things that break on every run)
2. **Config errors** (wrong settings, missing files, broken paths)
3. **Missing prerequisites** (bootstrap files/directories)
4. **Documentation inconsistencies** (wrong descriptions, Chinese text, format mismatches)
5. **Cosmetic improvements** (naming, structure, consistency)

### Phase 4: Test and Verify

1. **Run the full test suite** before and after changes
2. **Back up files before modifying them**
3. **Generate patches** (git diff) so changes can be re-applied after updates
4. **Write an apply script** for the patches

## Key Lessons

- **GLM-5.1 was the sharpest code reviewer** — found that ContextCompressor has no logging hooks, that trajectory.py saves files nothing reads, and that skill-performance.jsonl will never be populated
- **Different models find different bugs** — Gemma caught config issues (%% escaping, deliver settings), Qwen caught structural inconsistencies (directory format mismatches)
- **Always verify reviewer claims** — one reviewer said a skill didn't exist, but they searched the wrong path
- **Chinese characters in English docs** are a tell-tale sign of AI-generated content — catch and fix these
- **Write-only data stores are the #1 architectural failure** — if nothing reads the data, the system is broken regardless of how well it writes

## Patch Management Pattern

When modifying a codebase you don't own (like Hermes):
1. **Back up all files before changes** — `cp file file.bak`
2. **Make changes using the codebase's own patterns** (fire-and-forget logging, `try/except pass`, `get_hermes_home()`, etc.)
3. **Generate git diff patches** — `git diff HEAD -- file.py > patchfile.patch`
4. **Write an apply script** that uses `git apply --check` (forward) and `git apply --reverse --check` (already applied) to detect state
5. **Test: `python -m pytest tests/ -q`** — verify no regressions

## Pitfalls

- **Don't create GitHub repos without user approval** — save patches locally, offer repo creation as an option
- **Subagent iteration limits** — complex code changes may hit the iteration limit before finishing. Plan for a completion handler.
- **Flaky tests** — if a test fails, run it alone. xdist race conditions are common, not your bug.
- **Cron job `%%` escaping** — in Hermes cron JSON, `%%` appears literally in prompts. Use single `%`.
- **Cron job delivery** — if a job's purpose is human review, set `deliver: "telegram"`, not `"local"`