# Workflow Development Guide

How to create, customize, and deploy Claude-powered workflows.

## Table of Contents
- [Creating a Workflow](#creating-a-workflow)
- [Workflow Structure](#workflow-structure)
- [Agent Assignment](#agent-assignment)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Best Practices](#best-practices)

## Creating a Workflow

### 1. Choose a Template

Start with one of the provided templates based on your workflow pattern:

```bash
# Sequential workflow (steps run one after another)
cp templates/sequential-workflow.yaml workflows/my-workflow/workflow.yaml

# Parallel workflow (steps run concurrently)
cp templates/parallel-workflow.yaml workflows/my-workflow/workflow.yaml

# Conditional workflow (branching logic)
cp templates/conditional-workflow.yaml workflows/my-workflow/workflow.yaml

# Multi-agent orchestration
cp templates/orchestration-template.yaml workflows/my-workflow/workflow.yaml
```

### 2. Define Workflow Metadata

```yaml
name: my-workflow
description: "What this workflow does"
version: "1.0"

inputs:
  param_1:
    type: string
    required: true
    description: "Input parameter"

outputs:
  result:
    type: string
    description: "Output result"
```

### 3. Define Triggers

```yaml
triggers:
  - type: manual
    description: "Trigger via CLI"
  
  - type: github-webhook
    event: pull_request
    actions: [opened]
  
  - type: schedule
    cron: "0 * * * *"
  
  - type: slack-webhook
    command: /my-command
```

### 4. Define Steps

```yaml
steps:
  - id: step-1
    name: "Step One"
    agent: claude-sonnet
    timeout: 60s
    input:
      param: ${{ inputs.param_1 }}
    output:
      result: object
    error_handling:
      retry_attempts: 2
      on_failure: exit
```

## Workflow Structure

### Minimal Workflow

```yaml
---
name: minimal-workflow
description: "Minimal workflow example"
version: "1.0"

inputs:
  input_data:
    type: string
    required: true

outputs:
  output_data:
    type: string

triggers:
  - type: manual

steps:
  - id: process
    name: "Process"
    agent: claude-sonnet
    timeout: 30s
    input:
      data: ${{ inputs.input_data }}
    output:
      result: string
```

### Complete Workflow

```yaml
---
name: complete-workflow
description: "Complete workflow with all features"
version: "1.0"

# Inputs
inputs:
  primary_input:
    type: string
    required: true
    description: "Primary input"
  optional_input:
    type: integer
    required: false
    default: 10

# Outputs
outputs:
  primary_output:
    type: object
    description: "Main output"

# Triggers
triggers:
  - type: manual
  - type: schedule
    cron: "0 * * * *"

# Steps
steps:
  - id: validate
    name: "Validate Input"
    agent: claude-sonnet
    timeout: 30s
    input:
      data: ${{ inputs.primary_input }}
    output:
      valid: boolean
      errors: array
    error_handling:
      retry_attempts: 1
      on_failure: exit

  - id: process
    name: "Process"
    agent: claude-opus
    timeout: 120s
    depends_on: validate
    condition: ${{ steps.validate.output.valid == true }}
    input:
      data: ${{ inputs.primary_input }}
      multiplier: ${{ inputs.optional_input }}
    output:
      result: object
    error_handling:
      retry_attempts: 2
      backoff: exponential
      on_failure: [log, fallback_agent:claude-sonnet]

  - id: notify
    name: "Notify"
    agent: notification-bot
    timeout: 10s
    depends_on: process
    input:
      result: ${{ steps.process.output.result }}

# Global error handling
error_handling:
  default_retry_attempts: 2
  default_backoff: exponential
  on_critical_failure: escalate_to_human

# Observability
observability:
  log_level: info
  metrics: [duration, success_rate]
  trace: enabled

# Resources
resources:
  timeout_total: 300s
  max_concurrent_steps: 2

# Success criteria
success_criteria:
  - all_steps_completed
  - result_generated
```

## Agent Assignment

### Available Agents

```yaml
agents:
  claude-opus:
    model: claude-opus-4
    capabilities:
      - complex_reasoning
      - architecture_design
      - deep_analysis
    temperature: 0.7

  claude-sonnet:
    model: claude-sonnet-4
    capabilities:
      - fast_processing
      - code_generation
      - content_creation
    temperature: 0.5

  integration-bots:
    - devops-bot: Git, CI/CD operations
    - notification-bot: Slack, email notifications
    - monitoring-bot: System health checks
    - security-scanner: Security scanning
```

### Assigning Agents to Steps

```yaml
steps:
  - id: analyze
    agent: claude-opus  # Expert reasoning
    
  - id: implement
    agent: claude-sonnet  # Fast implementation
    
  - id: notify
    agent: notification-bot  # Send notifications
```

## Error Handling

### Retry Strategies

```yaml
error_handling:
  # No retry
  retry_attempts: 0
  
  # Linear backoff: 1s, 2s, 3s, ...
  retry_attempts: 3
  backoff: linear
  backoff_multiplier: 1s
  
  # Exponential backoff: 1s, 2s, 4s, ...
  retry_attempts: 3
  backoff: exponential
  backoff_base: 2
  max_backoff: 60s
```

### Failure Actions

```yaml
error_handling:
  on_failure: exit  # Stop immediately
  on_failure: continue  # Skip and continue
  on_failure: fallback_agent:claude-sonnet  # Try with different agent
  on_failure: [log, notify, escalate]  # Multiple actions
  on_failure: human_review  # Escalate to human
```

### Conditional Recovery

```yaml
steps:
  - id: primary
    error_handling:
      retry_attempts: 2
      on_failure: skip
  
  - id: fallback
    condition: ${{ steps.primary.failed }}
    depends_on: primary
```

## Testing

### Validate Workflow

```bash
xom-cli workflow validate workflows/my-workflow/workflow.yaml
```

### Test Locally

```bash
xom-cli workflow run --workflow workflows/my-workflow/workflow.yaml \
  --input '{"param_1": "test_value"}'
```

### Monitor Execution

```bash
xom-cli workflow logs --workflow-run <run-id> --follow
xom-cli workflow status --workflow-run <run-id>
```

### Test with Different Inputs

```bash
# Create test input file
cat > test-input.json << EOF
{
  "param_1": "test_value",
  "optional_param": 42
}
EOF

# Run with test input
xom-cli workflow run --workflow workflows/my-workflow/workflow.yaml \
  --input-file test-input.json
```

## Best Practices

### 1. Design for Resilience

```yaml
steps:
  - id: critical-operation
    error_handling:
      retry_attempts: 3
      backoff: exponential
      on_failure: escalate_to_human
```

### 2. Use Meaningful Step IDs

```yaml
# Good
- id: fetch-pr-details
- id: analyze-code-quality
- id: post-review-comment

# Bad
- id: step1
- id: step2
- id: step3
```

### 3. Document Input/Output

```yaml
inputs:
  github_repo:
    type: string
    required: true
    description: "GitHub repo in owner/name format"
    example: "Xomware/xom-claude-workflows"

outputs:
  analysis_score:
    type: float
    description: "Code quality score 0-100"
```

### 4. Set Appropriate Timeouts

```yaml
steps:
  # Quick validation: 30s
  - id: validate
    timeout: 30s
  
  # Analysis: 2-5 minutes
  - id: analyze
    timeout: 180s
  
  # Deployments: 10-20 minutes
  - id: deploy
    timeout: 600s
```

### 5. Use Dependencies Correctly

```yaml
# Sequential execution
steps:
  - id: step1
  - id: step2
    depends_on: step1
  - id: step3
    depends_on: step2

# Multiple dependencies
- id: step4
  depends_on: [step2, step3]

# Parallel execution
- id: step5
- id: step6
# No depends_on = can run in parallel
```

### 6. Implement Proper Logging

```yaml
observability:
  log_level: info  # debug, info, warn, error
  metrics:
    - workflow_duration
    - step_duration
    - success_rate
    - error_rate
  trace: enabled
```

### 7. Monitor Resource Usage

```yaml
resources:
  timeout_total: 600s
  max_concurrent_steps: 4
  max_parallel_workers: 8
```

### 8. Handle Secrets Properly

```bash
# Set environment variables
export GITHUB_TOKEN=ghp_xxxxx
export SLACK_WEBHOOK_URL=https://hooks.slack.com/...

# In workflow, reference environment variables
input:
  token: ${{ env.GITHUB_TOKEN }}
```

## Advanced Patterns

### Conditional Branching

```yaml
steps:
  - id: check-condition
    output:
      should_deploy: boolean
  
  - id: deploy-to-prod
    condition: ${{ steps.check-condition.output.should_deploy == true }}
  
  - id: deploy-to-staging
    condition: ${{ steps.check-condition.output.should_deploy == false }}
```

### Parallel Processing

```yaml
- id: parallel-work
  type: parallel
  worker_count: 4
  
  worker_steps:
    - id: process-item
      agent: claude-sonnet
      input:
        item: ${{ parallel.item }}
        index: ${{ parallel.index }}
```

### Multi-Agent Orchestration

```yaml
- id: architecture
  agent: claude-opus
  output:
    design: object

- id: implementation
  agent: claude-sonnet
  depends_on: architecture
  input:
    design: ${{ steps.architecture.output.design }}
```

## Deployment

### Deploy Workflow

```bash
xom-cli workflow deploy workflows/my-workflow/workflow.yaml
```

### Enable Triggers

```bash
# GitHub webhooks
xom-cli workflow configure --workflow my-workflow \
  --github-webhook --repo Xomware/my-repo

# Slack commands
xom-cli workflow configure --workflow my-workflow \
  --slack-command /my-command
```

### Monitor Deployments

```bash
xom-cli workflow metrics --workflow my-workflow
xom-cli workflow health --workflow my-workflow
```

## Troubleshooting

### Common Issues

**Workflow times out:**
- Increase step timeouts
- Reduce agent workload
- Add retry logic

**Steps failing sequentially:**
- Check dependencies
- Verify input/output types
- Test with simpler inputs

**High error rates:**
- Enable debug logging
- Review error messages
- Add explicit error handling

**Agent performance issues:**
- Switch to faster model (opus → sonnet)
- Reduce context size
- Use parallel execution

## See Also

- [trigger-configuration.md](trigger-configuration.md) — Webhook & schedule setup
- [debugging-workflows.md](debugging-workflows.md) — Monitoring & troubleshooting
- [deployment.md](deployment.md) — Production deployment guide
- [WORKFLOWS.md](../WORKFLOWS.md) — Reference for all 8 workflows
