# Coverage Configuration Examples

Configure your test runner to enforce the 80% minimum coverage threshold. These configurations will **fail the test run** if coverage drops below the threshold, blocking PRs in CI.

---

## Jest (JavaScript / TypeScript)

### `jest.config.js` or `jest.config.ts`

```javascript
/** @type {import('jest').Config} */
module.exports = {
  // Test file discovery
  testMatch: [
    '**/__tests__/**/*.[jt]s?(x)',
    '**/?(*.)+(spec|test).[jt]s?(x)',
  ],
  
  // Coverage settings
  collectCoverage: true,
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/index.ts',        // re-export files
    '!src/**/*.stories.tsx',   // Storybook files
    '!src/**/__mocks__/**',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  
  // ⚠️ This enforces the 80% threshold — build fails if below
  coverageThreshold: {
    global: {
      statements: 80,
      branches: 75,
      functions: 80,
      lines: 80,
    },
    // Optional: per-file thresholds for critical modules
    './src/auth/': {
      statements: 90,
      branches: 85,
      functions: 90,
      lines: 90,
    },
  },
  
  // TypeScript support
  transform: {
    '^.+\\.(ts|tsx)$': 'ts-jest',
  },
  
  // Module resolution
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
};
```

### `package.json` scripts

```json
{
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage",
    "test:watch": "jest --watch",
    "test:ci": "jest --coverage --ci --runInBand"
  }
}
```

### Running

```bash
# Run with coverage (fails if below threshold)
npm run test:coverage

# CI mode (no interactive prompts)
npm run test:ci
```

---

## Vitest (Vite / Vue / React)

### `vitest.config.ts`

```typescript
import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    // Test environment
    environment: 'node', // or 'jsdom' for browser-like
    globals: true,
    
    // Coverage settings
    coverage: {
      provider: 'v8', // or 'istanbul'
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage',
      
      // Files to include in coverage
      include: ['src/**/*.{ts,tsx,js,jsx}'],
      exclude: [
        'src/**/*.d.ts',
        'src/**/*.stories.tsx',
        'src/**/__mocks__/**',
        'src/**/index.ts',
      ],
      
      // ⚠️ Enforces 80% threshold
      thresholds: {
        statements: 80,
        branches: 75,
        functions: 80,
        lines: 80,
      },
    },
    
    // Path aliases
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

### `package.json` scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:watch": "vitest watch",
    "test:ci": "vitest run --coverage --reporter=verbose"
  }
}
```

### Running

```bash
# Run with coverage
npm run test:coverage

# Watch mode (development)
npm run test:watch
```

---

## pytest (Python)

### `pyproject.toml`

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--tb=short",
    "-v",
]

[tool.coverage.run]
source = ["src"]
omit = [
    "*/migrations/*",
    "*/tests/*",
    "*/__init__.py",
    "*/conftest.py",
]
branch = true  # Measure branch coverage

[tool.coverage.report]
# ⚠️ Fail if coverage drops below 80%
fail_under = 80
show_missing = true
skip_covered = false
precision = 2

[tool.coverage.html]
directory = "coverage_html"
```

### `setup.cfg` (alternative)

```ini
[tool:pytest]
testpaths = tests
addopts = --cov=src --cov-report=term-missing --cov-fail-under=80

[coverage:run]
source = src
branch = True

[coverage:report]
fail_under = 80
show_missing = True
```

### Running

```bash
# Run with coverage (fails if below 80%)
pytest --cov=src --cov-report=term-missing --cov-fail-under=80

# Generate HTML report
pytest --cov=src --cov-report=html --cov-fail-under=80

# Using pyproject.toml config
pytest
coverage run -m pytest
coverage report
```

### Installing dependencies

```bash
pip install pytest pytest-cov coverage
# or
uv add --dev pytest pytest-cov coverage
```

---

## Go (testing + go test -cover)

### `Makefile`

```makefile
COVERAGE_THRESHOLD := 80

.PHONY: test test-coverage

test:
	go test ./...

test-coverage:
	go test ./... -coverprofile=coverage.out -covermode=atomic
	go tool cover -html=coverage.out -o coverage.html
	@COVERAGE=$$(go tool cover -func=coverage.out | grep total | awk '{print $$3}' | tr -d '%'); \
	echo "Total coverage: $${COVERAGE}%"; \
	if [ $$(echo "$${COVERAGE} < $(COVERAGE_THRESHOLD)" | bc -l) -eq 1 ]; then \
		echo "❌ Coverage $${COVERAGE}% is below threshold $(COVERAGE_THRESHOLD)%"; \
		exit 1; \
	else \
		echo "✅ Coverage $${COVERAGE}% meets threshold $(COVERAGE_THRESHOLD)%"; \
	fi
```

### Running

```bash
make test-coverage
```

---

## GitHub Actions Integration

Add to your CI workflow to enforce coverage on every PR:

```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: npm run test:ci  # or pytest / vitest run --coverage

- name: Upload coverage to Codecov (optional)
  uses: codecov/codecov-action@v3
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    fail_ci_if_error: true
    threshold: 80
```

---

## Coverage Report Interpretation

```
------------------------|---------|----------|---------|---------|
File                    | % Stmts | % Branch | % Funcs | % Lines |
------------------------|---------|----------|---------|---------|
 src/                  |   85.20 |    78.50 |   88.00 |   85.20 |
  auth/user.ts         |   92.30 |    85.00 |   95.00 |   92.30 |
  email/mailer.ts      |   78.10 |    72.00 |   80.00 |   78.10 | ← AT THRESHOLD
  utils/parser.ts      |   61.40 |    55.00 |   65.00 |   61.40 | ← BELOW - FIX
------------------------|---------|----------|---------|---------|
```

**Action required** when a file is below threshold:
1. Identify uncovered lines using `--cov-report=term-missing` or HTML report
2. Write tests targeting the uncovered paths (not coverage theater)
3. Focus on error conditions and edge cases — these are usually the gaps

---

## What NOT to Do

```javascript
// ❌ Don't exclude entire modules just to hit the threshold
collectCoverageFrom: [
  'src/**/*.ts',
  '!src/auth/**',  // Don't do this to hide low coverage
],

// ❌ Don't write tests that only exist to hit coverage numbers
it('hits the branch', () => {
  const fn = require('./module');
  fn(null);  // No assertion — this is coverage theater
});
```

**Coverage is a signal, not a target.** If you can't test a path, that's a design smell — consider making the code more testable.
