#!/usr/bin/env bash
# ==============================================================================
# Xomware Conventional Commits — setup.sh
#
# Installs the commit-msg git hook into the current repository.
#
# Usage:
#   bash <path-to-xom-claude-workflows>/workflows/conventional-commits/setup.sh
#
# Run from the root of any repository you want to enforce conventional commits on.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SOURCE="${SCRIPT_DIR}/hooks/commit-msg"
HOOKS_DIR=".git/hooks"
HOOK_DEST="${HOOKS_DIR}/commit-msg"

echo ""
echo "🔧 Xomware Conventional Commits — Hook Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Verify we're inside a git repo ──────────────────────────────────────────
if [[ ! -d ".git" ]]; then
  echo "❌  No .git directory found."
  echo "    Run this script from the root of a git repository."
  echo ""
  exit 1
fi

# ── Verify the hook source exists ───────────────────────────────────────────
if [[ ! -f "$HOOK_SOURCE" ]]; then
  echo "❌  Hook source not found at: ${HOOK_SOURCE}"
  echo "    Is this script being run from within xom-claude-workflows?"
  echo ""
  exit 1
fi

# ── Warn if hook already exists ─────────────────────────────────────────────
if [[ -f "$HOOK_DEST" ]]; then
  echo "⚠️   A commit-msg hook already exists at ${HOOK_DEST}"
  printf "    Overwrite? [y/N] "
  read -r CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "    Skipped. No changes made."
    echo ""
    exit 0
  fi
fi

# ── Install ──────────────────────────────────────────────────────────────────
mkdir -p "$HOOKS_DIR"
cp "$HOOK_SOURCE" "$HOOK_DEST"
chmod +x "$HOOK_DEST"

echo "✅  Hook installed at: ${HOOK_DEST}"
echo ""
echo "    Every commit in this repo will now be validated against"
echo "    Xomware's Conventional Commits standard."
echo ""
echo "    Format: type(optional-scope): description (min 10 chars)"
echo ""
echo "    Valid types: feat, fix, refactor, docs, test, chore, perf, ci, build, revert"
echo ""
echo "    To uninstall: rm ${HOOK_DEST}"
echo ""
