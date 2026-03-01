# Modular File Size Standards — Xomware Standard

## Overview

Xomware enforces **strict file size limits** to keep the codebase modular, readable, and maintainable. Large files are a code smell that typically signals a violation of the Single Responsibility Principle.

---

## File Size Limits

| Threshold | Level | Action Required |
|-----------|-------|-----------------|
| < 300 lines | ✅ Ideal | No action |
| 300–599 lines | 🟡 Acceptable | Consider splitting |
| 600–799 lines | ⚠️ Warning | Plan to split |
| ≥ 800 lines | ❌ Error | Must split before merging |

These limits apply to all source files (`.ts`, `.tsx`, `.js`, `.jsx`, `.py`) unless explicitly excluded.

---

## Why This Matters

- **Readability**: Files under 300 lines are fully readable in one screen session
- **Reviewability**: PRs are faster to review when changes are in small, focused files
- **Testability**: Small modules are easier to unit test in isolation
- **Git blame**: Precise blame history when concerns are separated
- **AI assistance**: LLMs provide better help on focused, single-purpose files

---

## Feature-Domain Organization

Instead of grouping by technical layer, Xomware repos should group by **feature domain**:

### ❌ Layer-based (avoid)

```
src/
  controllers/
    user.controller.ts      # 900 lines
    order.controller.ts     # 650 lines
  services/
    user.service.ts         # 1200 lines
  models/
    user.model.ts           # 400 lines
```

### ✅ Feature-domain (preferred)

```
src/
  users/
    user.controller.ts      # 120 lines — HTTP layer only
    user.service.ts         # 150 lines — business logic
    user.repository.ts      # 100 lines — DB layer
    user.types.ts           # 60 lines  — interfaces / DTOs
    user.validators.ts      # 80 lines  — input validation
    user.test.ts            # 200 lines — tests colocated
  orders/
    order.controller.ts
    order.service.ts
    order.repository.ts
    order.types.ts
```

---

## What Counts Toward Line Count

- All non-blank, non-comment lines
- Import statements
- Type definitions
- Inline tests in the same file

**Not counted by the ESLint rule** (comment lines are excluded from LOC for linting purposes, though the audit script counts all lines).

---

## ESLint Enforcement

Add `eslint-rule/max-file-lines.js` to your ESLint config:

```js
// eslint.config.js
const maxFileLines = require('<xom-claude-workflows>/workflows/modular-file-size/eslint-rule/max-file-lines');

module.exports = {
  plugins: {
    xomware: { rules: { 'max-file-lines': maxFileLines } },
  },
  rules: {
    'xomware/max-file-lines': ['error', { warn: 600, error: 800 }],
  },
};
```

---

## Running the Audit Script

```bash
# Audit the current repo
bash <xom-claude-workflows>/workflows/modular-file-size/scripts/audit-file-sizes.sh

# Audit a specific directory
bash <xom-claude-workflows>/workflows/modular-file-size/scripts/audit-file-sizes.sh ./src

# Set custom threshold
MAX_LINES=600 bash <xom-claude-workflows>/workflows/modular-file-size/scripts/audit-file-sizes.sh
```

---

## Exclusions

The following are excluded from file size checks by default:

- `node_modules/`
- `dist/`, `build/`, `.next/`
- `*.min.js`, `*.bundle.js`
- Migration files (`**/migrations/*.ts`)
- Generated files (marked with `// @generated` or `// AUTO-GENERATED`)
- Test fixtures (`**/__fixtures__/**`)
- `vendor/`

---

## Refactoring Large Files

See `refactoring-guide.md` for a step-by-step guide on splitting large files.

---

*Maintained by Xomware Engineering. Questions? Open an issue in xom-claude-workflows.*
