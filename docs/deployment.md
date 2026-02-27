# Deployment Guide

Deploy Claude-powered workflows to production.

## Pre-Deployment Checklist

- [ ] Workflow passes validation: `xom-cli workflow validate workflow.yaml`
- [ ] All triggers are configured
- [ ] Error handling is in place
- [ ] Tests pass locally
- [ ] Secrets are configured in environment
- [ ] Monitoring/alerting is enabled
- [ ] Documentation is complete
- [ ] Code review approved

## Environment Setup

### Development

```bash
# Set environment variables
export WORKFLOW_ENV=development
export LOG_LEVEL=debug
export AGENT_MODEL=claude-sonnet  # Use cheaper model
export GITHUB_TOKEN=ghp_dev_token
export SLACK_TOKEN=xoxb_dev_token

# Create development workflow
xom-cli workflow create --workflow my-workflow \
  --env development \
  --log-level debug
```

### Staging

```bash
# Set environment variables
export WORKFLOW_ENV=staging
export LOG_LEVEL=info
export AGENT_MODEL=claude-opus  # Full capability
export GITHUB_TOKEN=$GITHUB_STAGING_TOKEN
export SLACK_TOKEN=$SLACK_STAGING_TOKEN

# Deploy to staging
xom-cli workflow deploy workflows/my-workflow/workflow.yaml \
  --env staging \
  --dry-run
```

### Production

```bash
# Set environment variables
export WORKFLOW_ENV=production
export LOG_LEVEL=warn
export AGENT_MODEL=claude-opus
export GITHUB_TOKEN=$GITHUB_PROD_TOKEN
export SLACK_TOKEN=$SLACK_PROD_TOKEN

# Deploy to production
xom-cli workflow deploy workflows/my-workflow/workflow.yaml \
  --env production \
  --require-approval
```

## Secrets Management

### Using Environment Variables

```bash
# Set secrets
export GITHUB_WEBHOOK_SECRET="your-secret"
export SLACK_SIGNING_SECRET="your-secret"
export DATABASE_PASSWORD="your-password"

# Reference in workflow
steps:
  - id: step
    input:
      token: ${{ env.GITHUB_TOKEN }}
```

### Using Vault/Secrets Manager

```bash
# AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id workflow-secrets

# HashiCorp Vault
vault kv get secret/workflows/my-workflow

# GitHub Secrets (for Actions)
gh secret set GITHUB_TOKEN --body $TOKEN
```

### Secure Secret Passing

```yaml
# Never log secrets
observability:
  mask_sensitive_data: true
  sensitive_fields:
    - password
    - token
    - secret
    - api_key

# Don't include in workflow files
# ❌ BAD
steps:
  - id: step
    input:
      token: "ghp_xxxxxxxxxxxxx"

# ✅ GOOD
steps:
  - id: step
    input:
      token: ${{ env.GITHUB_TOKEN }}
```

## Deployment Process

### 1. Validate Workflow

```bash
xom-cli workflow validate workflows/my-workflow/workflow.yaml

# Output:
# ✓ Workflow schema is valid
# ✓ All required inputs are defined
# ✓ All steps have proper error handling
# ✓ Agent assignments are valid
# ✓ Triggers are configured correctly
```

### 2. Test in Staging

```bash
# Deploy to staging
xom-cli workflow deploy workflows/my-workflow/workflow.yaml \
  --env staging

# Run test execution
xom-cli workflow trigger --workflow my-workflow \
  --env staging \
  --input '{"test": true}'

# Monitor execution
xom-cli workflow logs --workflow-run run_xxxxx --follow

# Verify results
xom-cli workflow status --workflow-run run_xxxxx
```

### 3. Configure Triggers

```bash
# GitHub webhooks
xom-cli workflow configure --workflow my-workflow \
  --github-webhook \
  --repo Xomware/my-repo \
  --events pull_request,push

# Slack commands
xom-cli workflow configure --workflow my-workflow \
  --slack-command /my-command

# Schedules
xom-cli workflow configure --workflow my-workflow \
  --schedule "0 * * * *"
```

