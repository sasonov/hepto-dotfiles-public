# Tools Learnings

## Strategy Tips
- **Cron jobs with subagents**: Never use delegate_task in cron job prompts → It causes timeouts (600s idle limit) → Work directly with search, browser, and file tools instead
- **Memory management**: Memory tool is capped at ~2200 chars → Save detailed findings to FILES in ~/.hermes/research/, not to memory → Memory for facts, files for data
- **Browser research**: `browser_console(expression="document.querySelector('article').innerText")` is 5-10x more token-efficient than browser_snapshot+scrolling → Use for text extraction, fall back to browser_vision for layout/visual content → Not all pages have `<article>` tag; try `document.querySelector('main')`, then `document.body`

## Recovery Tips
- **Cron job timeout (delegate_task)**: Cron jobs have a 600s idle limit → delegate_task spawning exceeds this → Remove all delegate_task calls from cron prompts, add explicit warning at top of prompt
- **DuckDuckGo rate limiting**: DDGS searches can get rate-limited → Add delays between searches, use specific queries → Fall back to browser_navigate for direct page access
- **Ollama model saturation**: Max 3 concurrent models on your server → Queue model swaps rather than launching 4+ simultaneously → Same model multiple times is fine

## Optimization Tips
- **Research pipeline**: Individual research jobs should deliver `local` (silent) → Only the morning summary should deliver to `telegram` → User wants ONE message in the morning, not 5 through the night
- **Web extraction**: Always verify key facts against a second source before including in research findings → Single-source claims have high error rate → Cross-reference with arxiv, official docs, or a second search result
- **Token budget**: Keep cron summaries under 3000 chars → Cron output is delivered as-is → Bloated output wastes tokens on delivery