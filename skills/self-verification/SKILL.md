---
name: self-verification
description: "Self-verification patterns for AI agent outputs — cross-reference facts, validate web extraction, sanity-check results before delivery. Inspired by ICLR 2024 research showing self-correction improves 18.5pp WITH verification but is unreliable without it."
triggers:
  - "verify this"
  - "fact check"
  - "double check"
  - "sanity check"
  - "cross reference"
---

# Self-Verification Skill

Research shows self-correction without external verification is fundamentally unreliable (ICLR 2024, Galileo). But self-correction WITH verification improves results by 18.5 percentage points. This skill provides structured verification patterns for different task types.

## Potemkin Interface Check (Replit/Spotify Pattern)

A **Potemkin interface** is a feature that *looks* functional but isn't actually wired up — buttons that render but don't submit, pages that display but 404 on action, services that start but don't respond on their port. This is the #1 source of false completions in autonomous agent runs.

**How to detect:**
- After creating an API endpoint: `curl` it. Does it actually respond?
- After configuring a service: `systemctl status` it, then hit the port. Is it listening?
- After building a UI feature: visit it in the browser. Does the form submit? Does the data flow through?
- After "fixing" a bug: reproduce the *original* bug report scenario. Did it actually get fixed, or did you just add code that doesn't affect the failure path?

**The principle:** Never trust the code. Run it. The agent wrote config files and code — verify the *running system* behaves as expected, not just that the files look correct.

This pattern comes from Replit's Agent 3 (200+ min autonomous sessions) and Spotify's 1,500+ agent-generated PRs. Both found that shift-left verification — checking *early and with external signals* — catches false completions that self-review misses entirely.

## When to Verify

### Always Verify
- Web extraction results (before including in research)
- Code that will be deployed to production
- Configuration changes to infrastructure
- Factual claims in summaries/reports
- URLs and references before citing them

### Verify After Struggle
- Any task that took 3+ iterations to get right
- Any task that involved debugging
- Output from subagents that didn't include verification

## Verification Patterns by Task Type

### Research Tasks
1. **Cross-reference**: For each key claim, find a second independent source
2. **Date check**: Verify publication dates on papers/repos (stale info is common)
3. **Source check**: Verify URLs actually resolve and contain the claimed content
4. **Methodology check**: If a paper claims X% improvement, check the baseline and conditions
5. **Duplication**: Cross-reference with existing research files to avoid repeating findings

### Web Extraction
1. **Content verification**: After extracting content, verify key facts against the page:
   ```python
   # After web_extract, pick 2-3 key claims and verify against source
   # Use browser_console to spot-check specific data points
   browser_console(expression="document.body.innerText.includes('claimed_fact')")
   ```
2. **Attribution check**: Verify that extracted content actually comes from the claimed source
3. **Completeness check**: If extracting from a long article, verify no major sections were missed

### Code Changes
1. **Syntax check**: Always run `python -m py_compile` or equivalent after modifying code
2. **Import check**: Verify all imports resolve after moving/renaming files
3. **Test execution**: Run existing tests after changes — never assume tests pass
4. **Diff review**: Before committing, review the actual diff (not just what you intended)

### Infrastructure Changes
1. **Health check**: After any change, verify service is running AND responding correctly
2. **Connectivity test**: After network/firewall changes, test actual connections (not just config)
3. **Rollback plan**: Before changes, document what the current state is for rollback
4. **Cascading effects**: Check what else depends on the thing you're changing

### Configuration Changes
1. **Validate before apply**: Use `-t` flags, dry-runs, or syntax checks before applying
2. **Minimal scope**: Change one thing at a time and verify between changes
3. **State comparison**: Before/after comparison to catch unintended side effects

## MASC-Inspired Anomaly Detection

From MASC paper (arXiv:2510.14319): Flag suspicious subagent outputs using prototype-guided anomaly detection.

Practical heuristic: If a subagent's output looks "too clean" (no qualifications, no caveats, no mention of limitations) or "too confident" (claims 100% success, no error handling), it's likely incomplete or wrong.

**Red flags in output**:
- No error handling or edge case consideration
- Claims of 100% accuracy/success rate
- No mention of limitations or trade-offs
- Very different style/quality from other subagent outputs (suggests one cut corners)
- Circular reasoning or self-referential claims

## Integration with Other Skills

- **trajectory-learning**: After extraction, trigger verification of the learning itself
- **systematic-debugging**: Verification is built into the debugging process
- **research pipeline**: Cross-referencing should be standard in all research outputs

## Multi-Model Review Pattern

For complex system audits, dispatch 2-3 different LLM models as independent reviewers. Each model catches different issues:

1. **Dispatch in parallel** (first 2), then a third AFTER reading their findings
2. **The third reviewer checks whether the first two were right or wrong** — this catches false positives and confirms true findings
3. **Synthesize**: Only report issues that at least 2 of 3 reviewers agree on, flag disputed findings separately

This catches far more than a single model reviewing its own work. Cost: ~3x a single review. Benefit: ~2x more issues found, ~50% fewer false positives.

Key: the third reviewer MUST be given the first two reviewers' findings to verify/reject. Don't just run 3 blind reviews — the third pass adds verification value.

## System-Building Verification Checklist

When building multi-component agent systems (skills, learnings, cron jobs, pipelines), run through this checklist BEFORE declaring done:

### Dead-End Verification
- [ ] Does every written output have a consumer? If you write to a file, does anything read it?
- [ ] Does every cron job have data to process? If the input file is empty, does the job handle that gracefully?
- [ ] Does every delivered output reach its intended audience? (local vs telegram vs discord)

### Bootstrapping Verification
- [ ] Do all referenced files and directories actually exist? Run `ls` or `find` to confirm.
- [ ] Does the first run of any system work without manual setup? (empty JSONL files, missing directories)
- [ ] Do prerequisite tools/packages exist? (`jq`, `curl`, Python packages)

### Integration Verification
- [ ] Does the system you built match the actual codebase? (directory structures, function signatures, file paths)
- [ ] Does the agent code actually support the behavior your skill describes? (hooks, callbacks, injection points)
- [ ] Are format references consistent? (markdown vs JSONL, `70%` vs `70%%`, subdirectories vs flat files)

### Language/Content Verification
- [ ] No non-English text in English documents (Chinese characters, etc.)
- [ ] No unverified AI-extracted claims cited as facts (mark with [UNVERIFIED] or verify manually)
- [ ] No hallucinated paths, URLs, or file references

## Pitfalls

- **Verification theater**: Don't verify things that are obviously true. Focus on claims that matter.
- **Double verification**: Don't verify the verification. One level of checking is sufficient.
- **Analysis paralysis**: Verification should add < 20% overhead. If it's adding more, you're over-verifying.
- **Trust but verify external sources**: Even "reliable" sources make mistakes. Verify key claims independently.
- **Write-only systems**: The #1 mistake in agent self-improvement systems is building pipelines that write data nothing reads. Always verify the read path exists before building the write path.
- **Aspirational skills**: Skills that describe behavior the agent code doesn't support are recipes without a kitchen. Verify the code has the hooks before writing the skill.