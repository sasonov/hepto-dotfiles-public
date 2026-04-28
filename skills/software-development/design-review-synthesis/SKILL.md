---
name: design-review-synthesis
description: Synthesize multiple agent reviews of a design document into actionable changes before implementation
category: software-development
triggers:
  - "multiple agents reviewed my design"
  - "what did the overnight reviews find"
  - "synthesize all the review findings"
  - "update design based on reviews"
---

# Design Review Synthesis

Use this skill when you have multiple agent reviews of a design/plan document and need to synthesize them into actionable design changes before implementation.

## When to Use

- Multiple agents/models have reviewed a design/plan document from different angles (architecture, security, UX, devops, etc.)
- You need to consolidate findings before approving the design
- User wants to see what changes are needed before moving to implementation
- Prevents building v1 only to refactor for security/reliability later
- **User sends reviews one-by-one** — save each persistently, provide quick analysis, then synthesize all together

## Workflow

### 1. Collect All Reviews

```bash
# Find all review files
ls ~/docs/plans/review-prompt/reviews/
# Or search for review files
search_files(target='files', pattern='*review*.md', path='~/docs')
```

### 2. Read Reviews in Batches

Read 4-6 reviews at a time (to avoid context overflow):

```python
# Example: Read architecture, security, devops, code-api reviews
review_files = [
    'review-architecture-*.md',
    'review-security-*.md',
    'review-devops-*.md',
    'review-code-api-*.md',
]
```

### 3. Categorize Findings by Severity

Create a table:

| # | Risk/Issue | Severity | Reviews Mentioning | Design Change Needed |
|---|------------|----------|-------------------|---------------------|
| 1 | Zombie sessions | 🔴 Critical | 8/24 | Add Reaper Service |
| 2 | SQLite contention | 🔴 Critical | 7/24 | Add write buffering + WAL |
| 3 | No auth/RCE risk | 🔴 Critical | 6/24 | Add auth + VPN-only mode |

**Severity levels:**
- 🔴 Critical: Must fix before implementation (security, data loss, system instability)
- 🟡 High: Should fix in v1 (reliability, performance)
- 🟢 Medium: Can defer to v2 (UX polish, optional features)

### 4. Map Findings to Design Sections

For each finding, identify which section needs updating:

| Finding | Design Section | Change Type |
|---------|---------------|-------------|
| Parser brittleness | 2.1 Session Manager | Add dual-stream storage |
| SQLite lock contention | 2.2 Event Database | Add WAL mode, batch writes |
| No reconciliation | NEW Section 9 | Add Reaper Service |
| No auth | NEW Section 10 | Add Security Architecture |

### 5. Present Options to User

**Option A: Update Design Now** (recommended for critical findings)
- Patch design doc with all critical/high findings
- User approves updated design
- Then proceed to implementation plan

**Option B: Approve Core, Defer to Implementation**
- Approve current design as "MVP core"
- Add security/reliability as Phase 2 tasks
- Risk: Technical debt, refactoring later

### 6. Patch Design Document

Use structured patches:

```bash
# For new sections
patch mode='patch' with heredoc containing:
*** Begin Patch
*** Update File: ~/docs/plans/design.md
@@ After Section 8 @@
+## 9. New Section Title
+...
```

```bash
# For targeted edits
patch mode='replace' path='design.md' old_string='...' new_string='...'
```

### 7. Update Memory

Save key design decisions to memory:

```python
memory(action='replace', target='memory', content='ProjectName: Key architecture decisions, security model, reliability patterns. Design approved YYYY-MM-DD, ready for Phase 2.')
```

## Output Format

Present synthesis as:

1. **Summary Table** - All critical/high risks with review counts
2. **Recommended Design Changes** - New sections + updated sections
3. **Options** - Update now vs. defer (with your recommendation)
4. **After Approval** - Update memory, proceed to implementation plan

## Pitfalls

