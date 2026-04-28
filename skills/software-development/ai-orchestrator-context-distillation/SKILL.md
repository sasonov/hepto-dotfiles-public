---
name: ai-orchestrator-context-distillation
description: >
  Architecture pattern for an AI orchestrator agent that monitors multiple autonomous
  coding agent sessions without suffering context rot. Use when building any system where
  one AI needs to oversee multiple other AI agent sessions (Claude Code, Codex, etc.)
  while keeping its own context window clean and useful.
version: 1.0.0
author: Hermes Agent
license: MIT
tags: [architecture, ai-orchestration, context-management, agent-dashboard, claude-code]
---

# AI Orchestrator Context Distillation Pattern

## Problem

When an orchestrator AI (like Hermes) watches multiple autonomous coding agent sessions
(Claude Code, Codex, etc.) in real time, raw terminal output floods its context window
within minutes. File reads, command logs, npm install spam — all noise that crowds out signal.
This is "context rot."

## Solution: Event Distillation, Not Event Streaming

The orchestrator does NOT receive the raw terminal stream. Instead, events pass through
a three-layer architecture:

### Layer 1: Session Manager (parsing)

Each agent session runs in structured output mode (e.g., `claude -p --output-format stream-json`)
or interactive tmux with output capture. The session manager parses the raw stream into
structured events:

```
TOOL_CALL: "read file auth.py"
FILE_EDIT: "modified auth.py lines 12-45"
COMMAND: "ran pytest, 3 passed, 1 failed"
THINKING: "analyzing auth flow..."
RESULT: "completed, commit abc123"
ERROR: "test failed: expected 200, got 403"
```

### Layer 2: Event Database (persistence)

All parsed events go into SQLite with timestamps, session ID, and importance level.
The dashboard UI reads from this for the activity feed. This decouples real-time
streaming from historical analysis.

```
events table: id, session_id, timestamp, type, summary, details_json, importance
```

Importance levels: `lifecycle` (started/finished), `action` (tool calls),
`progress` (command results), `error` (failures/blocks).

### Layer 3: Orchestrator Inbox (distilled summaries)

The orchestrator receives ONLY:

1. **Session lifecycle events** — "session X started", "session X finished task Y",
   "session X is waiting for input". These are tiny messages.
2. **On-demand deep dives** — when asked "what's happening in session 3?", the
   orchestrator queries the event DB and reads the last N structured events, then
   summarizes. Context is loaded only when needed, not continuously.
3. **Error escalation** — if a session fails or gets stuck, THAT event gets pushed
   proactively. Only failures and blockers, not routine progress.

Think: team lead who doesn't sit in every standup but gets paged immediately when
something blocks.

## Data Flow Diagram

```
Agent sessions (stream-json / tmux)
    ↓
Session Manager (parses raw → structured events)
    ↓
SQLite event DB (all events stored with importance)
    ↓
    ├──→ Dashboard UI (full activity feed + terminal stream)
    │
    └──→ Orchestrator Inbox (lifecycle events only + on-demand queries)
```

## Key Insight

The orchestrator doesn't need a continuous connection to sessions. It needs:
- A **pull model** for investigation (query the event DB when asked)
- A **push model** for escalation (errors and blockers only)

This keeps the orchestrator's context window clean and focused, even when
supervising dozens of sessions over hours.

## When to Use This Pattern

- Any dashboard where one AI orchestrates multiple autonomous coding sessions
- Any system where an AI needs "situational awareness" without drowning in data
- When building agent-to-agent monitoring with bounded context windows

## When NOT to Use

