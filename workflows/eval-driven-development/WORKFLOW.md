# Eval-Driven Development (EDD) — AI Workflow Quality Methodology

## Overview

Eval-Driven Development (EDD) is a methodology for building reliable AI-powered workflows and LLM integrations. It mirrors Test-Driven Development but is designed for the probabilistic, non-deterministic nature of AI outputs.

**Core principle:** Define how you will measure success *before* you write any code or prompts. If you can't measure it, you can't improve it.

---

## The EDD Problem Statement

Traditional software testing has deterministic expectations:
```
input → function → exact output
```

AI workflows are probabilistic:
```
input → LLM → one of many valid outputs (or invalid ones)
```

EDD solves this by:
1. Defining **evals** (evaluation criteria) before implementation
2. Using **pass@k** metrics to measure quality statistically
3. Tracking **regression** when prompts or models change
4. Setting **acceptance thresholds** per capability

---

## EDD Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    EDD LIFECYCLE                            │
│                                                             │
│  1. DEFINE        2. BASELINE       3. IMPLEMENT            │
│  ────────         ────────          ─────────               │
│  Write evals  →  Run against   →  Write prompt/             │
│  before code     stub/random       code to pass             │
│                  to get 0%         evals                    │
│       ↓                                  ↓                  │
│  4. MEASURE       5. ITERATE        6. GUARD                │
│  ────────         ─────────         ──────                  │
│  Run evals    →  Improve until → Lock in CI;                │
│  record          threshold met   alert on drop              │
│  pass@k                                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: DEFINE — Write Evals Before Code

**Goal:** Specify what success looks like before writing any prompt or AI logic.

An eval defines:
- **Capability** — what the AI should do
- **Input** — what it receives
- **Expected output** — what a correct response looks like
- **Success criteria** — how to judge correctness
- **Acceptance threshold** — what pass rate is acceptable

### Eval Categories

| Category | What It Tests | Example |
|----------|--------------|---------|
| **Format evals** | Output structure/format | JSON validity, schema compliance |
| **Content evals** | Factual correctness | Answer matches ground truth |
| **Safety evals** | Harmful output detection | Refusal rate for adversarial inputs |
| **Consistency evals** | Same input → similar output | Paraphrase invariance |
| **Edge case evals** | Boundary conditions | Empty input, very long input, multilingual |
| **Latency evals** | Performance | Response under Xms at p95 |

### Writing Your First Eval

Before writing any prompt:

```yaml
# eval-001: Code review should identify security issues
eval_id: eval-001
capability: security-code-review
description: "Model identifies SQL injection vulnerabilities in Python code"

input:
  code: |
    def get_user(username):
        query = f"SELECT * FROM users WHERE name = '{username}'"
        return db.execute(query)

expected:
  contains: ["SQL injection", "parameterized query", "f-string"]
  severity: ["high", "critical"]
  
success_criteria:
  - type: contains_any
    values: ["SQL injection", "injection attack", "parameterized"]
  - type: severity_detected
    min_severity: high

threshold:
  pass_rate: 0.90  # Must pass 90% of the time
  k: 10            # Run 10 times, need 9 passes
```

---

## Phase 2: BASELINE — Establish Current Performance

Before any implementation, run your evals against a baseline (stub/random/previous system) to establish:
- Current pass@k score
- Failure mode distribution
- Which evals are hardest

```bash
# Run eval suite and record baseline
xom-eval run --suite evals/ --model gpt-4o --runs 10 --output baseline.json

# View baseline report
xom-eval report baseline.json
```

**Baseline serves as your starting point.** Subsequent runs must beat the baseline.

---

## Phase 3: IMPLEMENT — Build to Pass Evals

Write prompt templates, retrieval logic, and orchestration code with the explicit goal of passing your defined evals.

**Rules:**
- Never add an eval after you know the output (this is eval-overfitting)
- If a new failure mode is discovered, write a new eval first, then fix it
- Implementation changes must be justified by eval improvement

---

## Phase 4: MEASURE — pass@k Metrics

### What is pass@k?

`pass@k` = probability that at least one of k samples is correct.

For AI workflows, we typically track:
- **pass@1** — First response is correct (most important for UX)
- **pass@5** — Any of 5 responses is correct (measures capability ceiling)
- **pass@10** — Quality with more attempts

### Calculating pass@k

