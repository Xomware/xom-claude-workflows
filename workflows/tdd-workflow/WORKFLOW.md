# TDD Workflow — Test-Driven Development as Default Mode

## Overview

This workflow enforces Test-Driven Development (TDD) as the **default development mode** for all feature implementation, bug fixes, and refactoring tasks. The TDD cycle ensures code is always written in response to a failing test, improving design quality and confidence.

---

## When to Invoke

Invoke this workflow whenever:
- Implementing a new feature or capability
- Fixing a bug (write a regression test first)
- Refactoring existing code
- Adding a new API endpoint or module
- Implementing AI/LLM integrations that need deterministic behavior

**Do NOT skip TDD for:**
- "Quick fixes" — these are the most common source of regressions
- Prototype code that may be promoted to production
- AI output parsing / transformation logic

---

## The TDD Cycle: RED → GREEN → REFACTOR

```
┌─────────────────────────────────────────────────────────┐
│                    TDD CYCLE                            │
│                                                         │
│   RED           GREEN          REFACTOR                 │
│   ────          ─────          ────────                 │
│  Write a   →  Write just   →  Improve code             │
│  failing       enough code    without breaking          │
│  test          to pass        tests                     │
│                                                         │
│  ↑___________________________________|                  │
│          Repeat for next feature                        │
└─────────────────────────────────────────────────────────┘
```

### Phase 1: RED — Write a Failing Test

**Goal:** Define the expected behavior before writing any implementation.

Steps:
1. Understand the requirement or bug report
2. Write the minimal test that captures the requirement
3. Run the test — **confirm it fails** (if it passes, the test is wrong or the feature already exists)
4. Commit the failing test

Rules:
- Test must fail for the right reason (not a syntax error)
- Test must be as simple as possible — test one thing
- Test name must clearly describe the intended behavior
- Do not write any implementation code yet

```bash
# Run tests and confirm failure
npm test -- --testPathPattern="<feature>"
pytest tests/test_<feature>.py -v
vitest run <feature>
```

### Phase 2: GREEN — Write Minimal Implementation

**Goal:** Write the simplest code that makes the test pass.

Steps:
1. Write only the code needed to pass the failing test
2. Do not over-engineer — simplicity is the goal
3. Run tests — **confirm the new test passes**
4. Confirm existing tests still pass (no regressions)
5. Commit the implementation

Rules:
- Resist adding logic not required by a test
- If you find yourself writing code "just in case," stop and write a test first
- Hard-coded values are acceptable at this phase if they make the test pass

```bash
# Run full test suite
npm test
pytest
vitest run
```

### Phase 3: REFACTOR — Improve Without Breaking

**Goal:** Clean up the implementation without changing behavior.

Steps:
1. Identify code smells: duplication, long functions, poor naming
2. Apply refactoring incrementally
3. Run tests after each change — they must stay green
4. Commit refactored code with descriptive message

Refactoring targets:
- Extract repeated logic into shared functions
- Improve naming clarity
- Remove hard-coded values (replace with constants/config)
- Simplify conditionals
- Improve error handling
- Ensure coverage stays ≥ 80%

```bash
# Run tests with coverage after refactoring
npm test -- --coverage
pytest --cov=src --cov-report=term-missing
vitest run --coverage
```

---

## Workflow Steps (Automated)

| Step | Action | Agent | Pass Criteria |
|------|--------|-------|---------------|
| 1 | Parse requirement or issue | tdd-guide | Requirement understood |
| 2 | Generate test skeleton | tdd-guide | Test file created |
| 3 | Run tests (RED) | devops-bot | Test fails as expected |
| 4 | Generate implementation | claude-sonnet | Implementation created |
| 5 | Run tests (GREEN) | devops-bot | All tests pass |
| 6 | Apply refactoring | tdd-guide | Code improved |
| 7 | Run tests + coverage | devops-bot | Tests pass, ≥80% coverage |
| 8 | Create PR | devops-bot | PR opened |

---

## The tdd-guide Subagent

The `tdd-guide` subagent is a specialized Claude agent that:

1. **Reads the requirement** — parses GitHub issues, PRDs, or plain text specs
2. **Generates test cases** — creates comprehensive tests covering happy path, edge cases, and error conditions
3. **Reviews implementation** — checks that implementation matches test intent
4. **Suggests refactorings** — identifies improvement opportunities after GREEN phase
5. **Validates coverage** — ensures 80% minimum threshold is maintained

See [`tdd-guide-agent.md`](./tdd-guide-agent.md) for full agent definition.

---

## Coverage Requirements

| Metric | Minimum Threshold | Target |
|--------|-------------------|--------|
| Statement coverage | 80% | 90% |
| Branch coverage | 75% | 85% |
| Function coverage | 80% | 90% |
| Line coverage | 80% | 90% |

See [`coverage-config-example.md`](./coverage-config-example.md) for configuration examples.

---

## Integration with Feature Implementation Workflow

This workflow integrates with `workflows/feature-implementation/` by replacing the `add-tests` step with the full RED→GREEN→REFACTOR cycle. The `tdd-guide` subagent is invoked during `design-architecture` to define test interfaces before any code is written.

---

## Definition of Done

A task is **done** when:
- [ ] All acceptance criteria have corresponding tests
- [ ] All tests pass (no failures, no skips without justification)
- [ ] Coverage ≥ 80% for new code
- [ ] No regressions in existing tests
- [ ] Refactoring pass completed
- [ ] PR description references which tests verify which requirements

---

## Anti-Patterns to Avoid

| Anti-Pattern | Description | Correct Approach |
|---|---|---|
| Test-last | Writing tests after implementation | Always write tests first |
| Testing implementation | Testing internal method calls rather than behavior | Test inputs/outputs, not internals |
| Giant tests | One test that covers everything | One test per behavior |
| Mocking everything | Over-mocking loses confidence | Mock only external dependencies |
| Skipping RED | Test passes immediately | Verify the test fails first |
| Coverage theater | Writing tests just to hit 80% | Write meaningful tests |

---

## References

- [Kent Beck — Test-Driven Development: By Example](https://www.oreilly.com/library/view/test-driven-development/0321146530/)
- [Martin Fowler on TDD](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Coverage Config Examples](./coverage-config-example.md)
- [Verification Loop Workflow](../verification-loop/WORKFLOW.md)
