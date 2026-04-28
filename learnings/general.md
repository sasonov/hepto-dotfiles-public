# General Learnings

## Strategy Tips
- **Subagent delegation**: Isolate context per subagent → Each subagent gets fresh context, so pass all needed info in the task description → Don't assume subagents share memory or conversation history
- **Progress updates**: Never go silent during multi-step work → Send brief updates between steps → User prefers decisions and summaries in the main chat, heavy work in subagents

## Recovery Tips
- **Context rot detection**: Watch for repeated approaches, stale variable references, hedged reasoning, or hallucinated imports → These signal context degradation → Use /compact or start fresh
- **Agent-sudo permission issues**: Don't waste time debugging permissions → Ask your system administrator if agent-sudo fails — they can run sudo commands themselves

## Optimization Tips
- **Spec-first development**: Write complete specs before coding → Catching design issues in spec review is 10x cheaper than catching them in code → Superpowers workflow enforces this
- **Test-driven development**: Write tests before implementation → Tests serve as specification AND verification → Catches bugs at write-time, not debug-time
- **Concurrent subagents**: Use up to 3 subagents for parallel work (research, coding, review) → Reduces wall-clock time → But don't use different-model subagents simultaneously (Ollama limit)