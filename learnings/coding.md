# Coding Learnings

## Strategy Tips
- **Spec before code**: Always write/review specs before implementation → Catches architecture issues early → Superpowers workflow enforces this with plan phase
- **Read existing code first**: Before making changes, read ALL relevant files → Understanding existing patterns prevents contradictory code → Use `read_file` not terminal cat
- **Edge cases in tests**: Write tests for edge cases first, then implementation → Forces thinking about failure modes upfront → TDD catches bugs at write-time

## Recovery Tips
- **Import errors after refactor**: Check all import paths after moving/renaming files → Python won't error until runtime → Use `search_files` to find all references before refactoring
- **Test failures in CI**: Check if failure is in test setup vs actual code → Many CI failures are env issues, not logic bugs → Run tests locally first with `python -m pytest tests/ -q`

## Optimization Tips
- **Patch vs write_file**: Use `patch` for targeted edits, `write_file` for full rewrites → Patch is safer (fuzzy matching, syntax checks) but doesn't work well for large structural changes → write_file for new files or major restructuring
- **Search before grep**: Use `search_files` instead of `terminal grep` → It's ripgrep-backed, faster, and returns structured results → Only use terminal for build/run/debug commands