### 4. Production Deployment

```bash
# Deploy with approval requirement
xom-cli workflow deploy workflows/my-workflow/workflow.yaml \
  --env production \
  --require-approval

# This will:
# 1. Create deployment request
# 2. Send notification to approvers
# 3. Wait for approval
# 4. Deploy after approval
```

### 5. Enable Monitoring

```bash
# Configure alerting
xom-cli workflow configure --workflow my-workflow \
  --alert-on failure \
  --alert-channel slack \
  --alert-webhook $SLACK_WEBHOOK_URL

# Enable metrics collection
xom-cli workflow configure --workflow my-workflow \
  --metrics enabled \
  --metrics-retention 30d
```

## Rollback Procedure

### Immediate Rollback

```bash
# Disable workflow immediately
xom-cli workflow disable --workflow my-workflow

# Or revert to previous version
xom-cli workflow rollback --workflow my-workflow \
  --version previous

# Verify rollback
xom-cli workflow status --workflow my-workflow
```

### Gradual Rollback

```bash
# Scale down to 10% traffic
xom-cli workflow configure --workflow my-workflow \
  --traffic-percentage 10

# Monitor for errors
xom-cli workflow metrics --workflow my-workflow --period 5m

# If errors detected, disable
xom-cli workflow disable --workflow my-workflow

# If healthy, scale back up
xom-cli workflow configure --workflow my-workflow \
  --traffic-percentage 100
```

## Monitoring in Production

### Health Checks

```bash
# Enable health checks
xom-cli workflow configure --workflow my-workflow \
  --health-checks enabled \
  --health-check-interval 5m

# View health status
xom-cli workflow health --workflow my-workflow
```

### Alerting

```yaml
# Configure in workflow.yaml
observability:
  alerts:
    - name: error-rate-high
      condition: error_rate > 5%
      channels: [slack, pagerduty]
      severity: critical
    
    - name: slow-execution
      condition: p95_duration > 5m
      channels: [slack]
      severity: warning
    
    - name: cost-overrun
      condition: daily_cost > $100
      channels: [email]
      severity: warning
```

### Metrics Dashboard

```bash
# Create dashboard
xom-cli workflow dashboard --workflow my-workflow \
  --output dashboard.json

# Metrics to track:
# - Success rate (target: >99%)
# - Error rate (target: <1%)
# - Average duration
# - P95 duration
# - Cost per execution
# - Agent utilization
```

## Scaling Workflows

### Parallel Execution

```yaml
# Increase worker count for parallel steps
steps:
  - id: parallel-work
    type: parallel
    worker_count: 16  # was 4
```

### Resource Limits

```yaml
resources:
  # Per-step limits
  timeout_total: 1200s
  max_concurrent_steps: 8
  
  # Per-workflow limits
  max_parallel_workers: 16
  max_retries: 5
```

### Load Balancing

```bash
# Distribute across multiple regions
xom-cli workflow configure --workflow my-workflow \
  --regions us-east-1,us-west-2,eu-west-1 \
  --distribution round-robin
```

## Updates & Versioning

### Version Workflow

```yaml
# In workflow.yaml
version: "1.0.1"  # Increment on changes

# Changelog
changelog:
  - version: "1.0.1"
    date: "2026-02-27"
    changes:
      - "Improved code analysis accuracy"
      - "Added performance metrics"
```

### Backward Compatibility

```bash
# Deploy new version alongside old
xom-cli workflow deploy workflows/my-workflow/workflow.yaml \
  --version 2.0 \
  --canary \
  --canary-percentage 10

# Monitor new version
xom-cli workflow compare --workflow my-workflow:1.0 \
  --workflow my-workflow:2.0 \
  --metrics success_rate,duration,cost

# Promote if healthy
xom-cli workflow promote --workflow my-workflow \
  --from-version 2.0 \
  --canary-percentage 100
```

