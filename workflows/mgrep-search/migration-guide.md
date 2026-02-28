# Migration Guide: grep/ripgrep → mgrep

This guide shows how to convert common grep and ripgrep patterns to mgrep equivalents.

---

## Direct Equivalents

| grep / ripgrep | mgrep equivalent | Notes |
|----------------|------------------|-------|
| `grep -r "pattern" .` | `mgrep "pattern" .` | Same behavior |
| `rg "pattern"` | `mgrep "pattern"` | Same behavior |
| `grep -rn "pattern" .` | `mgrep "pattern" .` | `-n` is default in mgrep |
| `grep -rl "pattern" .` | `mgrep -l "pattern" .` | Files only |
| `grep -rc "pattern" .` | `mgrep -c "pattern" .` | Count per file |
| `grep -ri "pattern" .` | `mgrep -i "pattern" .` | Case-insensitive |
| `grep -rw "word" .` | `mgrep -x "word" .` | Whole-word match |

---

## File Type Filtering

```bash
# ripgrep
rg "pattern" --type py
rg "pattern" -t js

# mgrep equivalent
mgrep -t py "pattern" .
mgrep -t js "pattern" .
```

---

## Context Lines

```bash
# grep: show 3 lines after match
grep -A 3 "def foo" src/

# ripgrep: show 3 lines after
rg -A 3 "def foo" src/

# mgrep: show 2 lines after (use sparingly — adds tokens)
mgrep -A 3 "def foo" src/

# BETTER mgrep pattern: get file+line, then Read
mgrep "def foo" src/
# → src/utils.py:42
# Then: Read src/utils.py lines 42-55
```

**Recommendation:** Avoid `-A`/`-B` with mgrep. Get the line number, then use `Read` for context. This is more token-efficient.

---

## Exclude Patterns

```bash
# grep: exclude directory
grep -r "pattern" . --exclude-dir=node_modules

# ripgrep: respects .gitignore automatically; add --glob
rg "pattern" --glob '!node_modules'

# mgrep: respects .gitignore by default
mgrep "pattern" .
# To add explicit exclusion:
mgrep "pattern" --ignore node_modules .
```

---

## Multiple Patterns

```bash
# grep: OR pattern
grep -rE "foo|bar" .

# ripgrep
rg "foo|bar" .

# mgrep: regex OR
mgrep "foo|bar" .

# mgrep: run two searches (usually cleaner for agents)
mgrep "foo" .
mgrep "bar" .
```

---

## Anchored Patterns

```bash
# grep: match at start of line
grep "^def " src/

# mgrep: same
mgrep "^def " src/

# grep: match at end of line
grep "error$" src/

# mgrep: same
mgrep "error$" src/
```

---

## Common Agent Refactors

### Before (ripgrep + context)
```bash
rg -A 5 "def authenticate" src/
# Returns 6 lines per match × N matches = many tokens
```

### After (mgrep + targeted Read)
```bash
mgrep "def authenticate" src/
# Returns: src/auth.py:45  (3 tokens)
# Then read lines 45-60 of src/auth.py with Read tool
```

---

### Before (grep for existence check)
```bash
grep -rl "JWT_SECRET" . | head -5
# Returns full paths
```

### After
```bash
mgrep -l "JWT_SECRET" .
# Same result, no change needed — already minimal
```

---

### Before (find all TODOs with context)
```bash
rg -B 1 -A 1 "TODO" .
# Returns 3 lines per match
```

### After
```bash
mgrep "TODO" .
# Returns file:line per match — agent can Read specific ones if needed
```

---

## Not a Good Fit for mgrep

Some tasks still belong to other tools:

| Task | Better Tool |
|------|-------------|
| Multiline pattern matching | `rg --multiline` |
| Search git history | `git log -S "pattern"` |
| Binary file content | `rg --binary` |
| Complex lookahead/lookbehind regex | `rg` or `perl -ne` |
| Structural code search | `ast-grep`, `semgrep` |