- Single-session monitoring (just show the terminal, no need for distillation)
- Non-AI orchestrators (a human can scan raw output fine)
- Short-lived sessions (context rot isn't a problem under ~5 minutes)

## Adapter Interfaces (Extensibility)

The architecture becomes more powerful when both the agent layer and orchestrator layer use adapter interfaces:

### Agent Adapter
```typescript
interface CodingAgentAdapter {
  type: "claude-code" | "opencode" | "codex" | string;
  spawn(task: string, options: SpawnOptions): AgentProcess;
  parseOutput(raw: string): Event[];
  sendInput(processId: string, text: string): void;
  healthCheck(processId: string): AgentStatus;
}
```

Each adapter normalizes its agent's output to the SAME unified event types so the rest of the system is agent-agnostic. Ship one adapter for v1, add more without refactoring.

### Orchestrator Adapter
```typescript
interface OrchestratorAdapter {
  name: string;
  type: "hermes" | "openclaw" | "claude-raw" | string;
  connect(): Promise<OrchestratorConnection>;
  sendMessage(message: string): Promise<string>;
  onEvent(callback: (event: OrchestratorEvent) => void): void;
  getStatus(): Promise<SessionSummary[]>;
  spawnSession(task: string): Promise<string>;
  killSession(sessionId: string): Promise<void>;
}
```

Hermes becomes one implementation. The bridge layer exposes a generic interface so adding a second orchestrator later requires one adapter, zero changes to the dashboard or event pipeline.

## Design Review Findings (from multi-model review)

Key issues identified by 5 different LLM models reviewing the architecture:

### Must-Fix
- **WebSocket auth:** Ticket-based authentication is essential — unauthenticated WS = RCE via terminal hijack
- **Session-scoped events:** WebSocket events must be scoped per session (not global broadcast) to prevent data leakage between users/sessions
- **Input sanitization:** LLM output must be treated as untrusted (stored XSS risk)

### Should-Fix
- **Unified streaming:** Use single WebSocket channel with typed messages instead of WS + SSE split (prevents state desync)
- **Type-safe events:** Use discriminated unions + Zod validation instead of string event types
- **Message queue between Session Manager and Event DB:** Don't write to SQLite synchronously on every stream chunk (use buffer/queue)
- **Capability-based adapters:** Adapters should expose capability manifests, not just normalize output
- **SQLite WAL mode + atomic backups:** Use Litestream for continuous WAL backup; never cp/rsync a live SQLite DB

### Good Ideas from Reviews
- **Shadow Mirror:** Fork session state at a specific event ID for sandboxed testing without interrupting the primary agent
- **Execution Graph model:** Sessions as directed graphs (LLM_CALL → TOOL_USE → CODE_EXEC → HUMAN_REVIEW) instead of flat chats
- **Heartbeat/health monitoring:** Regular checks for agent process health, tmux session existence
- **Session replay:** Event DB enables "time travel debugging" — replay any session from events

## Implementation Notes

- Claude Code's `--output-format stream-json` is the cleanest structured output source
- For interactive tmux sessions, parse ANSI-stripped output with regex patterns
- SQLite is sufficient — events are append-mostly, queries are simple
- The event DB also enables the "activity feed" sidebar in the dashboard UI
- Consider TTL/expiry on events to prevent unbounded DB growth

## Multi-Model Review Process

When reviewing a design document, running multiple models with different focus angles yields far better coverage than one model doing everything:

1. **Architecture** — data flow, component boundaries, extensibility
2. **UX & Security** — auth gaps, attack surface, mobile experience
3. **Scalability** — race conditions, resource exhaustion, failure modes
4. **DevOps** — deployment, monitoring, backups, production readiness
5. **Code/API** — endpoint design, type safety, developer experience
6. **General** — no angle, holistic review

**Critical constraint:** Ollama max 3 concurrent models. Run reviews sequentially or max 1-2 models alongside the active session. Same model multiple times is OK.

**Tips:**
- Use `curl -s http://127.0.0.1:11434/api/chat -d @payload.json` with a temp file (not inline JSON) — large prompts break shell escaping
- Set 180s+ timeout on curl calls; big models like qwen3.5:397b need it
- If a model times out, retry with a shorter prompt (first 4000 chars of design doc instead of 8000)
- Save progress to a JSON file between runs so the script can resume after failures