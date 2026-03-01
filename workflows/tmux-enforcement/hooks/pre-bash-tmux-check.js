#!/usr/bin/env node
/**
 * pre-bash-tmux-check.js
 * PreToolUse hook: Blocks dev server commands when not running inside tmux.
 *
 * Claude passes the tool input via stdin as JSON.
 * Exit codes:
 *   0 = allow
 *   2 = block the tool call
 *
 * Install as a PreToolUse hook matching the "Bash" tool.
 */

let input = {};

try {
  const raw = require('fs').readFileSync('/dev/stdin', 'utf8').trim();
  if (raw) {
    input = JSON.parse(raw);
  }
} catch (_) {
  // If stdin is empty or not JSON, allow through
  process.exit(0);
}

// Detects dev server commands and blocks them when not in tmux
const cmd = input.tool_input?.command || '';
const devServerPattern = /(npm run dev|pnpm dev|yarn dev|bun run dev|manage\.py runserver|uvicorn|fastapi run|next dev|vite|webpack-dev-server)/;

if (devServerPattern.test(cmd) && !process.env.TMUX) {
  console.error('[Hook] BLOCKED: Dev server must run in tmux for log access');
  console.error('[Hook] Use: tmux new-session -d -s dev "' + cmd + '"');
  console.error('[Hook] Then attach: tmux attach -t dev');
  process.exit(2);  // exit(2) = block the tool call
}

// All clear
process.exit(0);
