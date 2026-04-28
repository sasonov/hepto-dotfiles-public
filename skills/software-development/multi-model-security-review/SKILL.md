---
name: multi-model-security-review
description: Run independent security audits using 2-3 different AI models, then fix all critical/high issues before deployment.
category: software-development
tags: [security, code-review, multi-model, production]
---

# Multi-Model Security Review

Use this skill before deploying production code, especially for systems handling:
- API keys/secrets
- Financial transactions
- User data
- Network connectivity

## When to Use

- After completing implementation of a production feature
- Before first deployment to production
- After major refactoring of security-sensitive code
- When user explicitly requests security audit

## Workflow

### Phase 1: Independent Reviews (Parallel)

Spawn 2-3 subagents with **different models** to review the same codebase independently:

```python
# Subagent 1: qwen3.5:397b-cloud
delegate_task(
    goal="Security audit: Find vulnerabilities, validation gaps, credential leaks, injection risks",
    context="Files: src/*.js, test/*.test.js. Focus on: API key exposure, input validation, BigInt precision, error handling, race conditions.",
    toolsets=["terminal", "file"]
)

# Subagent 2: glm-5.1:cloud
delegate_task(
    goal="Security audit: Hunt for security bugs, credential leaks, validation issues, attack vectors",
    context="Same codebase. Look for: path traversal, SSRF, rate limiting, memory leaks, DoS vectors.",
    toolsets=["terminal", "file"]
)

# Subagent 3: gemma4:31b-cloud (optional third opinion)
delegate_task(
    goal="Security audit: Find ALL security vulnerabilities with file:line citations",
    context="Rate each issue: Critical/High/Medium/Low with exploit scenarios.",
    toolsets=["terminal", "file"]
)
```

**Important:** Use only models confirmed available in current session. Do NOT assume Claude Opus or other models are available just because skill docs mention them.

### Phase 2: Synthesize Findings

Create a summary table:

| Severity | Count | Top Issues |
|----------|-------|------------|
| Critical | N | List top 3 |
| High | N | List top 3 |
| Medium | N | List top 3 |

Save detailed findings to `docs/reviews/security-review-{date}.md`

### Phase 3: Fix All Critical + High

For each Critical/High issue:
1. Read the affected file(s)
2. Implement fix with security best practices:
   - **Input validation**: Regex patterns for addresses, IDs, URLs
   - **Credential handling**: Never interpolate into URLs, use provider SDK params
   - **Path safety**: `resolve()` + directory containment checks
   - **Precision**: Use proper libraries (e.g., `formatUnits` not `Number()`)
   - **Resource limits**: Cache size caps, fetch timeouts, connection limits
3. Update tests to cover the fixed edge case
4. Run full test suite

### Phase 4: Commit & Document

```bash
git commit -m "security: fix all critical and high severity issues from security audits

- file.js: Issue description → Fix applied
- ...

Security audits by: {model1}, {model2}, {model3}
Issues fixed: X Critical, Y High, Z Medium
All tests passing: N/M"
```

## Common Security Issues & Fixes

| Issue | Pattern | Fix |
|-------|---------|-----|
| API keys in URLs | `fetch(\`https://api?key=${key}\`)` | Use SDK's `apiKey` parameter |
| Path traversal | `readFile(process.env.PATH)` | `resolve()` + `startsWith(projectRoot)` |
| BigInt precision | `Number(bigint)` | `formatUnits(bigint, decimals)` |
| Unbounded cache | `new Map()` | Add `MAX_SIZE` + LRU eviction |
| No fetch timeout | `fetch(url)` | `AbortController` + `setTimeout` |
| Missing validation | Direct use of env vars | Regex validation on all inputs |
| Silent errors | `catch { return null }` | Log with prefix + stack trace |

## Available Models (Verify Per Session)

Confirmed working models vary by session. Common options:
- `qwen3.5:397b-cloud` — Strong security analysis
- `glm-5.1:cloud` — Thorough, detail-oriented
- `gemma4:31b-cloud` — Good for edge cases

**Do NOT use:** `claude-opus-4-6`, `claude-sonnet-4` (often unavailable despite skill docs)

## Output Files

- `docs/reviews/security-review-{date}.md` — Full findings from all models
- Updated test files with new edge case coverage
- Git commit with security fix summary

## Example

See TMXBot Discord deposit monitor (April 2026):
- 3 independent security audits
- 5 Critical, 7 High issues found
- All fixed before deployment
- 16 tests passing
- Production readiness: 4.9/10 → 8.5/10
