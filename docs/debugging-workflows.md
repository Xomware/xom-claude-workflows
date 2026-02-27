# Debugging & Monitoring Workflows

Comprehensive guide to monitoring, debugging, and troubleshooting workflows.

## Monitoring Executions

### View Workflow Run Status

```bash
# List recent runs
xom-cli workflow runs --workflow my-workflow

# View specific run
xom-cli workflow status --workflow-run run_12345

# Output:
# Status: in_progress
# Started: 2026-02-27T14:30:00Z
# Duration: 5m 23s
# Current Step: analyze-code
```

### Real-Time Logs

```bash
# Stream logs from running workflow
xom-cli workflow logs --workflow-run run_12345 --follow

# View last N lines
xom-cli workflow logs --workflow-run run_12345 --lines 50

# Export logs
xom-cli workflow logs --workflow-run run_12345 > logs.txt
```

### Step-Level Details

```bash
# Get details for specific step
xom-cli workflow step --workflow-run run_12345 --step analyze-code

# Output:
# Step: analyze-code
# Status: completed
# Agent: claude-opus
# Duration: 2m 15s
# Input: {files: ["src/main.py", "src/utils.py"]}
# Output: {score: 85, issues: 3}
```

## Metrics & Performance

### Workflow Metrics

```bash
# View metrics for workflow
xom-cli workflow metrics --workflow my-workflow

# Includes:
# - Average duration
# - Success rate
# - Error rate
# - Most common failures
# - Agent utilization
```

### Step Performance

```bash
# Get duration breakdown
xom-cli workflow metrics --workflow my-workflow --breakdown steps

# Output:
# Step                  Avg Duration  Success Rate
# fetch-pr              15s           99.8%
# analyze-code          2m 30s        98.5%
# security-review       1m 45s        97.2%
# post-comment          5s            99.9%
```

### Agent Utilization

```bash
# View agent usage
xom-cli workflow metrics --workflow-run run_12345 --agent-stats

# Output:
# Agent              Execution Time  Cost        Error Rate
# claude-opus        2m 15s          $0.0850     0.2%
# claude-sonnet      1m 30s          $0.0125     0.5%
# devops-bot         20s             $0.0000     0.0%
```

## Error Debugging

### View Error Details

```bash
# Get error details
xom-cli workflow error --workflow-run run_12345 --step analyze-code

# Output:
# Error Type: timeout
# Message: Step exceeded 180s timeout
# Agent: claude-opus
# Timestamp: 2026-02-27T14:35:23Z
# Last Output: {files_analyzed: 42, ...}
```

### Error Histogram

```bash
# View error patterns
xom-cli workflow metrics --workflow my-workflow --errors

# Output:
# Error Type          Count  Percentage
# timeout             45     12.5%
# agent_failure       28     7.8%
# validation_error    12     3.3%
# network_error       8      2.2%
```

### Reproduce Error Locally

```bash
# Get failed workflow inputs
xom-cli workflow run --workflow-run run_12345 --export-inputs inputs.json

# Run locally with same inputs
xom-cli workflow run --workflow my-workflow --input-file inputs.json

# Test with debug logging
xom-cli workflow run --workflow my-workflow \
  --input-file inputs.json \
  --log-level debug
```

## Common Issues & Solutions

### Workflow Timing Out

**Symptom:** Workflow exceeds total timeout

**Diagnosis:**
```bash
xom-cli workflow logs --workflow-run run_12345 | grep -i timeout
```

**Solutions:**
```yaml
# Increase timeout
resources:
  timeout_total: 1200s  # was 600s

# Or reduce scope
steps:
  - id: heavy-processing
    timeout: 120s  # was 180s
    
  - id: parallel-work
    type: parallel
    worker_count: 8  # increase parallelization
```

### Step Failing Repeatedly

**Symptom:** Step keeps failing after retries

**Diagnosis:**
```bash
# Check step logs
xom-cli workflow logs --workflow-run run_12345 --step step-id

# Check agent performance
xom-cli workflow metrics --workflow my-workflow --agent claude-opus

# Test with different agent
xom-cli workflow run --workflow my-workflow --override-agent step-id:claude-sonnet
```

**Solutions:**
```yaml
# Fallback to different agent
error_handling:
  on_failure: fallback_agent:claude-sonnet

# Increase retries
error_handling:
  retry_attempts: 5
  backoff: exponential
  max_backoff: 120s

# Reduce input complexity
input:
  data: ${{ inputs.data | first(100) }}
```

### Agent Exceeding Context Limits

**Symptom:** Agent errors about token limit

**Diagnosis:**
```bash
xom-cli workflow logs --workflow-run run_12345 | grep -i "token\|context"
```

**Solutions:**
```yaml
# Summarize input
- id: summarize
  agent: claude-sonnet
  input:
    large_data: ${{ inputs.large_data | summarize }}

# Split into smaller tasks
- id: process-batch-1
  input:
    data: ${{ inputs.data | slice(0, 100) }}

- id: process-batch-2
  input:
    data: ${{ inputs.data | slice(100, 200) }}
```

