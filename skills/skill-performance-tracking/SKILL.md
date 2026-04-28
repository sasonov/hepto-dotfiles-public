---
name: skill-performance-tracking
description: "Track skill usage and outcomes in a JSONL log. Prerequisite for GEPA-inspired skill evolution — identifies which skills succeed, which fail, and which need improvement. Feeds into the HyperAgents Loop 3 cron job for skill self-improvement."
triggers:
  - "skill performance"
  - "track skill"
  - "log skill outcome"
  - "skill stats"
  - "weekly review"
  - "skill review"
---

# Skill Performance Tracking

Every skill invocation should be logged with its outcome. This data is the foundation for GEPA-inspired skill evolution — without performance data, there's no signal for improvement. The HyperAgents Loop 3 cron job consumes this data to automatically evolve underperforming skills.

## Log Format

Log file: `~/data/skill-performance.jsonl`

One JSON line per skill invocation:

```json
{"timestamp": "2025-04-11T08:30:00Z", "skill": "trajectory-learning", "task": "extract learnings from failed WireGuard debugging", "outcome": "success", "iterations": 2}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `timestamp` | ISO 8601 string | Yes | When the skill was invoked |
| `skill` | string | Yes | Skill name (matches directory name under `~/skills/`) |
| `task` | string | Yes | Brief description of what the skill was asked to do (1-2 sentences max) |
| `outcome` | enum | Yes | `success`, `partial`, or `fail` |
| `iterations` | integer | Yes | Number of attempts/iterations needed (1 = first try, 5+ = struggled) |

### Outcome Definitions

- **success**: Task completed correctly and fully. No manual correction needed.
- **partial**: Task completed but with issues — required manual fix, missed requirements, or produced imperfect output.
- **fail**: Task could not be completed. Skill was abandoned or produced unusable output.

## Logging Procedure

After each skill use:

1. **Determine outcome**: Was the result fully correct (success), mostly correct but needed fixes (partial), or unusable (fail)?
2. **Count iterations**: How many attempts or correction rounds were needed?
3. **Append to JSONL**: Write one line to `~/data/skill-performance.jsonl`
4. **Move on**: Don't overthink the categorization. Consistency matters more than perfection.

### Example Entries

```jsonl
{"timestamp": "2025-04-11T08:30:00Z", "skill": "trajectory-learning", "task": "extract learnings from failed WireGuard debugging", "outcome": "success", "iterations": 2}
{"timestamp": "2025-04-11T09:15:00Z", "skill": "p5js", "task": "create animation with bouncing particles", "outcome": "partial", "iterations": 3}
{"timestamp": "2025-04-11T10:00:00Z", "skill": "systematic-debugging", "task": "debug docker networking issue", "outcome": "fail", "iterations": 5}
{"timestamp": "2025-04-11T10:45:00Z", "skill": "diagramming", "task": "create architecture diagram of home network", "outcome": "success", "iterations": 1}
```

## Analysis

### Reading the JSONL

The JSONL file is a simple line-delimited log. Basic analysis:

```bash
# Count invocations per skill
cat ~/data/skill-performance.jsonl | jq -r '.skill' | sort | uniq -c | sort -rn

# Success rate per skill
cat ~/data/skill-performance.jsonl | jq -r '[.skill, .outcome] | join(" ")' | sort | uniq -c

# Average iterations per skill (lower is better)
cat ~/data/skill-performance.jsonl | jq -r '[.skill, .iterations] | join(" ")' | awk '{sum[$1]+=$2; count[$1]++} END {for (k in sum) printf "%s %.1f\n", k, sum[k]/count[k]}'

# Recent failures (last 7 days)
cat ~/data/skill-performance.jsonl | jq -r 'select(.outcome != "success") | [.timestamp, .skill, .task] | join(" | ")'
```

### Patterns to Look For

1. **High failure rate**: A skill with >40% fail+partial outcomes needs investigation. Is the skill definition unclear? Is it missing context? Are the triggers too broad?
2. **High iteration count**: A skill that consistently needs 3+ iterations is either poorly defined or trying to do too much. Consider splitting or rewriting.
3. **Never triggered**: A skill that has zero invocations in the past 2 weeks may have wrong triggers or may be solving a problem that doesn't arise.
4. **Surprising success**: A skill succeeding in 1 iteration consistently is performing well. Its patterns should be studied and potentially transferred to other skills.
5. **Outcome regression**: If a skill's success rate drops over time, the task environment may have changed (e.g., tool updates, API changes).

## Weekly Review

Every week, summarize performance:

1. **Top performers**: Skills with highest success rate and lowest average iterations
2. **Underperformers**: Skills with highest fail/partial rates or highest average iterations
3. **Action items**: Which underperformers should be revised, split, or deprecated?

Store weekly summaries in `~/data/weekly-skill-reviews/` as markdown files:

```markdown
# Skill Performance Review — Week of 2025-04-07

## Top Performers
- diagramming: 95% success, avg 1.2 iterations (12 invocations)
- trajectory-learning: 88% success, avg 1.8 iterations (8 invocations)

## Underperformers
- systematic-debugging: 40% success, avg 4.1 iterations (5 invocations)
  - Main issue: Tends to hallucinate root causes without verifying
  - Action: Add verification step before proposing fixes

- social-media/xitter: 20% success, avg 3.5 iterations (5 invocations)
  - Main issue: API errors not handled gracefully
  - Action: Update error handling in skill definition

## Trends
- Overall success rate: 72% (up from 68% last week)
- Most used skill: p5js (18 invocations)
```

## Integration with HyperAgents Loop 3

This performance data is consumed by the HyperAgents Loop 3 cron job, which:

1. Reads `~/data/skill-performance.jsonl`
2. Identifies underperforming skills (high fail/partial rate, high iteration count)
3. Automatically rewrites or evolves those skill definitions
4. Logs the evolution in `~/data/skill-evolution-log.jsonl`

The cron job should NOT run more than once per week — skills need time to accumulate meaningful performance data before evolution is warranted.

## Pitfalls

- **Logging overhead**: If logging takes more than 10 seconds, it's too much. Keep entries brief.
- **Gaming the metric**: Don't avoid using a skill just because it might log a "fail". Honest failure data is more valuable than no data.
- ** Survivorship bias**: A skill with 100% success rate on 1 invocation tells you nothing. Trust skills with more data points.
- **Over-rotating on failures**: One failure doesn't mean a skill is broken. Look for patterns (3+ failures across multiple sessions) before taking action.
- **Stale data**: If a skill hasn't been invoked in 30+ days, its performance data may be irrelevant (the environment has changed). Weight recent data more heavily in analysis.