Create a detailed implementation plan from the approved design.

Read the writing-plans skill first:
- File: `skills/software-development/writing-plans/SKILL.md`

Follow the Superpowers Phase 2 workflow:
- Tasks must be bite-sized (2-5 min each)
- Vertical slicing: each task = one full-stack feature slice (DB + API + UI)
- Organize into phases ordered by dependency graph
- Each task: write failing test → confirm fail → implement → confirm pass → commit
- Include exact file paths, complete code examples, exact commands
- Save to `docs/plans/YYYY-MM-DD-<feature>.md`

After saving, ask: "Subagent-driven or manual execution?"