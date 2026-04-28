# Brainstorming Reference

Source: obra/superpowers brainstorming skill

## Preparation (before first question)

Before starting the brainstorm Q&A, load all relevant context so you can propose informed approaches:

1. **Load the superpowers skill + all references** — brainstorming.md, writing-plans.md, subagent-development.md, tdd.md
2. **Load related implementation skills** — claude-code, subagent-driven-development, writing-plans
3. **For web/app projects: load popular-web-designs** — check the catalog, then load 2-3 relevant design templates based on project type (dashboard? consumer app? dev tool?)
4. **Check for existing plans** — read any docs/plans/ files that relate to the project
5. **Explore project context** — check files, docs, recent commits if the project already exists

Only AFTER loading this context should you begin the one-question-at-a-time brainstorm. This ensures your proposed approaches reference real design systems and real tooling.

## Checklist (in order)

1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
3. **Propose 2–3 approaches** — with trade-offs and recommendation
4. **Present design** — in sections scaled to complexity, get approval after each section
5. **Write design doc** — `docs/plans/YYYY-MM-DD-<topic>-design.md` → commit
6. **Transition** — invoke writing-plans phase

## Rules

- One question per message only
- Multiple choice preferred over open-ended
- Every project goes through this process — no exceptions for "simple" ones
- HARD GATE: Do NOT write code, scaffold, or implement anything until design is approved
- Propose 2–3 approaches before settling, lead with recommendation

## Questions to Ask

- What are you really trying to do? (purpose)
- What constraints exist? (time, tech stack, dependencies)
- What does success look like? (success criteria)
- What should this NOT do? (scope boundaries)

## Design Sections to Cover

- Architecture overview
- Components and their responsibilities
- Data flow
- Error handling approach
- Testing strategy

## After Design Approval

- Write design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit the design doc
- Hand off to writing-plans — no other skill, no implementation