## Disaster Recovery

### Backup Workflows

```bash
# Backup workflow definitions
xom-cli workflow backup --workflow my-workflow \
  --output backup-2026-02-27.json

# Backup execution history
xom-cli workflow export-history --workflow my-workflow \
  --period 30d \
  --output history.json
```

### Restore Workflow

```bash
# Restore from backup
xom-cli workflow restore --workflow my-workflow \
  --backup backup-2026-02-27.json

# Verify restoration
xom-cli workflow status --workflow my-workflow
```

## Cost Management

### Monitor Costs

```bash
# View cost breakdown
xom-cli workflow costs --workflow my-workflow --period 7d

# Cost by agent
xom-cli workflow costs --workflow my-workflow --breakdown agent

# Cost by step
xom-cli workflow costs --workflow my-workflow --breakdown step

# Output:
# Agent          Executions  Avg Cost  Total Cost
# claude-opus    1,234       $0.085    $104.89
# claude-sonnet  2,567       $0.012    $30.80
```

### Optimize Costs

```yaml
# Use cheaper model when possible
steps:
  - id: classify
    agent: claude-sonnet  # cheaper than opus
    
  - id: design
    agent: claude-opus    # use opus for complex tasks

# Reduce API calls
- id: batch-process
  type: parallel
  worker_count: 8  # process multiple items in parallel

# Cache results
- id: analyze
  cache:
    key: ${{ inputs.data_hash }}
    ttl: 86400s  # cache for 24 hours
```

## Maintenance

### Regular Tasks

```bash
# Daily
xom-cli workflow health --workflow my-workflow

# Weekly
xom-cli workflow metrics --workflow my-workflow --period 7d

# Monthly
xom-cli workflow analytics --workflow my-workflow --period 30d
xom-cli workflow backup --workflow my-workflow --output monthly-backup.json

# Quarterly
xom-cli workflow audit --workflow my-workflow
```

### Updates & Patches

```bash
# Check for updates
xom-cli version check

# Update CLI
xom-cli update

# Review breaking changes
xom-cli changelog --since last-update

# Test compatibility
xom-cli workflow validate workflows/**/*.yaml
```

## Documentation

### README for Each Workflow

```markdown
# My Workflow

## Description
What this workflow does...

## Inputs
- `param1`: Description
- `param2`: Description

## Outputs
- `result`: Description

## Usage

### Trigger via Slack
\`\`\`
/my-command argument
\`\`\`

### Trigger via CLI
\`\`\`bash
xom-cli workflow trigger --workflow my-workflow
\`\`\`

## Monitoring
- [Metrics Dashboard](...)
- [Health Status](...)
- [Recent Executions](...)
```

### Runbooks

```markdown
# Incident Runbook: My Workflow Failure

## Detection
- Alert: High error rate
- Metric: Error rate > 5%

## Investigation
1. Check logs: `xom-cli workflow logs --workflow my-workflow`
2. Review recent changes
3. Check agent status

## Resolution
1. Identify root cause
2. Apply fix or rollback
3. Monitor recovery
```

## Checklist: Going to Production

**Pre-Deployment**
- [ ] Code reviewed and approved
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Performance acceptable
- [ ] Security reviewed
- [ ] Secrets configured

**Deployment**
- [ ] Deploy to staging first
- [ ] Run smoke tests
- [ ] Get production approval
- [ ] Deploy to production
- [ ] Verify deployment

**Post-Deployment**
- [ ] Monitor metrics
- [ ] Check error rates
- [ ] Verify triggers working
- [ ] Team notification sent
- [ ] Document changes

## See Also

- [workflow-development.md](workflow-development.md) — Creating workflows
- [trigger-configuration.md](trigger-configuration.md) — Configuring triggers
- [debugging-workflows.md](debugging-workflows.md) — Monitoring & debugging
