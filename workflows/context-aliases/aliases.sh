#!/usr/bin/env bash
# context-aliases/aliases.sh
# Role-specific Claude aliases for focused, efficient sessions.
#
# INSTALL: Add to ~/.zshrc or ~/.bashrc:
#   source /path/to/xom-claude-workflows/workflows/context-aliases/aliases.sh
#
# Or copy contexts and source from there:
#   mkdir -p ~/.claude/contexts
#   cp contexts/* ~/.claude/contexts/
#   source aliases.sh

# ---------------------------------------------------------------------------
# Helper: resolve context file path
# Priority: ~/.claude/contexts/<name>.md → repo-local contexts/<name>.md
# ---------------------------------------------------------------------------
_claude_context_path() {
  local name="$1"
  local global="$HOME/.claude/contexts/${name}.md"
  local local_path
  local_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/contexts/${name}.md"

  if [[ -f "$global" ]]; then
    echo "$global"
  elif [[ -f "$local_path" ]]; then
    echo "$local_path"
  else
    echo ""
  fi
}

# ---------------------------------------------------------------------------
# claude-dev — Implementation mode
# Focus: code, tests, type safety, explicit over clever
# ---------------------------------------------------------------------------
claude-dev() {
  local ctx
  ctx="$(_claude_context_path dev)"
  if [[ -z "$ctx" ]]; then
    echo "Error: dev context not found. Run: cp contexts/dev.md ~/.claude/contexts/" >&2
    return 1
  fi
  claude --system-prompt "$(cat "$ctx")" "$@"
}

# ---------------------------------------------------------------------------
# claude-review — Code review mode
# Focus: correctness, security, performance, standards
# ---------------------------------------------------------------------------
claude-review() {
  local ctx
  ctx="$(_claude_context_path review)"
  if [[ -z "$ctx" ]]; then
    echo "Error: review context not found. Run: cp contexts/review.md ~/.claude/contexts/" >&2
    return 1
  fi
  claude --system-prompt "$(cat "$ctx")" "$@"
}

# ---------------------------------------------------------------------------
# claude-research — Analysis and research mode
# Focus: comprehensive analysis, tradeoffs, alternatives, sourced claims
# ---------------------------------------------------------------------------
claude-research() {
  local ctx
  ctx="$(_claude_context_path research)"
  if [[ -z "$ctx" ]]; then
    echo "Error: research context not found. Run: cp contexts/research.md ~/.claude/contexts/" >&2
    return 1
  fi
  claude --system-prompt "$(cat "$ctx")" "$@"
}

# ---------------------------------------------------------------------------
# claude-infra — Infrastructure mode
# Focus: safety, cost, rollback plans, least-privilege
# ---------------------------------------------------------------------------
claude-infra() {
  local ctx
  ctx="$(_claude_context_path infra)"
  if [[ -z "$ctx" ]]; then
    echo "Error: infra context not found. Run: cp contexts/infra.md ~/.claude/contexts/" >&2
    return 1
  fi
  claude --system-prompt "$(cat "$ctx")" "$@"
}

# ---------------------------------------------------------------------------
# install-contexts — Copy context files to ~/.claude/contexts/
# ---------------------------------------------------------------------------
install-claude-contexts() {
  local src_dir
  src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/contexts"
  local dest_dir="$HOME/.claude/contexts"

  mkdir -p "$dest_dir"
  cp "$src_dir"/*.md "$dest_dir/"
  echo "✓ Installed Claude contexts to $dest_dir"
  echo "  Available: dev, review, research, infra"
}

export -f claude-dev claude-review claude-research claude-infra install-claude-contexts 2>/dev/null || true
