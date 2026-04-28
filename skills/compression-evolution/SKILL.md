---
name: compression-evolution
description: "Track and evolve context compression guidelines based on failure analysis. Inspired by ACON (arXiv:2510.00615) — iteratively improve compression rules by analyzing cases where compression preceded task failure."
triggers:
  - "context compression"
  - "compression failed"
  - "compaction quality"
  - "evolve compression"
  - "ACON"
---

# Compression Guideline Evolution (ACON-Inspired)

Based on ACON (Adaptive COntext Navigation, arXiv:2510.00615): Compression guidelines can be iteratively improved by analyzing failure cases. Our context compressor is currently static — it uses fixed rules. This skill tracks compression quality and evolves the rules.

## The Problem

Our ContextCompressor (your-agent/core/compressor.py) uses fixed rules:
- Prune old tool results
- Protect head messages (system + first exchange)
- Protect tail by token budget
- Summarize middle turns with LLM

These rules were written once and never improved. ACON shows that analyzing "compression failures" (cases where compression preceded task failure) can generate improved rules, achieving 26-54% token reduction while preserving task performance.

## How It Works

### Phase 1: Observation (Current — Just Track)
Log every compression event with:
- When it happened (tokens at time of compression)
- How much was compressed (before/after token counts)
- What was preserved vs removed
- Whether the task subsequently succeeded or failed

Store observations in: `~/data/compression-events.md`

### Phase 2: Failure Analysis (When We Have 5+ Failures)
For each compression event that preceded a task failure:
1. What information was lost that was needed later?
2. Could it have been preserved with smarter selection?
3. Would a different summarization prompt have retained it?
4. Was the issue in pruning (too aggressive) or selection (wrong priorities)?

### Phase 3: Rule Evolution (When Patterns Emerge)
Generate improved compression guidelines and save them as a skill.

Example evolved rules (from ACON paper + our research):

```markdown
## Evolved Compression Rules v2

### Priority Preservation (Higher = Keep)
1. Recent error messages and their resolutions (HIGH — needed for debugging)
2. File paths and code changes (MEDIUM — needed for continuation)
3. Tool call arguments and results (MEDIUM — but prune old ones first)
4. User preferences stated in this session (HIGH — needed for alignment)
5. Task decomposition details (HIGH — needed for continuation)
6. Context about what was already tried (HIGH — prevents repetition)

### Priority Pruning (Lower = Remove First)
1. Verbose tool output (file contents read in full) → Keep filename + key finding only
2. Successful verification steps → Summarize to "X verified OK"
3. Repeated similar errors → Keep first instance + count, prune rest
4. Intermediate debugging steps that didn't lead to the solution → Keep only solution
5. Confirmation messages ("Yes, that works") → Prune entirely

### Special Handling
- **Debugging sessions**: Preserve the ERROR that started it + the FIX that resolved it. Prune intermediate attempts.
- **Research sessions**: Preserve key FINDINGS and SOURCES. Prune search queries and raw extraction text.
- **Code sessions**: Preserve file PATHS and CHANGE DESCRIPTIONS. Prune full file contents (can re-read).
```

## Current Compression Rules (Static — Heremes ContextCompressor)

From reading the code (context_compressor.py):
1. **Tool result pruning**: Replace old tool results with `[Old tool output cleared to save context space]`
2. **Head protection**: Keep first N messages (default: system + first 3 exchanges)
3. **Tail protection**: Keep last ~20 messages or by token budget
4. **Middle summarization**: Use LLM to summarize middle turns with structured template (Goal, Progress, Decisions, Files, Next Steps)
5. **Iterative summaries**: Subsequent compactions update previous summary

## Potential Improvements (After Analysis)

### Near-Term (No code changes needed)
1. **Learnings injection**: Use trajectory-learnings to recognize "this session is similar to past X" → inject relevant past compression rules
2. **Task-aware pruning**: Research sessions → keep sources/findings; Code sessions → keep paths/changes; Debug sessions → keep error/fix pairs

### Medium-Term (Code changes needed)
3. **Semantic pruning**: Instead of chronological (old=prune, new=keep), use semantic relevance (important=keep, tangential=prune)
4. **Compression quality tracking**: Log metrics on compression → success correlation
5. **Dynamic summary templates**: Different summary templates for different task types

### Long-Term (Architecture changes)
6. **SWE-Pruner approach**: Lightweight neural filter that scores lines by relevance to current task
7. **AST-aware compression**: For code sessions, use Tree-sitter to keep structure and prune implementation details
8. **Knowledge graph context**: Store past session knowledge in a graph, query relevant nodes instead of full context

## Tracking Format

Each compression event logged as:

```markdown
## [Date] [Session Type]

- **Tokens before**: X
- **Tokens after**: Y
- **Compression ratio**: Z%
- **Task outcome**: Success / Partial / Failed
- **Lost info**: [What was removed that might have been needed]
- **Preserved info**: [What was kept that turned out to be useful]
- **Notes**: [Any observations about compression quality]
```

## Integration

- **trajectory-learning**: Compression failures feed into learnings as optimization tips
- **self-verification**: Verify that key information wasn't lost during compression
- **Research pipeline**: Compression events during research are logged separately

## Pitfalls

- **Analysis paralysis**: Don't over-log. Track the basics, improve when patterns are clear.
- **Premature optimization**: Current compressor works reasonably well. Only evolve rules when there's evidence of failure.
- **Context about context**: The compression tracking itself adds context. Keep logs minimal.
- **One-size-fits-all**: Different session types need different compression strategies. Don't create one monolithic rule set.