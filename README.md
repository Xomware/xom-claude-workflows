# xom-claude-workflows

A comprehensive, production-ready repository of Claude-powered workflows for distributed multi-agent automation, orchestration, and integration.

## Best Practices: The Four Pillars

All workflows in this repository implement four required patterns:

| Pillar | Rule | Why |
|--------|------|-----|
| **Hooks Framework** | Deterministic code before/after every LLM step | Zero-cost validation, model routing, rate limiting |
| **MCP Discipline** | Max 10 active MCP tools across all steps | Context hygiene, fewer hallucinations |
| **Model Routing** | Haiku → simple steps, Sonnet → code, Opus → complex | ~50% cost reduction |
| **Pre-Merge Gates** | Compile + 80% coverage + lint + security scan | Deterministic quality, high PR approval rate |

See [`docs/workflow-development.md`](docs/workflow-development.md) for implementation details.

---

## Overview

This repository contains:
- **8 production workflows** — ready-to-deploy patterns for code review, feature implementation, deployment, research, incident response, data analysis, multi-agent coordination, and knowledge base generation
- **Workflow templates** — reusable patterns (sequential, parallel, conditional) for custom orchestration
- **Trigger/hook definitions** — GitHub webhooks, Slack integrations, and scheduled workflows
- **Error handling & retry logic** — production-grade resilience patterns
- **Multi-agent orchestration patterns** — strategies for coordinating multiple Claude instances
- **Complete documentation** — development guides, debugging, and deployment instructions

## Quick Start

### 1. Explore Workflows
```bash
ls -la workflows/
```

Each workflow includes:
- `workflow.yaml` — workflow definition (steps, inputs, outputs, error handling)
- `triggers/` — webhook and schedule configurations
- `agents/` — agent assignments and routing

### 2. Use a Template
```bash
cp templates/sequential-workflow.yaml my-workflow.yaml
# Edit and customize...
```

### 3. Configure Hooks
```bash
cat hooks/github-webhooks.yaml
cat hooks/slack-webhooks.yaml
cat hooks/schedule-definitions.yaml
```

## Workflows

| Workflow | Purpose | Triggers | Multi-Agent |
|----------|---------|----------|-------------|
| **code-review** | Automated code review & approval | GitHub push, PR | Yes |
| **feature-implementation** | Generate & implement features | Manual, scheduled | Yes |
| **automated-deployment** | Build, test, deploy pipeline | GitHub release, schedule | Yes |
| **research-pipeline** | Multi-agent research & synthesis | Manual, scheduled | Yes |
| **incident-response** | Alert → diagnosis → mitigation | PagerDuty, Slack | Yes |
| **data-analysis** | Data ingestion, processing, reporting | Scheduled, API | Yes |
| **multi-agent-coordination** | Agent-to-agent task delegation | Manual | Yes |
| **kb-generation** | Document scanning & KB synthesis | Scheduled, manual | Yes |

## Templates

### Sequential
- Tasks execute one after another
- Passes output of each step to the next
- Best for: linear pipelines, DAGs

### Parallel
- Multiple tasks run concurrently
- Results aggregated at the end
- Best for: independent operations, performance

### Conditional
- Tasks execute based on previous results
- Branching logic, error recovery
- Best for: complex workflows with decisions

## Documentation

- **[workflow-development.md](docs/workflow-development.md)** — How to create custom workflows
- **[trigger-configuration.md](docs/trigger-configuration.md)** — Configuring webhooks, schedules, API triggers
- **[debugging-workflows.md](docs/debugging-workflows.md)** — Monitoring, logging, troubleshooting
- **[deployment.md](docs/deployment.md)** — Deploying workflows to production
- **[WORKFLOWS.md](WORKFLOWS.md)** — Detailed reference for each workflow

## Architecture

```
Trigger (GitHub, Slack, Schedule, Manual)
    ↓
Workflow Orchestrator
    ↓
Agent Assignment & Routing
    ↓
Parallel/Sequential Execution
    ↓
Error Handling & Retry Logic
    ↓
Output & Callback
```

## Key Concepts

### Agent Assignment
Each workflow step can assign work to specific Claude instances:
```yaml
steps:
  - name: analyze
    agent: claude-opus  # architect/reasoning
  - name: implement
    agent: claude-sonnet  # coding/execution
```

### Error Handling
```yaml
error_handling:
  retry_attempts: 3
  backoff: exponential
  on_failure: [notify, log, fallback_agent]
```

### Multi-Agent Coordination
```yaml
coordination:
  strategy: hand-off  # hand-off, parallel, supervisor
  timeout: 300s
  escalation: human-review
```

## Usage Examples

### Run a Workflow
```bash
# Manual trigger
xom-cli workflow trigger --workflow code-review --input "{repo: 'my-repo', pr: 123}"

# Or use the workflow directly
python scripts/run-workflow.py --workflow code-review --config my-config.yaml
```

### Monitor Execution
```bash
xom-cli workflow status --workflow-run <run-id>
xom-cli workflow logs --workflow-run <run-id> --follow
```

### Custom Workflow
1. Copy a template: `cp templates/sequential-workflow.yaml my-workflow.yaml`
2. Define steps, agents, and triggers
3. Test locally: `xom-cli workflow validate my-workflow.yaml`
4. Deploy: `xom-cli workflow deploy my-workflow.yaml`

## Configuration

### Environment Variables
```bash
WORKFLOW_TIMEOUT=600
AGENT_MODEL=claude-opus
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
GITHUB_TOKEN=...
```

### Secrets Management
Store sensitive data in:
- `.env.local` (development)
- GitHub Secrets (production)
- Vault integration (enterprise)

## Contributing

1. Create a new workflow in `workflows/`
2. Add documentation in `docs/`
3. Update `WORKFLOWS.md` with details
4. Test with `xom-cli workflow validate`
5. Submit PR with testing evidence

## License

MIT License — See [LICENSE](LICENSE) for details

## Support

- **Issues**: [GitHub Issues](https://github.com/Xomware/xom-claude-workflows/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Xomware/xom-claude-workflows/discussions)
- **Documentation**: See `docs/` directory

---

Built with ❤️ using Claude, multi-agent orchestration, and workflow automation.
