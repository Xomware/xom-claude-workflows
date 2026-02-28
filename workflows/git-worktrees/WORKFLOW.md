# Git Worktrees for Parallel Claude Instances

## Problem

When multiple Claude agents work on the same repository simultaneously, they share the same working directory. This causes:
- Merge conflicts from concurrent edits
- Branch switching mid-task clobbering uncommitted changes
- One agent's `git status` polluted by another's work

## Solution: Git Worktrees

`git worktree` lets you check out **multiple branches into separate directories simultaneously** — each with its own working tree, index, and HEAD. Each Claude session gets its own worktree and never conflicts with others.

---

## Core Commands

### Create a worktree for a new feature branch

```bash
# From the main repo directory
git worktree add ../project-feature-a feature/a

# Result:
# - Creates directory ../project-feature-a/
# - Checks out branch feature/a into that directory
# - Main repo stays on its current branch
```

### Create a worktree with a new branch

```bash
git worktree add -b feature/new-thing ../project-new-thing main
# Creates branch feature/new-thing from main, checked out in ../project-new-thing/
```

### List all worktrees

```bash
git worktree list
# Output:
# /Users/dev/project           abc1234 [main]
# /Users/dev/project-feature-a def5678 [feature/a]
# /Users/dev/project-new-thing ghi9012 [feature/new-thing]
```

### Remove a worktree (after merging)

```bash
git worktree remove ../project-feature-a
# Or force-remove if there are untracked files:
git worktree remove --force ../project-feature-a
```

---

## Parallel Claude Workflow

```
Main Repo (main branch)
├── /repos/myproject/           ← Jarvis: oversight, planning
├── /repos/myproject-feature-a/ ← Forge Agent 1: feature/a
├── /repos/myproject-feature-b/ ← Forge Agent 2: feature/b
└── /repos/myproject-bugfix-x/  ← Forge Agent 3: fix/x
```

Each Claude session:
1. Gets its own worktree directory
2. Works on its own branch
3. Pushes independently
4. Creates its own PR

No agent ever touches another agent's working directory.

---

## Step-by-Step Setup

```bash
# 1. From the main repo, create a worktree for each task
git worktree add ../myproject-feature-a -b feature/a main
git worktree add ../myproject-feature-b -b feature/b main

# 2. Spawn Claude sessions, each pointed at their worktree
# (Use openclaw or sessions_spawn with workdir set)

# 3. Each agent works independently in their directory
# cd ../myproject-feature-a && <implement feature a>
# cd ../myproject-feature-b && <implement feature b>

# 4. Each agent pushes and creates a PR
# git -C ../myproject-feature-a push origin feature/a
# gh pr create --repo owner/myproject --head feature/a

# 5. After PRs are merged, clean up worktrees
git worktree remove ../myproject-feature-a
git worktree remove ../myproject-feature-b
git worktree prune  # Clean up stale refs
```

---

## Benefits

| Without Worktrees | With Worktrees |
|-------------------|----------------|
| Agents fight over `git checkout` | Each agent owns its directory |
| `git status` is noisy | Clean status per agent |
| Risk of stash/unstash errors | No stashing needed |
| Sequential work only | True parallel work |
| Complex coordination needed | Zero coordination overhead |

---

## Limitations

- Each worktree uses ~same disk space as a full clone
- Git LFS objects are shared (good: saves space; neutral: no conflicts)
- Cannot check out the same branch in two worktrees simultaneously

---

## See Also

- `setup-worktrees.sh` — Helper script to automate worktree creation + session spawn
- `conventions.md` — Naming conventions and cleanup procedures
- [git-worktree docs](https://git-scm.com/docs/git-worktree)