```python
def pass_at_k(n: int, c: int, k: int) -> float:
    """
    n = total samples
    c = correct samples  
    k = k value
    Returns pass@k estimate
    """
    if n - c < k:
        return 1.0
    return 1.0 - (math.comb(n - c, k) / math.comb(n, k))

# Example: 10 runs, 8 correct
pass_at_1 = pass_at_k(n=10, c=8, k=1)   # ~0.80
pass_at_5 = pass_at_k(n=10, c=8, k=5)   # ~0.99
```

### Standard Thresholds

| Use Case | pass@1 Minimum | pass@5 Target |
|----------|---------------|---------------|
| Critical (billing, auth) | 0.95 | 0.99 |
| Standard feature | 0.80 | 0.95 |
| Experimental / research | 0.60 | 0.85 |
| Internal tool | 0.70 | 0.90 |

---

## Phase 5: ITERATE — Improve Until Threshold Met

Run the eval loop:

```
Run evals
   ↓
Check pass@k against threshold
   ↓ FAIL: Below threshold
Analyze failure patterns
   ↓
Improve prompt / retrieval / logic
   ↓
Re-run evals
   ↓ PASS: Meets threshold → proceed
```

### Iteration Strategies

| Problem | Strategy |
|---------|----------|
| Low factual accuracy | Add retrieval / better context |
| Wrong format | Few-shot examples, stricter format instructions |
| Inconsistent output | Lower temperature, structured outputs |
| Edge case failures | Targeted prompt additions, input preprocessing |
| Safety failures | Add system prompt constraints, output filtering |

---

## Phase 6: GUARD — Lock In CI, Alert on Regression

Once evals pass, commit them as permanent quality gates.

### CI Integration

```yaml
# .github/workflows/eval-gate.yml
- name: Run eval suite
  run: |
    xom-eval run --suite evals/ \
      --model ${{ env.LLM_MODEL }} \
      --runs 10 \
      --threshold 0.80 \
      --fail-below-threshold
```

### Regression Alerts

When pass@k drops by more than 5% from baseline:
1. CI fails (blocks deployment)
2. Alert posted to Slack `#ai-quality`
3. Regression report generated with examples of new failures
4. Team investigates before merge

---

## Workflow Integration

EDD integrates with existing workflows:

```
feature-implementation workflow
    ↓
[EDD: define evals for AI components]
    ↓
tdd-workflow (for non-AI logic)
    ↓
[EDD: run eval baseline]
    ↓
[implement AI logic]
    ↓
[EDD: run eval suite → must pass threshold]
    ↓
verification-loop (all 6 phases)
    ↓
PR creation
```

---

## When to Use EDD

**Always use EDD for:**
- LLM prompt development
- AI agent tool implementations  
- Retrieval-augmented generation (RAG) pipelines
- Classification or extraction tasks
- Any output that will be parsed programmatically

**Consider EDD for:**
- Structured data extraction from documents
- Summarization quality
- Code generation and review agents

**EDD is optional for:**
- Pure deterministic business logic (use TDD instead)
- Simple rule-based transformations
- UI components with no AI logic

---

## Definition of Done (EDD)

An AI feature is **done** when:
- [ ] Evals written before implementation (eval-first confirmed by git history)
- [ ] Baseline established and recorded
- [ ] pass@1 meets capability threshold
- [ ] Evals committed to `evals/` directory
- [ ] CI eval gate configured and passing
- [ ] Regression tracking initialized in `metrics/`
- [ ] PR includes eval results table

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Eval-after | Writing evals after seeing outputs | Write evals first, verify by git log |
| Cherry-picking runs | Running until you get a good result | Fix k and run count before starting |
| Threshold inflation | Raising threshold to match actual performance | Set thresholds based on UX need, not current perf |
| Eval overfitting | Tuning to eval set, not generalization | Hold out 20% of evals for validation |
| Ignoring regressions | Merging despite CI failures | Block merge on eval regression |

---

## References

- [Anthropic Evals Framework](https://github.com/anthropics/evals)
- [OpenAI Evals](https://github.com/openai/evals)
- [Chen et al. — Evaluating Large Language Models Trained on Code (pass@k)](https://arxiv.org/abs/2107.03374)
- [Eval Template](./eval-template.md)
- [Metrics Tracking Guide](./metrics-tracking.md)
