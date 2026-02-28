# Session Persistence for Cross-Session Continuity

## Problem

Claude agents have no memory between sessions. Each session starts cold — no knowledge of:
- What was worked on last time
- What decisions were made and why
- What's in-progress vs. done
- What blockers exist

This forces the user (or orchestrator) to re-explain context every session, wasting time and tokens.

## Solution: Session Summaries

At the **end of every session**, agents write a structured summary to `.claude/sessions/YYYY-MM-DD-<label>.md`. At the **start of the next session**, the agent reads the latest summary to resume seamlessly.

---

## How It Works

```
Session End
    │
    ▼
Write summary → .claude/sessions/2026-02-28-forge-auth.md
                 (what was done, decisions, next steps, blockers)

[time passes]

Session Start
    │
    ▼
Find latest summary for this label/context
    │
    ▼
Read summary → load context
    │
    ▼
Resume where previous session left off
```

---

## File Location

```
<repo-root>/
└── .claude/
    └── sessions/
        ├── .gitkeep
        ├── 2026-02-28-forge-auth.md
        ├── 2026-02-27-forge-auth.md
        ├── 2026-02-27-forge-payments.md
        └── 2026-02-25-jarvis-planning.md
```

**Naming:** `YYYY-MM-DD-<label>.md`
- `YYYY-MM-DD` — date of the session
- `<label>` — agent/task label (e.g., `forge-auth`, `jarvis-planning`, `boris-triage`)

---

## Agent Instructions

### End of Session

```markdown
## Session Wrap-Up
Before ending, write a session summary to `.claude/sessions/YYYY-MM-DD-<label>.md`
using the template from `workflows/session-persistence/session-summary-template.md`.

Include:
- What was accomplished
- Key decisions made (and why)
- What's in-progress / incomplete
- Next steps for the next session
- Any blockers
```

### Start of Session

```markdown
## Session Resume
1. Check `.claude/sessions/` for the most recent summary with your label
2. If found: read it and use it to resume context
3. If not found: start fresh (no prior context)
```

---

## Which Agents Use This

| Agent | When to Write | Label Pattern |
|-------|--------------|---------------|
| **Forge** | After every build/implementation session | `forge-<task>` |
| **Jarvis** | After planning or oversight sessions | `jarvis-<context>` |
| **Boris** | After complex triage sessions | `boris-<date>` |
| Any sub-agent | After multi-step tasks | `<agent>-<task>` |

---

## Example Summary

```markdown
# Session Summary: forge-auth — 2026-02-28

## Accomplished
- Implemented JWT authentication middleware (src/auth/jwt.py)
- Added token refresh logic (src/auth/refresh.py)
- 12 tests passing

## Key Decisions
- Used RS256 (asymmetric) over HS256: better for microservices (can verify without secret)
- Token expiry: 15min access, 7d refresh (matches industry standard)
- Stored refresh tokens in Redis, not DB (performance)

## In Progress
- OAuth provider integration (Google) — 40% done
  - File: src/auth/oauth.py (created, needs callback handler)

## Next Steps
1. Implement OAuth callback at /auth/google/callback
2. Add session invalidation endpoint
3. Integration test with frontend

## Blockers
- Need Google OAuth client ID from Dom (check TOOLS.md)
- Redis not running locally — use docker-compose up redis

## Files Modified
- src/auth/jwt.py (new)
- src/auth/refresh.py (new)
- src/auth/oauth.py (partial)
- tests/test_auth.py
```

---

## See Also

- `session-summary-template.md` — Copy-paste template
- `persistence-script.sh` — Helper to write/read session state from CLI