## Performance Optimization

### Profile Workflow

```bash
# Generate performance profile
xom-cli workflow profile --workflow my-workflow --runs 10

# Output includes:
# - Step durations
# - Bottlenecks
# - Parallelization opportunities
# - Cost breakdown
```

### Identify Bottlenecks

```bash
# Find slowest steps
xom-cli workflow metrics --workflow my-workflow \
  --sort duration \
  --limit 5

# Output:
# Step                  Duration  % of Total
# analyze-code          2m 30s    42%
# generate-visualizations 1m 45s   29%
# security-review       1m 15s    21%
```

### Optimization Strategies

**1. Parallelization**
```yaml
# Before: sequential
- id: step1
- id: step2
  depends_on: step1
- id: step3
  depends_on: step2

# After: parallel where possible
- id: step1
- id: step2
- id: step3
- id: combine
  depends_on: [step1, step2, step3]
```

**2. Caching**
```yaml
# Cache expensive computations
- id: analyze
  cache:
    key: ${{ inputs.data_hash }}
    ttl: 3600s
```

**3. Reduce Model Cost**
```yaml
# Use faster (cheaper) model for simple tasks
- id: classify
  agent: claude-sonnet  # instead of opus

# Reserve opus for complex tasks
- id: design
  agent: claude-opus
```

## Alerting & Notifications

### Configure Alerts

```bash
# Alert on failure
xom-cli workflow configure --workflow my-workflow \
  --alert-on failure \
  --alert-channel slack

# Alert on timeout
xom-cli workflow configure --workflow my-workflow \
  --alert-on timeout \
  --alert-channel email

# Alert on threshold
xom-cli workflow configure --workflow my-workflow \
  --alert-on success_rate<95% \
  --alert-channel slack
```

### Custom Alerts

```yaml
observability:
  alerts:
    - name: high-error-rate
      condition: error_rate > 5%
      channels: [slack, email]
    
    - name: slow-execution
      condition: duration > 5m
      channels: [slack]
    
    - name: cost-overrun
      condition: estimated_cost > $1.00
      channels: [email]
```

## Logging Configuration

### Log Levels

```bash
# Set globally
xom-cli config set log-level debug

# Set for workflow
xom-cli workflow configure --workflow my-workflow --log-level debug

# Set for step
# In workflow.yaml:
steps:
  - id: step
    logging:
      level: debug  # trace, debug, info, warn, error
```

### Log Output

```bash
# To console
xom-cli workflow logs --workflow-run run_12345 --output console

# To file
xom-cli workflow logs --workflow-run run_12345 --output file:logs.txt

# To cloud
xom-cli workflow logs --workflow-run run_12345 --output cloudwatch
```

## Health Checks

### Workflow Health

```bash
# Get health status
xom-cli workflow health --workflow my-workflow

# Output:
# Status: healthy
# Recent Executions: 10
# Success Rate: 98.5%
# Last Error: 2h ago
# Average Duration: 4m 32s
```

### System Health

```bash
# Check overall system
xom-cli system health

# Includes:
# - Agent availability
# - API response times
# - Error rates
# - Webhook delivery status
```

## Historical Analysis

### Trend Analysis

```bash
# View trends over time
xom-cli workflow analytics --workflow my-workflow \
  --period 7d \
  --metrics duration,success_rate,cost

# Export for analysis
xom-cli workflow analytics --workflow my-workflow \
  --period 30d \
  --format csv > analytics.csv
```

### Comparison

```bash
# Compare two workflows
xom-cli workflow compare --workflow1 workflow-a --workflow2 workflow-b \
  --metrics duration,cost,success_rate
```

## Troubleshooting Commands Reference

```bash
# Quick diagnostics
xom-cli workflow diagnose --workflow my-workflow

# Verbose output
xom-cli workflow diagnose --workflow my-workflow -vv

# Export diagnostic bundle
xom-cli workflow diagnose --workflow my-workflow --export diagnostics.zip

# Test trigger
xom-cli workflow test-trigger --workflow my-workflow

# Validate configuration
xom-cli workflow validate workflows/my-workflow/workflow.yaml

# Check agent connectivity
xom-cli agent health --agent claude-opus

# Test webhook
xom-cli webhook test --workflow my-workflow --event pull_request
```

## Debugging Tips

1. **Enable debug logging early:** Add `--log-level debug` before running
2. **Isolate the problem:** Run individual steps independently
3. **Test with minimal input:** Reduce input size to test flow
4. **Review error messages carefully:** Often contain useful context
5. **Check agent logs:** Agent-specific errors in agent logs
6. **Monitor resource usage:** Ensure sufficient memory/CPU
7. **Use test triggers:** Test webhook filters with realistic payloads

## See Also

- [workflow-development.md](workflow-development.md) — Creating workflows
- [trigger-configuration.md](trigger-configuration.md) — Webhook setup
- [deployment.md](deployment.md) — Production deployment
