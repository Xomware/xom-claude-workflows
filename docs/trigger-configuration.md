# Trigger Configuration Guide

Configure webhooks, schedules, and manual triggers for workflows.

## GitHub Webhooks

### Setup

1. Go to repository **Settings → Webhooks → Add webhook**
2. Payload URL: `https://api.workflow.io/github/{workflow-name}`
3. Content type: `application/json`
4. Secret: Set in environment variable `GITHUB_WEBHOOK_SECRET`
5. Events: Select specific events

### Common Trigger Events

```yaml
# Pull Request Events
pull_request:
  actions: [opened, synchronize, closed, reopened]
  # Fires when PR is opened, updated, closed, or reopened

# Push Events
push:
  branch_filter: "main"
  path_filter: "src/**"
  # Fires on push to specific branch/paths

# Release Events
release:
  actions: [published, created]
  # Fires when release is published

# Issue Events
issues:
  actions: [opened, labeled, closed]
  filter: 'contains(labels, "feature-request")'
  # Fires on issue activity with label filter
```

### Example: PR Code Review Trigger

```yaml
# In hooks/github-webhooks.yaml
pr-review:
  event: pull_request
  actions: [opened, synchronize]
  triggers:
    - workflow: code-review
      inputs:
        repo: ${{ github.repository }}
        pr_number: ${{ github.event.pull_request.number }}
        review_type: full
```

### Filtering

```yaml
# Filter by branch
trigger:
  event: push
  branch_filter: "main"
  
# Filter by path
trigger:
  event: push
  path_filter: "src/**"
  
# Filter by label
trigger:
  event: issues
  filter: 'contains(labels, "critical")'

# Multiple conditions
trigger:
  event: pull_request
  filter: |
    and(
      contains(labels, "review-needed"),
      equals(author, "trusted-user")
    )
```

## Slack Integration

### Setup

1. Go to Slack app settings
2. Create slash commands
3. Add event subscriptions
4. Configure incoming webhooks for notifications

### Slash Commands

```yaml
slash_commands:
  my-command:
    command: "/my-command"
    description: "What this command does"
    usage: "/my-command [arg1] [arg2]"
    workflow: my-workflow
    handler:
      url: "https://api.workflow.io/slack/my-command"
```

### Example: Trigger from Slack

```yaml
/review-pr owner/repo 123
```

Triggers workflow:
```yaml
workflow: code-review
inputs:
  repo: owner/repo
  pr_number: 123
```

### Interactive Components

```yaml
buttons:
  approve:
    label: "Approve"
    action_id: "workflow_approve"
    workflows: [automated-deployment]
    
  reject:
    label: "Reject"
    action_id: "workflow_reject"
```

### Notifications

```yaml
notifications:
  workflow_started:
    channel: "#workflows"
    template: |
      :rocket: Workflow `{{ workflow.name }}` started
      Parameters: {{ workflow.inputs }}

  workflow_completed:
    channel: "#workflows"
    template: |
      :white_check_mark: Workflow completed successfully
      Duration: {{ workflow.duration }}
```

## Scheduled Triggers

### CRON Syntax

```
 ┌───────────── minute (0 - 59)
 │ ┌───────────── hour (0 - 23)
 │ │ ┌───────────── day of month (1 - 31)
 │ │ │ ┌───────────── month (1 - 12)
 │ │ │ │ ┌───────────── day of week (0 - 7) (0 or 7 is Sunday)
 │ │ │ │ │
 │ │ │ │ │
 * * * * *
```

### Common Schedules

```yaml
schedules:
  # Every hour
  hourly:
    cron: "0 * * * *"
  
  # Every 6 hours
  every-6-hours:
    cron: "0 */6 * * *"
  
  # Daily at 2 AM
  daily:
    cron: "0 2 * * *"
  
  # Weekdays at 9 AM
  weekday-morning:
    cron: "0 9 * * 1-5"
  
  # Sundays at midnight
  weekly:
    cron: "0 0 * * 0"
  
  # First day of month
  monthly:
    cron: "0 0 1 * *"
```

### Configuration

