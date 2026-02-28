#!/usr/bin/env bash
# setup-worktrees.sh — Create a git worktree and optionally start a Claude session
#
# Usage:
#   ./setup-worktrees.sh <branch-name> [base-branch]
#
# Examples:
#   ./setup-worktrees.sh feature/auth main
#   ./setup-worktrees.sh fix/login-bug main
#   ./setup-worktrees.sh feature/payments  # defaults to main

set -euo pipefail

# ─── Arguments ───────────────────────────────────────────────────────────────

BRANCH="${1:-}"
BASE="${2:-main}"

if [[ -z "$BRANCH" ]]; then
  echo "Usage: $0 <branch-name> [base-branch]"
  echo "Example: $0 feature/auth main"
  exit 1
fi

# ─── Derive directory name ────────────────────────────────────────────────────

REPO_DIR="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_DIR")"

# Convert branch name to directory-safe slug
# feature/auth-flow → auth-flow
SLUG="${BRANCH##*/}"            # strip prefix before last /
SLUG="${SLUG//[^a-zA-Z0-9-]/-}" # replace non-alphanum with dash
SLUG="${SLUG,,}"                 # lowercase

WORKTREE_DIR="$(dirname "$REPO_DIR")/${REPO_NAME}-${SLUG}"

# ─── Sanity checks ────────────────────────────────────────────────────────────

if [[ -d "$WORKTREE_DIR" ]]; then
  echo "⚠️  Worktree directory already exists: $WORKTREE_DIR"
  echo "Run: git worktree list"
  exit 1
fi

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "📁 Branch '$BRANCH' exists — checking out into worktree"
  git worktree add "$WORKTREE_DIR" "$BRANCH"
else
  echo "🌿 Creating new branch '$BRANCH' from '$BASE'"
  git worktree add -b "$BRANCH" "$WORKTREE_DIR" "$BASE"
fi

echo ""
echo "✅ Worktree created:"
echo "   Directory: $WORKTREE_DIR"
echo "   Branch:    $BRANCH"
echo ""
echo "📋 Next steps:"
echo "   cd $WORKTREE_DIR"
echo "   # Start your Claude session here"
echo ""
echo "🧹 When done:"
echo "   git worktree remove $WORKTREE_DIR"
echo "   git worktree prune"

# ─── List current worktrees ──────────────────────────────────────────────────

echo ""
echo "📍 All current worktrees:"
git worktree list
