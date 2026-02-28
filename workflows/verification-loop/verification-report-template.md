# VERIFICATION REPORT Template

Use this template to document verification results before creating a PR. Copy, fill in, and paste into the PR description.

---

## How to Use

1. Run `npm run verify` (or `make verify`) to execute all 6 phases
2. Copy the template below
3. Fill in the results for each phase
4. Paste into the PR description under a `## Verification Report` section

---

## Template

```markdown
## ✅ VERIFICATION REPORT

**Branch:** `feature/<name>`
**Run Date:** YYYY-MM-DD HH:MM UTC
**Runner:** local / CI (GitHub Actions)
**Commit:** `<sha>`

---

### Phase 1: Lint / Format
- **Status:** ✅ PASS / ❌ FAIL
- **Command:** `npm run lint` / `ruff check . && black --check .`
- **Output:**
  ```
  <paste output here or "No errors">
  ```
- **Warnings (acceptable):** N / List any

---

### Phase 2: Type Check
- **Status:** ✅ PASS / ❌ FAIL
- **Command:** `npx tsc --noEmit` / `mypy src/`
- **Output:**
  ```
  <paste output or "No errors">
  ```
- **Errors fixed:** N/A or describe

---

### Phase 3: Unit Tests
- **Status:** ✅ PASS / ❌ FAIL
- **Command:** `npm test` / `pytest tests/unit/`
- **Results:**
  - Tests passed: X
  - Tests failed: 0
  - Tests skipped: X (with reason)
  - Duration: Xs
- **Output:**
  ```
  <paste test summary>
  ```

---

### Phase 4: Integration Tests
- **Status:** ✅ PASS / ❌ FAIL / ⏭️ SKIPPED (reason)
- **Command:** `npm run test:integration` / `pytest tests/integration/`
- **Results:**
  - Tests passed: X
  - Tests failed: 0
  - Duration: Xs
- **Note:** _(skipped only if approved by team lead)_

---

### Phase 5: Coverage Gate
- **Status:** ✅ PASS / ❌ FAIL
- **Command:** `npm test -- --coverage` / `pytest --cov=src --cov-fail-under=80`
- **Results:**

| Metric | Actual | Threshold | Status |
|--------|--------|-----------|--------|
| Statements | X.X% | 80% | ✅/❌ |
| Branches | X.X% | 75% | ✅/❌ |
| Functions | X.X% | 80% | ✅/❌ |
| Lines | X.X% | 80% | ✅/❌ |

- **New files with coverage:**
  - `src/module/file.ts`: X%
- **Uncovered paths (justified):**
  - None / List with justification

---

### Phase 6: Build Check
- **Status:** ✅ PASS / ❌ FAIL
- **Command:** `npm run build` / `go build ./...`
- **Output:**
  ```
  <paste build output summary>
  ```
- **Build size:** X.XX MB (if applicable)
- **Duration:** Xs

---

### Summary

| Phase | Status | Duration |
|-------|--------|----------|
| 1. Lint/Format | ✅ PASS | Xs |
| 2. Type Check | ✅ PASS | Xs |
| 3. Unit Tests | ✅ PASS | Xs |
| 4. Integration Tests | ✅ PASS | Xs |
| 5. Coverage Gate | ✅ PASS | Xs |
| 6. Build Check | ✅ PASS | Xs |
| **OVERALL** | **✅ ALL PASS** | **Xs** |

**Ready for review:** ✅ Yes / ❌ No — fix phases: [list]
```

---

## Automated Report (CI)

When running via GitHub Actions, the verification report is automatically generated and posted as a PR comment. The format matches the template above.

To trigger a fresh report on an existing PR:
```bash
# Add comment to PR
gh pr comment <PR_NUMBER> --body "/verify"
```

---

## Status Icons Reference

| Icon | Meaning |
|------|---------|
| ✅ | Phase passed |
| ❌ | Phase failed — PR blocked |
| ⚠️ | Phase passed with warnings |
| ⏭️ | Phase skipped (must be justified) |
| 🔄 | Phase running |

---

## Example: Filled Report

```markdown
## ✅ VERIFICATION REPORT

**Branch:** `feature/user-auth`
**Run Date:** 2026-02-28 14:32 UTC
**Runner:** CI (GitHub Actions)
**Commit:** `a1b2c3d`

### Phase 1: Lint / Format
- **Status:** ✅ PASS
- **Command:** `npm run lint`
- **Output:** No errors. 2 warnings (unused var `x` in test file — acceptable)

### Phase 2: Type Check
- **Status:** ✅ PASS
- **Command:** `npx tsc --noEmit`
- **Output:** No errors.

### Phase 3: Unit Tests
- **Status:** ✅ PASS
- **Results:** 87 passed, 0 failed, 2 skipped (platform-specific), 4.2s

### Phase 4: Integration Tests
- **Status:** ✅ PASS
- **Results:** 12 passed, 0 failed, 18.7s

### Phase 5: Coverage Gate
- **Status:** ✅ PASS
| Metric | Actual | Threshold | Status |
|--------|--------|-----------|--------|
| Statements | 84.2% | 80% | ✅ |
| Branches | 76.8% | 75% | ✅ |
| Functions | 88.0% | 80% | ✅ |
| Lines | 84.2% | 80% | ✅ |

### Phase 6: Build Check
- **Status:** ✅ PASS
- **Output:** Build completed in 12.4s, 234KB gzipped

### Summary
| Phase | Status | Duration |
|-------|--------|----------|
| 1. Lint/Format | ✅ PASS | 3s |
| 2. Type Check | ✅ PASS | 8s |
| 3. Unit Tests | ✅ PASS | 4.2s |
| 4. Integration Tests | ✅ PASS | 18.7s |
| 5. Coverage Gate | ✅ PASS | 6.1s |
| 6. Build Check | ✅ PASS | 12.4s |
| **OVERALL** | **✅ ALL PASS** | **52.4s** |

**Ready for review:** ✅ Yes
```
