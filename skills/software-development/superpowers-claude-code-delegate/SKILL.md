---
name: superpowers-claude-code-delegate
description: >
  Execute superpowers Phase 3 (subagent-driven development) by delegating to Claude Code via ACP.
  Use when: you have an implementation plan and want Claude Code to handle TDD + commits autonomously.
  Alternative to sessions_spawn pattern — leverages Claude Code's native TDD workflow.
---

# Superpowers + Claude Code Delegation

Alternative to the standard `sessions_spawn` subagent pattern. Delegates implementation to Claude Code via ACP (Agent Communication Protocol).

## When to Use

- You have an existing implementation plan (Phase 2 complete)
- You want Claude Code to handle the full TDD loop autonomously
- The tasks are straightforward enough that you trust Claude Code's judgment
- You prefer fewer subagent handoffs (no separate spec/code reviewers needed)

## When NOT to Use

- Complex tasks needing explicit spec-reviewer + code-quality-reviewer subagents
- When you want fine-grained control over each task's review process
- Claude Code not available (missing credentials, ACP not configured)

## Pattern

```python
delegate_task(
    acp_command="claude",
    acp_args=["--acp", "--stdio", "--model", "claude-sonnet-4-6"],
    goal="Implement X following superpowers TDD workflow",
    context="""
    Project: [name]
    Location: [path]
    Plan file: [path to plan .md]
    Design spec: [path to spec .md]
    
    Current state:
    - [what's already done]
    - [dependencies installed, directories created, etc.]
    
    Follow the implementation plan tasks in order.
    For each task:
    1. Write failing test first
    2. Run test to confirm it fails
    3. Implement minimum code to pass
    4. Run test to confirm pass
    5. Commit with meaningful message
    
    TDD is mandatory. No scope creep.
    """,
    toolsets=["terminal", "file"],
)
```

## Key Differences from sessions_spawn Pattern

| Aspect | sessions_spawn (standard) | claude-code delegate |
|--------|--------------------------|---------------------|
| Subagent type | Hermes native agent | Claude Code CLI via ACP |
| Review process | Explicit spec + code quality reviewers | Claude Code self-reviews |
| Commits | Agent makes commits | Claude Code makes commits |
| Control | Fine-grained per task | Coarse-grained (full plan) |
| Best for | Complex tasks needing oversight | Straightforward implementations |

## Example Context Template

```
Project: [Project Name]
Location: ~/path/to/project/
Plan file: ~/path/to/project/docs/superpowers/plans/YYYY-MM-DD-feature.md
Design spec: ~/path/to/project/docs/superpowers/specs/YYYY-MM-DD-feature-design.md

Current state:
- Repo cloned, basic scaffold started
- package.json configured with type:module, scripts for start/test
- .gitignore, .env.example created
- src/ and test/ directories exist
- npm dependencies installed

Follow the implementation plan tasks in order:
1. [Task 1 name]
2. [Task 2 name]
3. [etc.]

For each task:
1. Write failing test first
2. Run test to confirm it fails
3. Implement minimum code to pass
4. Run test to confirm pass
5. Commit with meaningful message

Use superpowers:subagent-driven-development workflow. TDD is mandatory. No scope creep.
```

## Verification

After Claude Code completes:
1. Check git log for commits
2. Run tests to verify all pass: `npm test` or equivalent
3. Review file structure matches plan
4. Proceed to Phase 5 (Finishing Branch) if all tasks complete

## Pitfalls

- **Claude Code may scope-creep** — explicitly state "no scope creep" in context
- **May skip tests if not emphasized** — explicitly state "TDD is mandatory"
- **Model selection matters** — use capable model (claude-sonnet-4-6 or better)
- **ACP must be configured** — ensure `claude` command is available and authenticated
