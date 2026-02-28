# Git Worktree Conventions

## Naming Convention

### Directory Naming

Worktree directories live **adjacent to the main repo** (parent directory):

```
~/repos/
├── myproject/              ← main repo (main branch)
├── myproject-auth/         ← worktree for feature/auth
├── myproject-payments/     ← worktree for feature/payments
└── myproject-fix-login/    ← worktree for fix/login-bug
```

**Pattern:** `<repo-name>-<branch-slug>`

Where `<branch-slug>` is:
- The last component of the branch name (after the last `/`)
- Lowercased
- Non-alphanumeric characters replaced with `-`

| Branch | Directory |
|--------|-----------|
| `feature/auth-flow` | `myproject-auth-flow` |
| `fix/login-bug` | `myproject-fix-login-bug` |
| `chore/update-deps` | `myproject-update-deps` |
| `feature/payments` | `myproject-payments` |

---

## Branch Naming

Follow the project's existing branch convention. For Xomware projects:

| Type | Format | Example |
|------|--------|---------|
| Feature | `feature/<slug>` | `feature/instinct-system` |
| Bug fix | `fix/<slug>` | `fix/auth-token-refresh` |
| Chore/maintenance | `chore/<slug>` | `chore/update-node-deps` |
| Hotfix | `hotfix/<slug>` | `hotfix/critical-auth-bypass` |

---

## Lifecycle

### 1. Create
```bash
./workflows/git-worktrees/setup-worktrees.sh feature/auth main
```

### 2. Work
Claude session runs inside the worktree directory.
Each session has full git autonomy — commit, push, etc.

### 3. Push & PR
```bash
git -C ~/repos/myproject-auth push origin feature/auth
gh pr create --repo owner/myproject --head feature/auth --base main
```

### 4. Cleanup (after merge)
```bash
# Remove the worktree directory
git worktree remove ~/repos/myproject-auth

# Clean up any stale refs
git worktree prune

# Delete the remote branch (optional, usually done via GitHub UI)
git push origin --delete feature/auth
```

---

## Parallel Session Assignment

When spawning multiple Claude sessions for parallel work:

| Agent | Worktree | Branch |
|-------|----------|--------|
| `forge-auth` | `myproject-auth` | `feature/auth` |
| `forge-payments` | `myproject-payments` | `feature/payments` |
| `forge-fix-login` | `myproject-fix-login` | `fix/login` |

**Rule:** One agent per worktree. Never share a worktree between agents.

---

## Stale Worktree Detection

```bash
# List all worktrees with their status
git worktree list --porcelain

# Prune worktrees whose directories no longer exist
git worktree prune -v
```

Stale worktrees (directory deleted without `git worktree remove`) are cleaned up by `git worktree prune`.

---

## CI/CD Considerations

- Do **not** run worktree-based workflows inside CI containers (use regular clones there)
- Worktrees are a local development / local agent pattern
- In CI, each job already gets its own clone — no worktrees needed
