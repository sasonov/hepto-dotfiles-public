---
name: multi-model-design-review
description: Get multiple AI models to independently review a design document, then synthesize findings into actionable decisions.
category: software-development
triggers:
  - "Have multiple AI models review this design"
  - "Validate this architecture before building"
  - "Get diverse perspectives on this plan"
---

# Multi-Model Design Review Workflow

Use this when you have a significant design document and want diverse architectural perspectives before committing to implementation.

## Why This Works

Different models have different "personalities" and training biases:
- **ChatGPT**: Production infrastructure focus, security-first, tends toward comprehensive systems
- **Gemini**: Pragmatic implementation gotchas, DX-focused, identifies real-world conflicts
- **Opus/Claude**: Architectural elegance, scope management, identifies premature abstraction

Getting 2-3 independent reviews surfaces blind spots no single model would catch.

## Process

### Step 1: Prepare the Design Doc
Ensure your design document covers:
- Architecture overview + data flow
- Security model
- Reliability/failure handling
- Performance considerations
- Scope boundaries (what's in/out)

### Step 2: Send to Multiple Models
Send the SAME design doc to 2-3 different models independently. Ask:
> "Review this design from a senior architect perspective. Validate architecture, identify security gaps, reliability risks, performance bottlenecks, and scope creep. Be blunt."

**Important:** Don't let models see each other's reviews initially — you want independent analysis.

### Step 3: Collect Reviews
Save each review to a dedicated folder:
```
~/docs/plans/<project>-reviews/
├── chatgpt-review.md
├── gemini-review.md
├── opus-review.md
└── SYNTHESIS.md
```

### Step 4: Synthesize Findings
Create a synthesis document with:

1. **Universal Agreements** — Issues all models flagged (these are real problems)
2. **Disagreements** — Where models conflict (requires your judgment)
3. **Best Insights** — Unique valuable ideas from each review
4. **What to Ignore** — Overengineering or incorrect critiques
5. **Revised Plan** — Updated architecture based on feedback

### Step 5: Decide & Document
For each major critique:
- Accept → Update design
- Defer → Mark as v2 consideration
- Reject → Document why (model was wrong)

## When to Use

✅ Significant architecture decisions (new system, major refactor)
✅ Security-critical systems (AI with terminal access, user data)
✅ Complex multi-component designs
✅ Before 2+ weeks of implementation work

❌ Simple features or bug fixes
❌ Time-critical decisions (overhead not worth it)
❌ Well-trodden patterns (CRUD API, standard auth flow)

## Pitfalls

- **Analysis paralysis** — Set a deadline. Reviews inform decisions, they don't make them.
- **Contradiction confusion** — Models will disagree. Your job is to decide, not find consensus.
- **Overengineering from feedback** — Some models suggest solutions to problems you don't have yet. Push back.
- **Ignoring the synthesis** — Don't just collect reviews. Force yourself to write the synthesis document.

## Example Output Structure

```markdown
## Universal Agreements (All N models)
| Issue | Verdict | Action |
|-------|---------|--------|
| Security gap X | Valid | Fix before build |

## Disagreements
| Topic | Model A | Model B | Model C | Decision |
|-------|---------|---------|---------|----------|

## Best Insights
1. Model X's idea about Y — implement in Phase 1
2. Model Z's pattern for W — save for v2

## What to Ignore
- Model A's suggestion about X — overengineering for our scale

## Revised Phase 1 Plan
[Updated implementation plan]
```

## Tools

- Save reviews with `file_write` to `~/docs/plans/<project>-reviews/`
- Use `memory` tool to save final architecture decisions
- Consider saving the synthesis as a reference for future similar projects
