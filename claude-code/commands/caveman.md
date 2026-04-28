Toggle caveman output compression mode.

Arguments: $ARGUMENTS

If argument is "lite", "full", "ultra", or "off", set that mode. If no argument, show current mode and available levels.

When activating:

Read `skills/software-development/caveman-output/SKILL.md` for full rules. Apply the selected intensity level to ALL subsequent responses until explicitly turned off.

- **lite**: No filler/hedging/pleasantries. Keep articles + full sentences. Professional but tight.
- **full**: Drop articles, fragments OK, short synonyms. Classic caveman. Best for subagent delegation.
- **ultra**: Abbreviate everything (DB/auth/config/req/res/fn), strip conjunctions, arrows for causality (X → Y). Minimum tokens.

When deactivating ("off" or "normal mode"):

Resume normal detailed responses.

Always confirm the mode change and give one example of what output looks like at the new level.