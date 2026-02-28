# Metrics Tracking — pass@k Over Time

This guide explains how to track eval metrics longitudinally, detect regressions, and alert the team when AI quality drops.

---

## Why Track Metrics Over Time?

AI model quality is not static. Quality can regress when:
- The underlying model is updated (API version changes)
- A prompt is modified
- The retrieval context changes
- New edge cases emerge in production
- Temperature or sampling parameters change

Without longitudinal tracking, you won't know quality has degraded until users complain.

---

## Metrics Storage Format

Store eval results as JSON Lines (`.jsonl`) — one result per line, easy to append.

### Result Schema

```json
{
  "run_id": "run-20260228-001",
  "timestamp": "2026-02-28T15:30:00Z",
  "eval_id": "eval-001",
  "workflow": "code-review",
  "capability": "security-detection",
  "model": "claude-sonnet-4",
  "model_version": "20260228",
  "prompt_hash": "a1b2c3d4",
  "k": 10,
  "n_correct": 8,
  "n_total": 10,
  "pass_at_1": 0.80,
  "pass_at_5": 0.992,
  "pass_at_10": 1.0,
  "threshold": 0.85,
  "status": "fail",
  "failure_examples": [
    {
      "run": 3,
      "input_hash": "x9y8z7",
      "output_snippet": "The code looks fine...",
      "failure_reason": "Did not contain 'SQL injection'"
    }
  ],
  "git_sha": "abc123",
  "branch": "feature/code-review-v2",
  "ci_run_url": "https://github.com/org/repo/actions/runs/123456"
}
```

### File Organization

```
metrics/
├── results/
│   ├── 2026-01-01.jsonl
│   ├── 2026-02-01.jsonl
│   └── 2026-02-28.jsonl
├── baselines/
│   ├── code-review-baseline-v1.json
│   └── summarization-baseline-v1.json
├── regressions/
│   └── 2026-02-15-regression-report.md
└── dashboard.json           # Aggregated for display
```

---

## Recording Metrics

### After Each CI Run

```bash
# Run evals and save results
xom-eval run \
  --suite evals/ \
  --model claude-sonnet-4 \
  --runs 10 \
  --output metrics/results/$(date +%Y-%m-%d).jsonl \
  --append  # append to daily file if exists

# Update rolling dashboard
xom-eval aggregate \
  --input metrics/results/ \
  --output metrics/dashboard.json \
  --window 30d  # Last 30 days
```

### Manually Recording (without CLI)

```python
import json
import datetime
import math

def pass_at_k(n: int, c: int, k: int) -> float:
    """Unbiased pass@k estimator from Chen et al. 2021"""
    if n - c < k:
        return 1.0
    from math import comb
    return 1.0 - comb(n - c, k) / comb(n, k)

def record_eval_result(eval_id: str, n_correct: int, n_total: int, 
                        k: int = 10, model: str = "claude-sonnet-4",
                        threshold: float = 0.80):
    result = {
        "run_id": f"run-{datetime.datetime.utcnow().strftime('%Y%m%d-%H%M%S')}",
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "eval_id": eval_id,
        "model": model,
        "k": k,
        "n_correct": n_correct,
        "n_total": n_total,
        "pass_at_1": pass_at_k(n_total, n_correct, 1),
        "pass_at_5": pass_at_k(n_total, n_correct, 5),
        "pass_at_10": pass_at_k(n_total, n_correct, 10),
        "threshold": threshold,
        "status": "pass" if pass_at_k(n_total, n_correct, 1) >= threshold else "fail"
    }
    
    with open(f"metrics/results/{datetime.date.today()}.jsonl", "a") as f:
        f.write(json.dumps(result) + "\n")
    
    return result
```

---

## Regression Detection

### What Counts as a Regression?

| Condition | Severity | Action |
|-----------|----------|--------|
| pass@1 drops > 10% from baseline | 🔴 Critical | Block CI, alert immediately |
| pass@1 drops 5-10% from baseline | 🟡 Warning | Alert, require review |
| pass@1 drops 1-5% from baseline | 🔵 Info | Log, monitor |
| New eval fails on first run | 🔴 Critical | Block CI |
| pass@1 drops below threshold | 🔴 Critical | Block CI |

### Regression Detection Script

