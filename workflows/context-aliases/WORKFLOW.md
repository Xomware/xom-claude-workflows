# Context Aliases Workflow

## Overview

Context aliases inject focused system prompts into Claude sessions, replacing a bloated "do everything" context with a lean, role-specific one. Each alias optimizes Claude's behavior for a specific type of work, reducing noise and improving output quality.

## Why Context Aliases?

**Problem:** A single catch-all system prompt forces Claude to context-switch constantly. It wastes tokens, produces vague answers, and dilutes role-specific expertise.

**Solution:** Four purpose-built aliases — each with a tight, role-appropriate system prompt. Keep your base `~/.claude/` context minimal (identity + memory only). Load role context on demand.

---

## The Four Aliases

### `claude-dev` — Implementation Mode
**When:** Writing code, building features, adding tests, debugging

System prompt focuses on:
- Concrete implementation over theory
- Type safety and compile-time guarantees
- Test coverage for all new code
- Prefer explicit over clever

```bash
claude-dev "Add OAuth2 to the auth module"
claude-dev "Fix the race condition in the job queue"
```

---

### `claude-review` — Code Review Mode
**When:** Reviewing PRs, auditing security, evaluating performance

System prompt focuses on:
- Correctness first, elegance second
- Security vulnerabilities and attack surfaces
- Performance bottlenecks and resource usage
- Standards compliance and best practices

```bash
claude-review "Review PR #42 for security issues"
claude-review "Audit our SQL query builder for injection risks"
```

---

### `claude-research` — Analysis Mode
**When:** Evaluating libraries, comparing approaches, writing technical docs

System prompt focuses on:
- Comprehensive landscape analysis
- Explicit tradeoff documentation
- Multiple alternatives, not just one answer
- Source everything (no unsupported assertions)

```bash
claude-research "What's the best job queue for Node.js at 10k jobs/day?"
claude-research "Compare temporal.io vs conductor for orchestration"
```

---

### `claude-infra` — Infrastructure Mode
**When:** Deploying, configuring, writing IaC, incident response

System prompt focuses on:
- Safety and blast radius minimization
- Cost implications of every change
- Explicit rollback plans
- Least-privilege access

```bash
claude-infra "Write Terraform for a new RDS instance with failover"
claude-infra "How do we scale the k8s cluster without downtime?"
```

---

## Installation

```bash
# Add to ~/.zshrc or ~/.bashrc:
source /path/to/xom-claude-workflows/workflows/context-aliases/aliases.sh

# Or install context files globally:
mkdir -p ~/.claude/contexts
cp workflows/context-aliases/contexts/* ~/.claude/contexts/
```

See `aliases.sh` for the full alias definitions.

---

## Design Principles

1. **Lean base context** — Your `~/.claude/` should only define who you are and load memory. Role behavior comes from aliases.
2. **One alias per session** — Don't chain aliases. If a task crosses roles, pick the primary mode.
3. **Aliases are starting points** — Add inline instructions for task-specific nuance: `claude-dev "Build X — also consider Y"`
4. **Iterate your contexts** — Edit `~/.claude/contexts/*.md` as you learn what works. These are living documents.

---

## File Structure

```
workflows/context-aliases/
├── WORKFLOW.md          ← This file
├── aliases.sh           ← Shell alias definitions
└── contexts/
    ├── dev.md           ← Developer context
    ├── review.md        ← Code reviewer context
    ├── research.md      ← Research/analysis context
    └── infra.md         ← Infrastructure context
```