- **Don't skip reading reviews** - User explicitly wants findings addressed
- **Don't implement yet** - This is design phase, not implementation
- **Don't ignore security findings** - Critical security issues must be in design before coding
- **Count review mentions** - "8/24 reviews mentioned this" shows consensus
- **Be opinionated** - Recommend Option A for critical findings (user prefers pushback)

## Example Output Structure

```
## 📊 Overnight Review Synthesis (24 Reviews Across 4 Models × 6 Angles)

### CRITICAL RISKS (Must Address in Design)

| # | Risk | Severity | Reviews Mentioning | Design Change Needed |
|---|------|----------|-------------------|---------------------|
| 1 | Zombie Sessions | 🔴 Critical | 8/24 | Add Reaper Service |

### RECOMMENDED DESIGN ADDITIONS

**NEW Section 9: Reliability & Recovery**
- Reaper Service, Startup Hook, Graceful Shutdown

**NEW Section 10: Security Architecture**
- Auth modes, Docker sandbox, Command allowlisting

## MY RECOMMENDATION

**Option A: Update Design Now** (I recommend this)
- Pros: Security/reliability baked in from start
- Cons: Takes ~30 min to update design

**What do you want to do?**
```

## Related Skills

- `writing-plans` - For Phase 2 (implementation plan) after design approval
- `plan` - Plan mode for Hermes
- `github-code-review` - For code reviews (different from design reviews)

## Patterns Learned (Zenkro Review - April 2026)

### Three-Process Architecture Pattern
When reviewing a monolithic design, consider splitting into independent processes:
- **Session Daemon** - failure-prone (child processes, stream parsing)
- **UI** - renders views, holds no critical state
- **Gateway** - stateless proxy to external services

**Benefit:** Independent failure/recovery. If daemon crashes, UI stays up, sessions survive in tmux.

### Append-Only Event Log Pattern
Make events the only source of truth. Session status is a projection (materialized view) derived from the latest event.

```sql
-- Append-only event log
CREATE TABLE event_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  type TEXT NOT NULL,
  data_json TEXT,
  emitted_by TEXT NOT NULL,    -- 'daemon', 'user:alice', 'orchestrator:agent'
  ts DATETIME DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
);

-- Materialized view, rebuilt from events
CREATE TABLE session_state (
  session_id TEXT PRIMARY KEY,
  status TEXT NOT NULL,        -- derived from latest lifecycle event
  owner TEXT NOT NULL,
  task TEXT,
  last_event_id INTEGER,
  last_event_ts DATETIME
);
```

**Benefit:** Eliminates state sync bugs, enables session forking, free audit trails, Reaper becomes just another event emitter.

### Universal Agreement Table
When synthesizing multiple reviews, create a table of what ALL models agree on:

| Issue | Consensus | Action |
|-------|-----------|--------|
| Docker volume `:rw` is a security hole | ✅ All agree | Use overlayfs or `:ro` |
| Regex allowlisting is bypassable | ✅ All agree | Rely on container isolation |

**Benefit:** Shows clear priorities, eliminates debate on settled issues.

### Disagreement Resolution Table
When models disagree, present their positions and your recommendation:

| Topic | Model A | Model B | Model C | **Final Decision** |
|-------|---------|---------|---------|-------------------|
| Adapter interfaces | "Strong" | "Strong" | "Premature" | **Defer** — Write directly |

**Benefit:** Makes trade-offs explicit, shows reasoning.

### Save Reviews Persistently During Session
When user sends reviews one-by-one:
1. Create a review directory: `mkdir -p ~/docs/plans/<project>-reviews/`
2. Save each review as a separate file immediately
3. Provide quick analysis after each (valid critiques vs. questionable vs. valuable)
4. Synthesize all together at the end

**Benefit:** Preserves context across sessions, user can reference individual reviews later.

### Security Must-Fixes Checklist
For any AI system with terminal access:
- [ ] `network_mode: none` or restrictive policy on containers
- [ ] `:ro` or overlayfs for workspace mounts
- [ ] Mandatory auth even behind VPN
- [ ] Container is the sandbox — drop regex allowlisting
- [ ] Stateful parser with buffer + flush for streaming JSON