```python
#!/usr/bin/env python3
"""
regression_detector.py — Detect eval regressions against baseline
Usage: python regression_detector.py --baseline metrics/baselines/v1.json --current metrics/results/today.jsonl
"""

import json
import sys
import argparse
from pathlib import Path

REGRESSION_THRESHOLD = 0.10  # Alert if drop > 10%
WARNING_THRESHOLD = 0.05     # Warn if drop > 5%

def load_baseline(path: str) -> dict:
    with open(path) as f:
        return {r["eval_id"]: r for r in (json.loads(l) for l in f) if l.strip()}

def load_current(path: str) -> dict:
    with open(path) as f:
        results = {}
        for line in f:
            if line.strip():
                r = json.loads(line)
                results[r["eval_id"]] = r
    return results

def detect_regressions(baseline: dict, current: dict) -> list:
    regressions = []
    
    for eval_id, base in baseline.items():
        if eval_id not in current:
            regressions.append({
                "eval_id": eval_id,
                "severity": "critical",
                "reason": "Eval missing from current run",
                "baseline_pass_at_1": base["pass_at_1"],
                "current_pass_at_1": None,
                "drop": None
            })
            continue
        
        curr = current[eval_id]
        drop = base["pass_at_1"] - curr["pass_at_1"]
        
        if drop > REGRESSION_THRESHOLD:
            severity = "critical"
        elif drop > WARNING_THRESHOLD:
            severity = "warning"
        elif curr["pass_at_1"] < curr["threshold"]:
            severity = "critical"
        else:
            continue  # No regression
        
        regressions.append({
            "eval_id": eval_id,
            "workflow": curr.get("workflow", "unknown"),
            "capability": curr.get("capability", "unknown"),
            "severity": severity,
            "baseline_pass_at_1": base["pass_at_1"],
            "current_pass_at_1": curr["pass_at_1"],
            "drop": drop,
            "threshold": curr["threshold"],
            "below_threshold": curr["pass_at_1"] < curr["threshold"]
        })
    
    return sorted(regressions, key=lambda x: x.get("drop") or 1.0, reverse=True)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--current", required=True)
    parser.add_argument("--fail-on-critical", action="store_true")
    args = parser.parse_args()
    
    baseline = load_baseline(args.baseline)
    current = load_current(args.current)
    regressions = detect_regressions(baseline, current)
    
    if not regressions:
        print("✅ No regressions detected")
        sys.exit(0)
    
    print("\n=== REGRESSION REPORT ===\n")
    has_critical = False
    
    for r in regressions:
        icon = "🔴" if r["severity"] == "critical" else "🟡"
        print(f"{icon} [{r['severity'].upper()}] {r['eval_id']}")
        print(f"   Capability: {r.get('workflow', 'N/A')}/{r.get('capability', 'N/A')}")
        print(f"   Baseline pass@1: {r['baseline_pass_at_1']:.1%}")
        print(f"   Current  pass@1: {r['current_pass_at_1']:.1%}" if r['current_pass_at_1'] else "   Current: MISSING")
        if r.get("drop"):
            print(f"   Drop:           {r['drop']:.1%}")
        if r.get("below_threshold"):
            print(f"   ⚠️  Below threshold ({r['threshold']:.1%})")
        print()
        
        if r["severity"] == "critical":
            has_critical = True
    
    if args.fail_on_critical and has_critical:
        print("❌ Critical regressions found. Pipeline blocked.")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

---

## Alerting

### GitHub Actions Regression Gate

```yaml
# .github/workflows/eval-regression-check.yml
name: Eval Regression Check

on:
  push:
    branches: [main]
  pull_request:

jobs:
  eval-regression:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run eval suite
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          pip install xom-eval
          xom-eval run \
            --suite evals/ \
            --model claude-sonnet-4 \
            --runs 10 \
            --output metrics/results/$(date +%Y-%m-%d).jsonl
      
      - name: Detect regressions
        run: |
          python metrics/regression_detector.py \
            --baseline metrics/baselines/current-baseline.jsonl \
            --current metrics/results/$(date +%Y-%m-%d).jsonl \
            --fail-on-critical
      
      - name: Post regression report to PR
        if: failure() && github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('regression-report.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 🔴 Eval Regression Detected\n\n\`\`\`\n${report}\n\`\`\``
            });
      
      - name: Save results artifact
        uses: actions/upload-artifact@v4
        with:
          name: eval-results-${{ github.sha }}
          path: metrics/results/
```

### Slack Alerting

```python
# In your eval runner or CI post-step
import requests

def alert_slack(regressions: list, webhook_url: str):
    if not any(r["severity"] == "critical" for r in regressions):
        return
    
    critical = [r for r in regressions if r["severity"] == "critical"]
    
    message = {
        "text": f"🔴 *Eval Regression Detected* — {len(critical)} critical regression(s)",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*🔴 Eval Regression Detected*\n{len(critical)} critical regression(s) found in latest run"
                }
            }
        ] + [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*{r['eval_id']}*\npass@1: {r['baseline_pass_at_1']:.0%} → {r['current_pass_at_1']:.0%} (↓{r['drop']:.0%})"
                }
            }
            for r in critical[:5]  # Max 5 in alert
        ]
    }
    
    requests.post(webhook_url, json=message)
```

---

## Updating Baselines

When a **deliberate** model or prompt improvement raises quality, update the baseline:

```bash
# After verifying improvement is intentional:
cp metrics/results/$(date +%Y-%m-%d).jsonl metrics/baselines/current-baseline.jsonl

# Or promote a specific run:
xom-eval baseline --promote metrics/results/2026-02-28.jsonl \
  --output metrics/baselines/current-baseline.jsonl \
  --message "Upgraded to claude-sonnet-4, all evals improved"
```

**Rules for baseline updates:**
1. Baseline can only be updated on `main` branch
2. Requires PR approval from at least 1 team member
3. Commit message must explain why the baseline changed
4. Old baseline is archived (never deleted)

---

## Dashboard Metrics

Track these metrics on your team dashboard:

| Metric | Target | Alert If |
|--------|--------|----------|
| Overall pass@1 across all evals | ≥0.85 | <0.80 |
| Critical evals pass@1 | ≥0.95 | <0.90 |
| Evals with regression (7d) | 0 | >0 |
| New evals added (sprint) | ≥1 per new AI feature | 0 |
| Eval coverage (% AI code) | ≥80% | <60% |
| Mean eval run time | <5 min | >10 min |

---

## Weekly Eval Review

Every sprint, review:

1. **Which evals failed most often?** → Prioritize improvement
2. **Are there capabilities without evals?** → Write new evals
3. **Did any baseline updates happen?** → Verify they're intentional improvements
4. **What's the trend line?** → Quality should trend up or stay flat

```bash
# Generate weekly summary
xom-eval report \
  --input metrics/results/ \
  --window 7d \
  --format markdown \
  --output reports/weekly-$(date +%Y-%W).md
```
