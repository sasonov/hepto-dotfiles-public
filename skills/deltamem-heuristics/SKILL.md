---
name: deltamem-heuristics
description: "Heuristic rules for managing Hermes's memory tool — deciding when to ADD, REPLACE, MERGE, or REMOVE memory entries. Based on the DeltaMem paper (arXiv:2604.01560) and operational experience. Memory is a scarce resource (~2200 chars); every entry must earn its place."
triggers:
  - "memory"
  - "remember"
  - "forget"
  - "update memory"
  - "I prefer"
  - "correction"
  - "that's wrong"
  - "actually I"
---

# DeltaMem Memory Heuristics

Based on the DeltaMem paper (arXiv:2604.01560) and operational experience with Hermes's memory tool. The memory tool has a fixed capacity of approximately 2200 characters. Every entry must earn its place — this skill provides heuristic rules for deciding when to ADD, REPLACE, MERGE, or REMOVE entries.

## Core Principle

Memory is a scarce resource. Every character spent on a low-value entry is a character that cannot store a high-value entry. The guiding question for any memory operation is: **"Will this entry save time or prevent errors in future sessions?"** If not, don't store it.

## Priority Order

When capacity is tight and entries must compete for space, prioritize in this order:

1. **User preferences** — language, style, communication format, tool preferences (permanent value)
2. **Environment facts** — system configuration, network topology, service locations (durable value)
3. **Procedural knowledge** — how to do recurring tasks, workflow patterns (reusable value)
4. **Task-specific facts** — details about a current project or one-time task (ephemeral value)

Task-specific facts are the first to prune when space is needed. User preferences are the last.

## Operations

### ADD

Add a new memory entry when the user:

- **States a preference**: "I prefer concise responses", "Use German for code comments"
- **Corrects an error**: "Actually, the staging server is at 10.1.1.5, not .3"
- **Shares a fact about themselves**: "I'm sensitive about timezone handling", "My name is pronounced EE-lee-as"
- **Introduces a new constraint**: "Never commit directly to main", "All deployments must go through CI"

Before adding, check: Does a similar entry already exist? If so, consider REPLACE or MERGE instead.

### REPLACE

Replace an existing entry when:

- **New fact contradicts old one**: "I use Linux now" contradicts "Elias uses macOS"
- **Old entry is outdated**: "I use Mac" → "I switched to Linux", "Server is at X" → "Server moved to Y"
- **More accurate version available**: "Deploy with docker-compose" → "Deploy with docker compose" (v2 syntax), "API key is ABC" → "API key is XYZ (rotated)"
- **Same topic, better formulation**: Old entry is vague, new information allows a clearer, more actionable statement

When replacing, do NOT add a new entry alongside the old one. Delete the old one and write the new one. Two entries on the same topic waste capacity and cause confusion.

### MERGE

Merge two entries into one when:

- **Significant overlap**: "Elias prefers English" + "No German responses" — merge to "Elias prefers English; no German responses"
- **Same topic from different angles**: "Always show progress during long tasks" + "Never go silent for >30s" — merge to "Always show progress; never silent >30s"
- **Compoundable context**: "Server A is at 10.1.1.2" + "Server B is at 10.1.1.3" — merge to "Servers: A=10.1.1.2, B=10.1.1.3"

Merging frees capacity by eliminating redundancy. A merged entry should be shorter than the sum of its parts while preserving all essential information.

### REMOVE

Remove an entry when:

- **Stale and task-specific**: Entry hasn't been referenced in 7+ days AND is about a specific task (not a user preference). Examples: "Project X uses TypeScript 4.9", "The bug in auth flow is in middleware.ts"
- **One-time event**: Entry is about an event that won't recur. Examples: "Yesterday's outage was caused by DNS TTL", "Meeting at 3pm on Thursday"
- **Redundant**: Entry duplicates information found in another entry. Examples: "Elias likes short responses" + "Keep responses brief"
- **Superseded**: A newer entry makes this one irrelevant. Examples: old API key when new one is stored, old port number when new one is stored

Do NOT remove:
- User preferences (even if old, they persist until the user changes them)
- Environment facts that are still accurate
- Procedural knowledge that still applies

## Entry Format Guidelines

Each entry should be:

- **Atomic**: One piece of information per entry (makes REPLACE/MERGE/REMOVE easier)
- **Specific**: "Elias prefers bullet points for lists" beats "Elias has formatting preferences"
- **Actionable**: "Use `docker compose` (v2), not `docker-compose` (v1)" beats "Docker compose syntax changed"
- **Concise**: Every character counts. Abbreviate where unambiguous. Drop filler words.

## Examples

### Good entries
- "Elias prefers English; no German responses"
- "Server: A=10.1.1.2, B=10.1.1.3, VPS=10.1.1.1"
- "Always show progress during multi-step tasks; never silent >30s"
- "Never commit directly to main branch"
- "Docker MTU=1450 (fiber UDP fragmentation fix)"

### Bad entries
- "Elias has some preferences about language and stuff" (vague)
- "The user told me something important about servers" (not actionable)
- "Remember to be careful with networking" (too generic)
- "Yesterday we debugged nginx for 2 hours" (ephemeral, not reusable)

## Pitfalls

- **Memory hoarding**: Don't store everything the user says. Only store what will matter in future sessions.
- **Stale entries**: Without removal, memory degrades. Task-specific entries from weeks ago are noise. Prune aggressively.
- **Over-merging**: Don't merge unrelated entries just because they're short. "Elias prefers English" and "Docker MTU is 1450" should stay separate — they have nothing to do with each other.
- **Premature removal**: Don't remove an entry just because it hasn't been referenced recently. Preferences and environment facts are durable.
- **Contradiction tolerance**: Never let two contradictory entries coexist. If you notice a contradiction, resolve it immediately via REPLACE.
- **Capacity panic**: When memory is near capacity, don't just compact everything into a single blob. Individual entries enable surgical MERGE and REMOVE. Compress by merging related entries, not by concatenating everything.

## Integration

- **trajectory-learning**: When learnings are extracted, they may produce memory-worthy entries (user preferences, environment facts). Apply these heuristics.
- **skill-performance-tracking**: Performance data itself is ephemeral and should NOT be stored in memory. Analysis results (e.g., "X skill has chronic failures") could be stored as procedural knowledge — but only if it will change future behavior.