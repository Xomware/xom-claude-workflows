# 6-Phase Verification Loop — Pre-PR Quality Gate

## Overview

The 6-Phase Verification Loop is a mandatory pre-PR quality gate. It must pass **completely** before any pull request is opened. It runs automatically in CI (GitHub Actions) and can be run locally using the same commands.

**No PR merges if any phase fails.**

---

## When to Run

- Before creating any pull request
- After every significant code change
- As part of the automated `feature-implementation` and `tdd-workflow` pipelines
- On every push to a feature branch (CI enforced)

---

## The 6 Phases

```
Phase 1: Lint / Format Check
         ↓
Phase 2: Type Check
         ↓
Phase 3: Unit Tests
         ↓
Phase 4: Integration Tests
         ↓
Phase 5: Coverage Gate (≥80%)
         ↓
Phase 6: Build Check
         ↓
       PASS → Create PR
       FAIL → Fix & Restart
```

---

## Phase 1: Lint / Format Check

**Goal:** Ensure code follows style standards and has no obvious errors.

### Commands

```bash
# JavaScript / TypeScript
npx eslint . --ext .js,.jsx,.ts,.tsx
npx prettier --check "src/**/*.{js,jsx,ts,tsx,json,css,md}"

# Python
ruff check .           # linting
black --check .        # formatting
isort --check-only .   # import order

# Go
golangci-lint run
gofmt -l .

# General
npm run lint          # if configured in package.json
```

### Pass Criteria
- Zero ESLint/ruff errors (warnings are acceptable, configurable)
- All files formatted according to Prettier/Black/gofmt
- No unused imports flagged as errors

### Fail Criteria
- Any lint error (not warning)
- Any formatting diff (file not formatted)
- Unused variables in strict mode

### Fix
```bash
# Auto-fix (when safe)
npx eslint . --fix
npx prettier --write "src/**/*"
black .
ruff check . --fix
```

---

## Phase 2: Type Check

**Goal:** Ensure type safety and no type errors.

### Commands

```bash
# TypeScript
npx tsc --noEmit
npx tsc --noEmit --strict  # stricter check

# Python (mypy)
mypy src/ --strict
mypy src/ --ignore-missing-imports

# Go (type checking is built into build)
go vet ./...

# Rust
cargo check
```

### Pass Criteria
- Zero type errors
- Zero `any` types introduced (if strict mode enabled)
- All function signatures have explicit return types (if configured)

### Fail Criteria
- Any TypeScript error (`TS2xxx`)
- Any mypy error
- `go vet` findings

### Fix
- Add missing type annotations
- Fix type mismatches
- Never use `// @ts-ignore` without a documented justification comment

---

## Phase 3: Unit Tests

**Goal:** All unit tests pass with no failures or unexpected skips.

### Commands

```bash
# JavaScript / TypeScript (Jest)
npm test -- --passWithNoTests
npm run test:unit

# JavaScript / TypeScript (Vitest)
npx vitest run

# Python
pytest tests/unit/ -v --tb=short

# Go
go test ./... -run Unit -v

# Run all unit tests
npm test
```

### Pass Criteria
- All tests pass (0 failures)
- 0 unexpected test skips (skips must have `// TODO` or `@pytest.mark.skip(reason=...)`)
- Test run completes within time limit (5 minutes default)

### Fail Criteria
- Any test failure
- Test runner crashes or hangs
- Test suite takes > 10 minutes (investigate performance)

### Output Expected
```
Test Suites: 12 passed, 12 total
Tests:       143 passed, 143 total
Snapshots:   0 total
Time:        8.432s
```

---

## Phase 4: Integration Tests

**Goal:** End-to-end flows work with real dependencies (or realistic mocks).

### Commands

```bash
# JavaScript / TypeScript
npm run test:integration
npm run test:e2e

# Python
pytest tests/integration/ -v --tb=short

# Go
go test ./... -run Integration -v -tags=integration

# With Docker dependencies
docker-compose -f docker-compose.test.yml up -d
npm run test:integration
docker-compose -f docker-compose.test.yml down
```

### Pass Criteria
- All integration test scenarios pass
- Database/API interactions work correctly
- External services respond or are correctly mocked
- No data corruption in test state