```yaml
schedule:
  workflow: my-workflow
  cron: "0 * * * *"
  timezone: "America/New_York"
  
  inputs:
    param_1: "default_value"
  
  error_handling:
    retry_attempts: 3
    backoff: exponential
  
  notifications:
    on_failure: slack
    on_success: slack
    
  enabled: true
```

## Manual Triggers

### CLI

```bash
# Run with default inputs
xom-cli workflow trigger --workflow my-workflow

# Run with custom inputs
xom-cli workflow trigger --workflow my-workflow \
  --input '{"param_1": "value"}'

# Run with input file
xom-cli workflow trigger --workflow my-workflow \
  --input-file inputs.json
```

### API

```bash
curl -X POST https://api.workflow.io/workflows/my-workflow/trigger \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "param_1": "value",
    "param_2": "another_value"
  }'
```

### Response

```json
{
  "workflow_run_id": "run_12345",
  "status": "pending",
  "workflow": "my-workflow",
  "started_at": "2026-02-27T14:30:00Z"
}
```

## Environment Variables

### Configuration

```bash
# GitHub
export GITHUB_WEBHOOK_SECRET="..."
export GITHUB_TOKEN="ghp_..."

# Slack
export SLACK_SIGNING_SECRET="..."
export SLACK_BOT_TOKEN="xoxb-..."
export SLACK_WEBHOOK_URL="https://hooks.slack.com/..."

# PagerDuty
export PAGERDUTY_TOKEN="..."
export PAGERDUTY_WEBHOOK_SECRET="..."

# Workflow Configuration
export WORKFLOW_TIMEOUT=600
export WORKFLOW_MAX_RETRIES=3
```

### Reference in Workflows

```yaml
triggers:
  - type: github-webhook
    secret: ${{ env.GITHUB_WEBHOOK_SECRET }}

steps:
  - id: post-comment
    input:
      token: ${{ env.GITHUB_TOKEN }}
```

## Advanced Filtering

### Conditional Triggers

```yaml
# Deploy only if author has permission
trigger:
  event: pull_request
  condition: |
    and(
      equals(action, "opened"),
      has_permission(author, "admin")
    )

# Trigger on specific file changes
trigger:
  event: push
  path_filter: |
    or(
      "src/**",
      "Dockerfile",
      ".github/**"
    )
```

### Custom Conditions

```yaml
trigger:
  event: pull_request
  custom_condition: |
    # Only review PRs with 3+ files changed
    pr.files_changed.length >= 3 AND
    # AND have description
    pr.body != null AND
    # AND are not drafts
    !pr.draft
```

## Security

### Webhook Verification

```yaml
security:
  verify_signature: true
  signature_header: "X-Hub-Signature-256"
  
  # GitHub uses SHA256 HMAC
  algorithm: sha256
```

### Rate Limiting

```yaml
rate_limits:
  github_webhook: 1000_per_hour
  slack_commands: 100_per_minute
  manual_trigger: 500_per_hour
```

### IP Whitelisting

```yaml
github:
  allowed_ips:
    - 140.82.112.0/20
    - 143.55.64.0/20

slack:
  allowed_ips:
    - 69.46.88.68/32
    - 69.46.88.68/32
```

## Troubleshooting

### Webhook Not Firing

1. Check webhook logs: `xom-cli webhook logs --workflow my-workflow`
2. Verify secret is set correctly
3. Check repository webhook configuration
4. Verify CRON syntax for schedules

### Test Webhook

```bash
# Test GitHub webhook
curl -X POST https://api.workflow.io/github/my-workflow \
  -H "X-Hub-Signature-256: sha256=..." \
  -d @payload.json

# Test Slack command
curl -X POST https://api.workflow.io/slack/my-command \
  -H "X-Slack-Request-Timestamp: ..." \
  -H "X-Slack-Signature: ..." \
  -d "text=/my-command%20argument"
```

### Debug Payload

Enable payload logging:
```bash
xom-cli webhook configure --workflow my-workflow --log-payloads debug
```

## See Also

- [workflow-development.md](workflow-development.md) — Workflow creation guide
- [debugging-workflows.md](debugging-workflows.md) — Debugging & monitoring
- [deployment.md](deployment.md) — Production deployment
