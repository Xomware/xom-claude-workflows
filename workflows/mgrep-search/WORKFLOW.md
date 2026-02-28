# mgrep — Token-Efficient Codebase Search

## Why mgrep Over grep/ripgrep?

Standard `grep` and `ripgrep` return full lines of context, often including indentation, comments, and boilerplate that an LLM agent doesn't need. **mgrep** is a minimal-output search tool designed for token efficiency in AI workflows.

**Measured improvement: ~50% token reduction** on typical codebases.

### Example Comparison

```bash
# ripgrep output (verbose, ~80 tokens)
$ rg "def authenticate" src/
src/auth/jwt.py:45:def authenticate(token: str, secret: str) -> Optional[User]:
src/auth/oauth.py:12:def authenticate(code: str, provider: str) -> Optional[User]:
src/tests/test_auth.py:88:    def authenticate(self, *args):

# mgrep output (concise, ~30 tokens)
$ mgrep "def authenticate" src/
auth/jwt.py:45
auth/oauth.py:12
tests/test_auth.py:88
```

The agent gets the same information (file + line number) to make a `Read` call, but uses ~60% fewer tokens.

---

## Installation

```bash
# macOS (Homebrew)
brew install mgrep

# From source (Go)
go install github.com/xomware/mgrep@latest

# Via npm (Node wrapper)
npm install -g @xomware/mgrep

# Verify
mgrep --version
```

---

## Core Flags

| Flag | Description | Example |
|------|-------------|---------|
| `-n` | Show line numbers (default on) | `mgrep -n "pattern" .` |
| `-r` / `--recursive` | Search directories recursively (default) | `mgrep -r "fn main" src/` |
| `-l` / `--files` | List matching files only (no line numbers) | `mgrep -l "TODO" .` |
| `-c` / `--count` | Show match count per file | `mgrep -c "import" .` |
| `-i` / `--ignore-case` | Case-insensitive search | `mgrep -i "error" .` |
| `-x` / `--exact` | Whole-word match | `mgrep -x "auth" .` |
| `-t` / `--type` | Filter by file type | `mgrep -t py "class" .` |
| `--no-filename` | Suppress filename in output | `mgrep --no-filename "x" .` |
| `-A <n>` | Show N lines after match | `mgrep -A 2 "def foo" .` |
| `-B <n>` | Show N lines before match | `mgrep -B 1 "def foo" .` |

---

## When to Use mgrep vs Other Tools

| Use Case | Tool | Reason |
|----------|------|--------|
| Find a function/class definition | **mgrep** | Need file+line, not content |
| Check if a pattern exists anywhere | **mgrep -l** | Files-only output, minimal tokens |
| Count occurrences | **mgrep -c** | Single number per file |
| Read the matched code | **Read** (after mgrep) | Use file+line from mgrep |
| Complex regex / multiline | ripgrep | mgrep doesn't support multiline |
| Binary file search | ripgrep | mgrep is text-only |
| Git history search | `git log -S` | Not a file search |

---

## Workflow: Search → Read

The canonical pattern for agents:

```bash
# Step 1: Find where the function is (cheap, ~5 tokens output)
mgrep "def process_payment" src/

# Output: src/billing/processor.py:142

# Step 2: Read only that file at that line (targeted)
# Read file: src/billing/processor.py, lines 142-180
```

This two-step pattern is significantly more token-efficient than `grep -A 20` or reading entire files speculatively.

---

## See Also

- `search-patterns.md` — Common patterns for function defs, imports, TODOs
- `migration-guide.md` — Converting existing grep/ripgrep commands to mgrep
