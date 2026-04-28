---
name: superpowers
description: >
  Spec-first, TDD, subagent-driven software development workflow. Use when:
  (1) building any new feature or app — triggers brainstorm → plan → subagent execution loop,
  (2) debugging a bug or test failure — triggers systematic root-cause process,
  (3) user says "let's build", "help me plan", "I want to add X", or "this is broken",
  (4) completing a feature branch — triggers test verification + merge/PR options.
  NOT for: one-liner fixes (just edit), reading code, or non-code tasks.
  Requires exec tool and sessions_spawn.
---

# Superpowers — OpenClaw Edition

Adapted from [obra/superpowers](https://github.com/obra/superpowers). Mandatory workflow — not suggestions.

## The Pipeline

```
Idea → Brainstorm → Plan (vertical-sliced, phased) → Subagent-Driven Build (TDD, one phase at a time) → Five-Axis Review → Finish Branch
```

Every coding task follows this pipeline. "Too simple to need a design" is always wrong.

---

## Phase 1: Brainstorming

**Trigger:** User wants to build something. Activate before touching any code.

**See:** [references/brainstorming.md](references/brainstorming.md)

**Summary:**
1. Explore project context (files, docs, recent commits)
2. Ask clarifying questions — **one at a time**, prefer multiple choice
3. Propose 2–3 approaches with trade-offs + recommendation
4. Present design in sections, get approval after each
5. Write design doc → `docs/plans/YYYY-MM-DD-<topic>-design.md` → commit
6. Hand off to **Phase 2: Writing Plans**

**HARD GATE:** Do NOT write any code until user approves design.

---

## Phase 2: Writing Plans

**Trigger:** Design approved. Activated by brainstorming phase.

**See:** [references/writing-plans.md](references/writing-plans.md)

**Summary:**
- Write a detailed task-by-task implementation plan
- Each task = 2–5 minutes: write test → watch fail → implement → watch pass → commit
- **Tasks MUST be organized into phases ordered by dependency graph** (foundation → core → UI → integration)
- **Each phase uses VERTICAL SLICING** — a single task covers DB + API + UI for one feature slice, NOT "all DB then all API then all UI"
- **Explicit phase gates** — build ONE phase at a time, never all at once. This prevents context window blowout.
- Save to `docs/plans/YYYY-MM-DD-<feature>.md`
- Announce: `"I'm using the writing-plans skill to create the implementation plan."`
- After saving, offer two execution modes:
  - **Subagent-driven (current session):** `sessions_spawn` per task + two-stage review
  - **Manual execution:** User runs tasks themselves

---

## Phase 3: Subagent-Driven Development

**Trigger:** Plan exists, user chooses subagent-driven execution.

**See:** [references/subagent-development.md](references/subagent-development.md)

### ⚠️ Subagent Scope Guardrails (CRITICAL — prevents timeouts)

Subagents that try to do too much time out and produce ZERO output. Follow these constraints:

- **Each subagent task: AT MOST 3 file edits + 1 test run**
- If a task needs more than 3 edits, **split it into 2+ smaller subagent tasks**
- Use **max_iterations=15** on delegate_task for coding subagents (prevents runaway)
- After 3 file edits, the subagent should **STOP and report** — even if incomplete
- **Incomplete subagent work > timed-out subagent work** (partial output vs zero output)
- **Never give a subagent more than one task from the plan at a time**

These guardrails were added after 3/3 subagents timed out in a single session, producing nothing.

### Per-task loop (OpenClaw):
1. `sessions_spawn` an implementer subagent with task + full plan context
2. Wait for completion announcement
3. `sessions_spawn` a spec-reviewer subagent → must confirm code matches spec
4. `sessions_spawn` a code-quality reviewer subagent → must approve quality
5. Fix any issues, re-review if needed
6. Mark task done, move to next
7. Final: dispatch overall code reviewer → hand off to Phase 5

**TDD is mandatory in every task.** See [references/tdd.md](references/tdd.md).

---

#### Debugging (cross-cutting — available at any phase)

**Trigger:** Bug, test failure, unexpected behaviour — any technical issue.

**See:** [references/systematic-debugging.md](references/systematic-debugging.md)

**HARD GATE:** No fixes without root cause investigation first.

**Four phases:**
1. Root Cause Investigation (read errors, reproduce, check recent changes, trace data flow)
2. Pattern Analysis (find working examples, compare, identify differences)
3. Hypothesis + Testing (one hypothesis at a time, test to prove/disprove)
4. Fix + Verification (fix at root, not symptom; verify fix doesn't break anything)

---

### Phase 5: Five-Axis Review

**Trigger:** All tasks built and verified. Before finishing branch.

**Five review dimensions (all must pass):**

1. **Correctness** — Does every feature work as specified? Every acceptance criterion met?
2. **Readability & Simplicity** — Would another developer understand this? Any over-engineering?
3. **Architectural Conformance** — Does the code follow existing project patterns? Module boundaries maintained? No leaky abstractions?
4. **Security** — No SQL injection, XSS, hardcoded secrets, path traversal, unsafe deserialization. Parameterised queries everywhere. ORM usage where applicable.
5. **Performance** — Efficient queries, proper indexing, no N+1, no unnecessary re-renders, no memory leaks.

**Process:**
- Run `requesting-code-review` skill (covers security scan + independent reviewer)
- Supplement with **five-axis checklist** — explicitly verify each dimension
- If critical/important issues found → create a fix plan (use writing-plans skill), implement fixes
- Only proceed to Phase 6 when all five axes pass

---

## Phase 6: Finishing a Branch

1. Run the test suite one more time. **Scope Verification (Step 1.5)**: Compare the final diff against the original spec. Flag scope creep (extra features not requested), missing features (spec items not implemented), and Potemkin interfaces (components that look wired up but aren't). Don't declare "done" until every item from the original spec is verified working.

**See:** [references/finishing-branch.md](references/finishing-branch.md)

**Summary:**
1. Verify all tests pass
2. Determine base branch
3. **Scope Verification** — compare final diff against the original spec/task request. Check: Did we build exactly what was asked? Any scope creep, missing features, or Potemkin interfaces (features that look functional but aren't actually wired up)? Flag discrepancies before declaring done.
4. Present 4 options: merge locally / push + PR / keep / discard
5. Execute choice
6. Clean up

---

## OpenClaw Subagent Dispatch Pattern

When dispatching implementer or reviewer subagents, use `sessions_spawn`:

```
Goal: [one sentence]
Context: [why it matters, which plan file]
Files: [exact paths]
Constraints: [what NOT to do — no scope creep, TDD only]
Verify: [how to confirm success — tests pass, specific command]
Task text: [paste full task from plan]
```

Run `sessions_spawn` with the task as a detailed prompt. The sub-agent announces results automatically.

---

## Key Principles

- **One question at a time** during brainstorm
- **TDD always** — write failing test first, delete code written before tests
- **YAGNI** — remove unnecessary features from all designs
- **DRY** — no duplication
- **Systematic over ad-hoc** — follow the process especially under time pressure
- **Evidence over claims** — verify before declaring success
- **Frequent commits** — after each green test
