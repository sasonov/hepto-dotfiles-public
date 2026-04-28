# Research Learnings

## Strategy Tips
- **Cross-referencing sources**: Always verify research findings against 2+ sources before marking as actionable → Single-source claims (especially from vendor blogs) are often inflated → Academic papers + independent benchmarks are more reliable
- **Research pipeline scheduling**: Run 4 silent local jobs + 1 morning summary to Telegram → Reduces notification fatigue while still collecting data → Nightly rotation ensures all topics get covered

## Recovery Tips
- **Agent Frameworks cron timeout**: delegate_task in cron prompt causes timeout → Explicitly prohibit delegate_task at TOP of prompt, not just in body → The model still tried it despite mid-prompt warnings
- **Stale research topics**: If a topic yields diminishing returns after 3+ nights → Rotate it out and add a new angle → Example: "AI Model Landscape" becomes "Open Source Models vs Proprietary Benchmarks" instead

## Optimization Tips
- **Research depth vs breadth**: Spend 60% effort on 1-2 promising sources (deep dive), 40% on broader scan → Full-depth on every source wastes tokens → Web_extract for promising URLs, DDG for broad scanning
- **Gemini Deep Research as comparison**: External research (like Gemini's) often covers different angles → Cross-reference our findings with external summaries → Our research focuses more on self-improvement; external research tends toward architecture patterns