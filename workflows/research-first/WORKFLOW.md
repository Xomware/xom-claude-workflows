# Research-First Development Discipline

## Overview

Before writing a single line of new code, you must verify that the problem hasn't already been solved. This discipline prevents reinventing wheels, reduces maintenance burden, and forces deliberate decisions about when to build vs adopt.

**Rule:** No new dependency, library, or significant feature may be implemented without completing the research checklist first.

---

## The Five-Step Research Protocol

### Step 1: Search GitHub for Existing Solutions

Search for what others have built. Most problems in software are not novel.

```bash
# Search across all public repos
gh search repos "<problem keywords>" --language <lang> --sort stars

# Search issues/PRs for approaches
gh search issues "<problem>" --repo <relevant-org>/<repo>
```

**What you're looking for:**
- Active repos (commits within 6 months)
- Repos with >100 stars (community validation)
- MIT/Apache/BSD licensed (compatible with your project)
- Code quality you'd be proud to adopt

**Time box:** 15 minutes. If nothing emerges, move to Step 2.

---

### Step 2: Check npm / PyPI / pkg ecosystem

Language-specific package registries have vast catalogs. Check there before building.

```bash
# npm (Node.js)
npm search <keywords>
npx npm-check-updates  # check for existing deps that might already cover this

# PyPI (Python)
pip search <keywords>       # or use https://pypi.org/search
pip show <package-name>     # check an existing package's capabilities

# Go
pkg.go.dev (web) or: go list -m all | grep <keyword>

# Rust
cargo search <keywords>
```

**Evaluate each candidate on:**
- Weekly downloads (proxy for adoption)
- Last publish date (is it maintained?)
- Open issue count vs close rate
- Dependency footprint (avoid adding 50 transitive deps for a 20-line utility)

**Time box:** 20 minutes.

---

### Step 3: Check Web / Official Docs

Sometimes the answer is already in the platform or framework you're using.

- Read the official docs for your framework/platform — the feature may exist natively
- Check the changelog for recent versions — it may have been added
- Search Stack Overflow for the exact problem
- Check the framework's GitHub issues for workarounds or upcoming features

```bash
# Quick web searches to try
# "<framework> native support for <feature>"
# "<problem> without library"
# "<problem> standard library"
```

**Time box:** 15 minutes.

---

### Step 4: Evaluate — Fork vs Build vs Buy

After research, you have three paths:

| Option | When to Choose | Risk |
|--------|---------------|------|
| **Adopt as-is** | Package solves the problem, actively maintained, compatible license | Low: adds dependency |
| **Fork and customize** | Package is 80% right, abandoned or slow to accept PRs | Medium: maintain fork |
| **Build custom** | No suitable solution exists, requirements are highly specific | High: full ownership |
| **Buy/SaaS** | Problem is not core to your product, operational cost is justified | Medium: vendor lock-in |

**Default:** Adopt > Fork > Build. You must have explicit reasons to build.

---

### Step 5: Document the Decision

Create a brief decision record before starting implementation:

```markdown
## Decision: <What you decided>

**Date:** YYYY-MM-DD
**Author:** @handle

### Problem
<One paragraph: what problem are we solving?>

### Options Considered
- **Option A (adopted):** <package/approach>
  - Pros: ...
  - Cons: ...
- **Option B (rejected):** <alternative>
  - Reason for rejection: ...
- **Option C (rejected):** build custom
  - Reason for rejection: ...

### Decision
<What we chose and why.>

### Risks
<What could go wrong with this decision and how we'd handle it.>
```

Store this in `docs/decisions/` or as a GitHub issue comment on the feature issue.

---

## When to Skip (Narrow Exceptions)

You may skip the research phase if:
1. The feature is <50 lines of highly domain-specific logic with no plausible generic equivalent
2. Security or compliance prevents using third-party code in this area
3. A previous research decision document already covers this exact problem

Document your reason for skipping.

---

## Anti-Patterns This Prevents

- ❌ "I'll just write a quick parser" (parsers are never quick)
- ❌ "All the libraries are too heavy, I'll build my own" (your custom version will be heavier and worse)
- ❌ "I know exactly how to do this" (you may, but someone may have done it better)
- ❌ 3-week builds that could have been a 3-line import

---

## Files in This Workflow

```
workflows/research-first/
├── WORKFLOW.md              ← This file
├── research-checklist.md   ← Quick checklist to run before implementation
└── search-commands.md      ← Curated search commands for all ecosystems
```
