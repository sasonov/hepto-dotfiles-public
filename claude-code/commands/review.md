Run the five-axis code review on current changes.

Read the code review skill first:
- File: `skills/software-development/requesting-code-review/SKILL.md`

Follow the Superpowers Phase 4 workflow:

1. Get the diff (`git diff --cached` or `git diff`)
2. Static security scan (secrets, injection, eval, pickle)
3. Baseline tests and linting
4. Self-review checklist
5. Independent reviewer subagent with five-axis format:
   - Correctness
   - Readability & Simplicity
   - Architecture Conformance
   - Security
   - Performance
6. If failures: auto-fix loop (max 2 cycles)
7. If passed: commit with `[verified]` prefix