### Fail Criteria
- Any integration test failure
- Test environment fails to start
- External dependency unreachable (if not mocked)

### Notes
- Integration tests may be skipped in fast-feedback mode with `--skip-integration` flag
- Always run before merging to `main`
- Use test databases / sandboxed environments only

---

## Phase 5: Coverage Gate (≥80%)

**Goal:** Enforce minimum code coverage across the codebase.

### Commands

```bash
# Jest
npm test -- --coverage --coverageThreshold='{"global":{"lines":80}}'

# Vitest
npx vitest run --coverage

# pytest
pytest --cov=src --cov-report=term-missing --cov-fail-under=80

# Go
go test ./... -coverprofile=coverage.out
go tool cover -func=coverage.out | grep total
```

### Pass Criteria
| Metric | Minimum |
|--------|---------|
| Statement coverage | 80% |
| Branch coverage | 75% |
| Function coverage | 80% |
| Line coverage | 80% |

### Fail Criteria
- Any coverage metric below threshold
- New files added without tests
- Coverage drops more than 2% from baseline

### Handling Failures
1. Run coverage with `--reporter=html` to see exact uncovered lines
2. Write tests for uncovered paths (focus on error conditions and edge cases)
3. If a path truly cannot be tested, add exclusion comment with justification:
   ```javascript
   /* istanbul ignore next -- requires hardware interface */
   ```

---

## Phase 6: Build Check

**Goal:** Ensure the application builds successfully for production.

### Commands

```bash
# Next.js / React
npm run build

# Vite
npx vite build

# Python package
python -m build
pip install -e . --dry-run

# Go
go build ./...

# Docker
docker build -t app:test .

# TypeScript compilation only
npx tsc --noEmit --project tsconfig.build.json
```

### Pass Criteria
- Build completes without errors
- Build artifacts are generated
- No missing dependencies in production build
- Bundle size within acceptable limits (if configured)

### Fail Criteria
- Build exits with non-zero code
- Missing environment variables required at build time
- Circular dependency errors
- Bundle size exceeds limit

---

## Running All 6 Phases Locally

```bash
# Quick run script (add to package.json or Makefile)
npm run verify

# Equivalent to:
npm run lint && \
npx tsc --noEmit && \
npm test && \
npm run test:integration && \
npm test -- --coverage && \
npm run build
```

### `package.json` scripts

```json
{
  "scripts": {
    "lint": "eslint . && prettier --check 'src/**/*'",
    "typecheck": "tsc --noEmit",
    "test": "jest",
    "test:integration": "jest --config jest.integration.config.js",
    "test:coverage": "jest --coverage",
    "build": "vite build",
    "verify": "npm run lint && npm run typecheck && npm run test && npm run test:integration && npm run test:coverage && npm run build"
  }
}
```

### `Makefile` (Python / Go)

```makefile
.PHONY: verify lint typecheck test test-integration coverage build

verify: lint typecheck test test-integration coverage build
	@echo "✅ All 6 phases passed"

lint:
	ruff check . && black --check . && isort --check-only .

typecheck:
	mypy src/ --strict

test:
	pytest tests/unit/ -v

test-integration:
	pytest tests/integration/ -v

coverage:
	pytest --cov=src --cov-fail-under=80

build:
	python -m build
```

---

## Verification Report

After running all phases, generate the report using the template:

See [`verification-report-template.md`](./verification-report-template.md)

---

## Error Decision Tree

```
Phase fails?
    ↓
Is it a lint/format issue?
  → YES: Auto-fix with eslint --fix / black / ruff --fix, re-run Phase 1
  ↓ NO
Is it a type error?
  → YES: Fix type annotation, re-run Phase 2
  ↓ NO
Is it a test failure?
  → YES: Fix the bug (or the test if spec changed), re-run from Phase 3
  ↓ NO
Is it a coverage gap?
  → YES: Write missing tests, re-run from Phase 5
  ↓ NO
Is it a build error?
  → YES: Fix build config, re-run Phase 6 only
```

---

## CI Integration

See [`.github/workflows/verification-gate.yml`](../../.github/workflows/verification-gate.yml) for the GitHub Actions configuration that runs all 6 phases automatically on every PR.
