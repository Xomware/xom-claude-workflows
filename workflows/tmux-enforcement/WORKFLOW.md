# tmux Enforcement Workflow

## Overview

This workflow enforces the use of **tmux** for long-running commands (dev servers, build watchers, test runners) executed by Claude agents. Without tmux, log output from background processes is lost and agents cannot inspect or resume sessions.

## Problem

When an AI agent runs `npm run dev` or `uvicorn` directly in a shell, the process:
- Blocks the shell or runs silently in background
- Produces logs the agent cannot later retrieve
- Cannot be resumed or attached to in a new session
- Dies when the agent session ends

## Solution: PreToolUse Hook

A PreToolUse hook (`pre-bash-tmux-check.js`) intercepts Bash tool calls and blocks dev server commands when the shell is **not already inside a tmux session**.

### Hook Behavior

| Condition | Result |
|---|---|
| Dev server command + inside tmux | ✅ Allowed |
| Dev server command + NOT in tmux | 🚫 Blocked (exit code 2) |
| Non-dev-server command | ✅ Always allowed |

### Detected Commands

The hook blocks these patterns unless inside tmux:

- `npm run dev`
- `pnpm dev`
- `yarn dev`
- `bun run dev`
- `manage.py runserver` (Django)
- `uvicorn` (FastAPI/ASGI)
- `fastapi run`
- `next dev` (Next.js)
- `vite` (Vite dev server)
- `webpack-dev-server`

## Installation

### 1. Install the hook

Copy `hooks/pre-bash-tmux-check.js` to your Claude hooks directory and register it as a `PreToolUse` hook in your Claude config:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node /path/to/pre-bash-tmux-check.js"
          }
        ]
      }
    ]
  }
}
```

### 2. How to correctly start a dev server

When blocked, the hook will print the correct command:

```bash
# Start a named tmux session with the dev server
tmux new-session -d -s dev "npm run dev"

# Attach to view logs
tmux attach -t dev

# Detach (keep running)
Ctrl+B, D
```

See [tmux-conventions.md](../tmux-conventions.md) for Xomware session naming standards.

## Why exit(2)?

Claude hooks use exit codes to signal behavior:
- `exit(0)` = success, allow the tool call
- `exit(1)` = non-blocking warning/error
- `exit(2)` = **block the tool call** (the agent must not proceed)

## Testing

Run the unit tests:

```bash
node hooks/pre-bash-tmux-check.test.js
```

## References

- [tmux-conventions.md](../tmux-conventions.md) — session naming standards
- [Claude Hooks Documentation](https://docs.anthropic.com/claude/hooks)
