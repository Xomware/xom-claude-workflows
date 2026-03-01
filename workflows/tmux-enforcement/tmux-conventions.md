# Xomware tmux Session Naming Conventions

Consistent session names make it easy for Claude agents and developers to find, attach to, and manage long-running processes across projects.

## Standard Session Names

| Session Name | Purpose | Example Command |
|---|---|---|
| `dev` | Primary dev server | `tmux new-session -d -s dev "npm run dev"` |
| `api` | Backend API server | `tmux new-session -d -s api "uvicorn main:app --reload"` |
| `worker` | Background workers / queues | `tmux new-session -d -s worker "celery -A app worker"` |
| `test` | Long-running test watcher | `tmux new-session -d -s test "npm run test:watch"` |
| `build` | Long build processes | `tmux new-session -d -s build "npm run build:watch"` |
| `db` | Local database shell | `tmux new-session -d -s db "psql mydb"` |
| `logs` | Log tailing | `tmux new-session -d -s logs "tail -f /var/log/app.log"` |

## Multi-Service Projects

For projects with multiple services, prefix with the project or service name:

```
<project>-<role>
```

Examples:
- `xomboard-dev` — XomBoard frontend dev server
- `xomboard-api` — XomBoard API server
- `herald-dev` — Herald service dev mode
- `forge-worker` — Forge background worker

## Common Commands

```bash
# Start a session (detached)
tmux new-session -d -s dev "npm run dev"

# List all sessions
tmux list-sessions

# Attach to a session
tmux attach -t dev

# Detach from current session (keep running)
# Press: Ctrl+B, then D

# Kill a session
tmux kill-session -t dev

# Rename a session
tmux rename-session -t old-name new-name

# Run a command in an existing session (from outside)
tmux send-keys -t dev "npm run build" Enter
```

## Agent Usage Pattern

When an agent needs to start a dev server:

```bash
# 1. Check if session already exists
tmux has-session -t dev 2>/dev/null && echo "exists" || echo "not found"

# 2. Start if not running
tmux new-session -d -s dev "npm run dev"

# 3. Wait for ready signal (check logs)
sleep 3 && tmux capture-pane -t dev -p | tail -20
```

## Session Lifecycle

- Sessions started by agents should be killed when the project work is complete.
- Use `tmux kill-session -t <name>` or `tmux kill-server` to clean up all sessions.
- Never leave zombie sessions running — they consume memory and ports.

## Naming Anti-Patterns

❌ `session1`, `session2` — not descriptive  
❌ `s`, `d`, `tmp` — too short  
❌ `my-long-complicated-service-name-with-lots-of-words` — use abbreviations  
✅ `api`, `dev`, `worker` — clear, short, reusable  
