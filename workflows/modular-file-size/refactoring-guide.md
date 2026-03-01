# Refactoring Guide: Splitting Large Files

## When to Use This Guide

When a file exceeds **600 lines** (warning) or **800 lines** (error), use this guide to split it into focused, single-responsibility modules.

---

## Step 1: Identify the File's Responsibilities

Before splitting, list everything the file does. A well-structured large file usually has 3–5 distinct concerns:

```
user.service.ts (1,200 lines)
├─ User CRUD operations      (~200 lines)
├─ Password hashing/reset    (~150 lines)
├─ Email verification flow   (~200 lines)
├─ Role/permission checks    (~150 lines)
├─ User search / filtering   (~180 lines)
└─ Audit logging             (~100 lines)
```

Each group is a candidate for its own module.

---

## Step 2: Determine the Split Strategy

### Pattern A: Split by Concern (most common)

```
Before:
  user.service.ts  (1,200 lines)

After:
  user.service.ts          (~100 lines) — re-exports and orchestration
  user-crud.service.ts     (~200 lines)
  user-auth.service.ts     (~200 lines)
  user-email.service.ts    (~200 lines)
  user-permissions.ts      (~150 lines)
  user-search.service.ts   (~180 lines)
  user-audit.service.ts    (~100 lines)
```

### Pattern B: Split by Feature Domain

```
Before:
  controllers/user.controller.ts  (900 lines)

After:
  users/
    user.controller.ts        (~100 lines) — route bindings only
    user-profile.handler.ts   (~150 lines)
    user-settings.handler.ts  (~120 lines)
    user-admin.handler.ts     (~200 lines)
```

### Pattern C: Extract Utilities

When you find helpers, validators, or constants mixed into business logic:

```
Before:
  order.service.ts (750 lines — includes validators, constants, mappers)

After:
  order.service.ts       (~300 lines) — business logic only
  order.validators.ts    (~100 lines)
  order.constants.ts     (~80 lines)
  order.mappers.ts       (~120 lines)
  order.types.ts         (~60 lines)
```

---

## Step 3: Refactor Safely

Follow this order to avoid breaking changes:

### 1. Write tests first (if missing)

```bash
# Ensure existing behaviour is captured
npx jest --coverage src/users/user.service.ts
```

### 2. Create the new files

Create the new smaller files alongside the original:

```bash
touch src/users/user-auth.service.ts
touch src/users/user-email.service.ts
```

### 3. Move code incrementally

Move one logical group at a time. After each move:
- Update imports in the new file
- Export from the new file
- Re-export from the original file (for backward compatibility)

**Example: Backward-compatible re-export**

```typescript
// user.service.ts — while migrating
export { hashPassword, verifyPassword, resetPassword } from './user-auth.service';
// ... existing code ...
```

### 4. Update all consumers

```bash
# Find all imports of the original file
rg "from.*user.service" --type ts
```

Update each import to point to the specific sub-module:

```typescript
// Before
import { hashPassword, getUser, sendVerificationEmail } from './user.service';

// After
import { getUser } from './user-crud.service';
import { hashPassword } from './user-auth.service';
import { sendVerificationEmail } from './user-email.service';
```

### 5. Remove the re-exports once consumers are updated

Once all consumers import from specific modules, clean up the re-exports from the original file.

### 6. Run tests + linter

```bash
npx tsc --noEmit          # type check
npx jest                  # tests
npx eslint src/users/     # lint (including max-file-lines)
bash audit-file-sizes.sh  # confirm all files are under limit
```

---

## Step 4: Update the Index File (if applicable)

If the domain has an `index.ts` barrel file, update it to aggregate from the new modules:

```typescript
// users/index.ts
export * from './user-crud.service';
export * from './user-auth.service';
export * from './user-email.service';
export type { User, CreateUserDto } from './user.types';
```

---

## Anti-Patterns to Avoid

| Anti-pattern | Problem | Fix |
|---|---|---|
| Split into files > 800 lines | Just moved the problem | Split further |
| Circular imports between split files | Tight coupling | Introduce a shared `types.ts` |
| One huge `index.ts` barrel | Hidden blob file | Limit barrel to < 100 lines of re-exports |
| Splitting by file size alone (no SRP) | Random slices | Always split by responsibility |
| Premature splitting (files < 200 lines) | Over-engineering | Only split when needed |

---

## Worked Example: Splitting a 900-Line Controller

### Before: `user.controller.ts` (900 lines)

```typescript
// Handles: CRUD, settings, admin actions, avatar upload
router.get('/users', listUsers);
router.post('/users', createUser);
// ... 50 more routes ...

async function listUsers(req, res) { /* 80 lines */ }
async function createUser(req, res) { /* 120 lines */ }
async function updateSettings(req, res) { /* 100 lines */ }
async function uploadAvatar(req, res) { /* 150 lines */ }
async function adminBanUser(req, res) { /* 80 lines */ }
// ...
```

### After: Feature-split controllers

```
users/
  user.routes.ts             # route definitions only (~60 lines)
  user-crud.controller.ts    # list, create, update, delete (~200 lines)
  user-settings.controller.ts # profile settings (~120 lines)
  user-media.controller.ts   # avatar upload, media (~150 lines)
  user-admin.controller.ts   # admin-only actions (~100 lines)
```

---

## Tooling Reference

| Tool | Command |
|------|---------|
| Audit all large files | `bash workflows/modular-file-size/scripts/audit-file-sizes.sh` |
| Find all imports of a file | `rg "from.*filename" --type ts` |
| Check types after refactor | `npx tsc --noEmit` |
| ESLint check | `npx eslint <dir>` |
| Run tests | `npx jest <dir>` |

---

*Maintained by Xomware Engineering. Questions? Open an issue in xom-claude-workflows.*
