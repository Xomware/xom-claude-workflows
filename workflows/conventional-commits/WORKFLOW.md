# Conventional Commits Enforcement — Xomware Standard

## Overview

All Xomware repositories must use **Conventional Commits** format for every commit message. This ensures:

- Automated changelog generation
- Clear and searchable history
- Consistent communication across all repos
- Compatibility with semantic versioning automation

---

## Commit Message Format

```
type(optional-scope): description

[optional body]

[optional footer(s)]
```

### Rules

| Rule | Requirement |
|------|-------------|
| `type` | Required. Must be one of the allowed types (see below) |
| `scope` | Optional. Lowercase, kebab-case noun describing the area |
| `description` | Required. Imperative present tense. Minimum 10 characters. No period at the end. |
| `body` | Optional. Explain the motivation / context. Wrap at 72 chars. |
| `footer` | Optional. Use for breaking changes (`BREAKING CHANGE:`) or issue refs (`Closes #123`) |

---

## Allowed Types

| Type | When to use |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `docs` | Documentation only changes |
| `test` | Adding or updating tests |
| `chore` | Build process, tooling, or dependency updates |
| `perf` | A code change that improves performance |
| `ci` | Changes to CI/CD configuration files and scripts |
| `build` | Changes that affect the build system |
| `revert` | Reverts a previous commit |

---

## Examples

### ✅ Valid Commit Messages

```
feat(auth): add OAuth2 login with Google
fix(api): handle null response from payment provider
refactor(user-service): extract email validation to helper
docs(readme): update local development setup steps
test(orders): add unit tests for discount calculation
chore(deps): upgrade express to v4.18.2
perf(db): add index on orders.created_at column
ci(github-actions): add caching for node_modules
build(webpack): migrate to esbuild bundler
revert: revert "feat(auth): add OAuth2 login"
```

### ❌ Invalid Commit Messages

```
# Too short description
fix(api): fix

# Missing type
update readme

# Wrong type
update(auth): add login page

# Capitalized description
feat(auth): Add login page

# Ends with period
fix(db): correct migration path.
```

---

## Setup

### Install the commit-msg hook

```bash
# From the root of any Xomware repository:
bash <path-to-this-repo>/workflows/conventional-commits/setup.sh
```

Or directly:

```bash
cp workflows/conventional-commits/hooks/commit-msg .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
```

### Use commitlint (optional, for CI)

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
cp workflows/conventional-commits/commitlint.config.js .
```

Then add to your CI:

```yaml
- name: Lint commit messages
  run: npx commitlint --from HEAD~1 --to HEAD
```

---

## Enforcement in CI

Add this to your GitHub Actions workflow:

```yaml
- name: Validate commit messages
  run: |
    COMMIT_MSG=$(git log -1 --pretty=%B)
    echo "$COMMIT_MSG" | bash .git/hooks/commit-msg /dev/stdin
```

---

## Breaking Changes

Breaking changes must be noted in the footer with `BREAKING CHANGE:`:

```
feat(api): change user endpoint response shape

BREAKING CHANGE: `user.fullName` is now split into `user.firstName` and `user.lastName`.
Migrate consumers before deploying.
```

You may also use the `!` shorthand:

```
feat(api)!: rename user endpoint fields
```

---

## Tooling Reference

- Commitlint: https://commitlint.js.org/
- Conventional Commits spec: https://www.conventionalcommits.org/
- Git hooks documentation: https://git-scm.com/docs/githooks

---

*Maintained by Xomware Engineering. Questions? Open an issue in xom-claude-workflows.*
