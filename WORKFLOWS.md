# WORKFLOWS.md — Complete Reference

Detailed reference for all 8 production workflows included in this repository.

## Engineering Standards (Applied to All Workflows)

| Standard | Rule |
|----------|------|
| **Hooks** | Pre/post-invoke deterministic checks on every LLM step |
| **MCP Cap** | Max 10 active MCP tools per workflow run |
| **Model Routing** | Haiku (simple) / Sonnet (code) / Opus (complex) |
| **Pre-Merge Gates** | Compile + 80% coverage + lint + security scan — all must pass |

### Model Names (current)
- `claude-haiku-4-5` — Fast, cheap (~$0.01/task)
- `claude-sonnet-4-5` — Balanced, default for code (~$0.05/task)
- `claude-opus-4-5` — Complex reasoning (~$0.15/task)

### Coverage Standard
Minimum unit test coverage is **80%** (raised from legacy 70%). The pre-merge gate enforces this deterministically.

---

## 1. Code Review Workflow

**File:** `workflows/code-review/workflow.yaml`

### Purpose
Automated code review using Claude for architectural review, security analysis, and quality assessment on GitHub pull requests.

### Inputs
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `repo` | string | yes | GitHub repository (owner/name) |
| `pr_number` | integer | yes | Pull request number |
| `review_type` | enum | no | `full`, `security`, `performance` (default: `full`) |
| `auto_approve` | boolean | no | Auto-approve if quality ≥ threshold |

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| `review_result` | object | {score, issues, suggestions, security_findings} |
| `approval_status` | enum | `approved`, `requested_changes`, `commented` |
| `pr_comment_id` | string | GitHub comment ID |
| `auto_approved` | boolean | Whether auto-approval was granted |

### Steps
1. **fetch-pr** — Retrieve PR details, diff, metadata
2. **analyze-code** — Claude Opus analyzes code for quality, architecture, patterns
3. **security-review** — Dedicated security analysis (vulnerabilities, secrets, permissions)
4. **performance-check** — Performance implications, optimization opportunities
5. **aggregate-findings** — Combine all reviews
6. **post-comment** — Post review as GitHub comment
7. **conditional-approve** — Auto-approve if score ≥ 85% and no blocking issues
8. **notify-team** — Slack notification with summary

### Agents
- **claude-opus** — Architectural review, main analysis
- **claude-sonnet** — Security and performance assessment
- **notification-bot** — Slack/GitHub integration

### Triggers
- GitHub PR opened, updated
- Manual trigger via CLI
- Scheduled daily review for open PRs

### Error Handling
```yaml
retry_on: [network_error, api_rate_limit]
max_retries: 3
backoff: exponential
on_failure:
  - log_error
  - post_comment: "Review failed, please retry"
  - escalate_to: human_reviewer
```

### Success Criteria
- Review posted within 5 minutes
- All analysis steps completed
- GitHub comment created

---

## 2. Feature Implementation Workflow

**File:** `workflows/feature-implementation/workflow.yaml`

### Purpose
End-to-end feature development: specification → design → implementation → testing → integration.

### Inputs
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `feature_spec` | string | yes | Feature description/specification |
| `repo` | string | yes | Target GitHub repository |
| `branch_base` | string | no | Base branch (default: `main`) |
| `test_coverage_target` | float | no | Target test coverage % (default: 80) |

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| `pr_url` | string | Created pull request URL |
| `feature_branch` | string | Feature branch name |
| `test_results` | object | Coverage, pass/fail counts |
| `implementation_summary` | string | What was implemented |

### Steps
1. **parse-spec** — Claude parses feature specification
2. **create-branch** — Create feature branch in repo
3. **design-architecture** — Design system architecture and module structure
4. **implement-code** — Generate implementation code
5. **add-tests** — Generate comprehensive test suite
6. **validate-tests** — Run tests, verify coverage
7. **create-pr** — Create pull request with description
8. **post-review** — Tag code reviewers, add labels
9. **notify-team** — Slack notification with PR link

### Agents
- **claude-opus** — Architecture design, complex logic
- **claude-sonnet** — Code generation, testing
- **devops-bot** — Git operations, CI/CD

### Triggers
- Manual trigger from Slack command
- GitHub issue labeled `feature-request`
- Scheduled sprint planning

### Error Handling
```yaml
on_step_failure:
  implementation: "fallback to simpler design"
  tests: "manual review required"
  pr: "save draft, notify team"
max_retries: 2
escalate_after: 2_failures
```

### Success Criteria
- PR created and opened
- Tests passing with ≥80% coverage
- Team notified within 10 minutes

---

## 3. Automated Deployment Workflow

**File:** `workflows/automated-deployment/workflow.yaml`

### Purpose
Build, test, scan, and deploy applications through staging to production.

### Inputs
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `repo` | string | yes | Repository to deploy |
| `version` | string | yes | Version/tag to deploy |
| `target_env` | enum | yes | `staging`, `production` |
| `require_approval` | boolean | no | Require human approval for prod (default: true) |

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| `deployment_id` | string | Unique deployment identifier |
| `build_status` | enum | `success`, `failed` |
| `security_scan_results` | object | Vulnerabilities, compliance check |
| `deployment_status` | enum | `pending`, `in_progress`, `completed`, `failed` |
| `rollback_available` | boolean | Can this deployment be rolled back |

### Steps
1. **checkout-code** — Clone repo at specified version
2. **build-application** — Compile/package application
3. **run-tests** — Unit, integration tests
4. **security-scan** — SAST, dependencies, container scan
5. **create-artifacts** — Build Docker image, store artifacts
6. **deploy-to-staging** — Deploy to staging environment
7. **run-smoke-tests** — Smoke tests in staging
8. **approval-gate** — Request human approval (if prod)
9. **deploy-to-production** — Blue-green deployment to prod
10. **health-check** — Verify deployment health
11. **post-deployment** — Update status page, notify team

### Agents
- **devops-bot** — Orchestration, CI/CD, deployments
- **security-scanner** — Security scanning, compliance
- **monitoring-bot** — Health checks, alerts

### Triggers
- GitHub release published
- Manual CLI trigger
- Scheduled daily deployment of `main` to staging

### Error Handling
```yaml
steps:
  security_scan:
    on_critical_vuln: stop
    on_warning: warn_and_continue
  deploy_production:
    on_failure: automatic_rollback
    notify: [team_slack, pagerduty]
max_retries: 2
```

### Success Criteria
- Build completes
- All tests pass
- No critical security issues
- Deployment reaches production
- Health checks pass

---

## 4. Research Pipeline Workflow

**File:** `workflows/research-pipeline/workflow.yaml`

### Purpose
Multi-agent research: collect → analyze → synthesize → report.

### Inputs
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `research_topic` | string | yes | Topic or question to research |
| `scope` | enum | no | `narrow`, `broad` (default: `broad`) |
| `sources_limit` | integer | no | Max sources to analyze (default: 50) |
| `output_format` | enum | no | `report`, `slides`, `summary` |

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| `research_report` | string | Markdown research report |
| `key_findings` | array | List of main findings |
| `sources_cited` | array | All sources with citations |
| `confidence_scores` | object | Confidence in each finding |

### Steps
1. **define-research-plan** — Claude designs research strategy
2. **search-sources** — Gather academic papers, articles, docs
3. **parallel-analysis** — Multiple agents analyze different sources
4. **synthesis** — Combine findings, identify patterns
5. **quality-check** — Verify citations, check for bias
6. **generate-report** — Format output (report/slides/summary)
7. **peer-review** — Optional human review
8. **publish-report** — Store in knowledge base or deliver

### Agents
- **claude-opus** — Research planning, synthesis
- **claude-sonnet** (parallel) — Source analysis
- **research-validator** — Fact-checking, citations

### Triggers
- Manual Slack command
- Scheduled weekly research on trending topics
- GitHub issue `research-request`

### Error Handling
```yaml
source_analysis:
  timeout: 30s_per_source
  on_error: skip_source
  min_sources: 5
synthesis:
  on_conflict: annotate_disagreement
  confidence_threshold: 0.7
```

### Success Criteria
- Research report generated
- ≥5 sources analyzed
- All findings have confidence score
- Report formatted and delivered

---

## 5. Incident Response Workflow

**File:** `workflows/incident-response/workflow.yaml`

### Purpose
Automated incident triage, diagnosis, and mitigation workflows.

### Inputs
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `incident_alert` | object | yes | Alert data from monitoring system |
| `severity` | enum | yes | `critical`, `high`, `medium`, `low` |
| `affected_service` | string | yes | Service name |
| `runbook_key` | string | no | Associated runbook identifier |

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| `incident_id` | string | Unique incident identifier |
| `initial_assessment` | object | Severity, impact estimate, root cause hypothesis |
| `actions_taken` | array | List of mitigation actions |
| `resolution_status` | enum | `resolved`, `mitigated`, `escalated`, `needs_investigation` |
| `postmortem_url` | string | Link to postmortem document |

### Steps
1. **receive-alert** — Parse alert from monitoring system
2. **initial-triage** — Assess severity and impact
3. **pull-context** — Gather recent logs, metrics, related alerts
4. **run-diagnostics** — Execute diagnostic commands
5. **analyze-root-cause** — Claude analyzes symptoms → root cause
6. **determine-mitigation** — Claude suggests remediation steps
7. **execute-runbook** — Run automated remediation (if available)
8. **escalate-if-needed** — Page on-call engineer if critical
9. **communicate** — Status page update, team notification
10. **monitor-recovery** — Verify metrics return to normal
11. **start-postmortem** — Create postmortem document

### Agents
- **incident-coordinator** — Orchestration, escalation
- **claude-opus** — Root cause analysis, decision making
- **devops-bot** — Runbook execution, diagnostics

### Triggers
- PagerDuty alert
- Monitoring system webhook
- Manual Slack command

### Error Handling
```yaml
diagnostics:
  timeout: 10s
  on_error: skip
escalation:
  critical: immediate
  high: 5min_if_unresolved
  medium: 15min_if_unresolved
communication:
  always_notify: [slack_oncall, status_page]
```

### Success Criteria
- Alert processed within 1 minute
- Root cause identified or escalated
- Runbook executed if applicable
- Team notified

---

## 6. Data Analysis Workflow

**File:** `workflows/data-analysis/workflow.yaml`

### Purpose
Ingest, analyze, and report on data: ETL → exploration → visualization → insight generation.

### Inputs
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `data_source` | string | yes | Data source (file, API, database) |
| `analysis_type` | enum | yes | `exploratory`, `statistical`, `predictive` |
| `output_format` | enum | no | `report`, `dashboard`, `csv` |
| `sample_size` | integer | no | Rows to analyze (default: all) |

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| `analysis_report` | string | Markdown analysis report |
| `visualizations` | array | Chart/graph files |
| `statistics` | object | Summary statistics |
| `insights` | array | Key insights discovered |

### Steps
1. **fetch-data** — Retrieve from source
2. **validate-data** — Check integrity, completeness
3. **clean-data** — Handle missing values, outliers
4. **exploratory-analysis** — Distribution, patterns, correlations
5. **statistical-analysis** — Hypothesis testing, significance
6. **generate-visualizations** — Charts and graphs
7. **synthesize-insights** — Claude extracts meaningful insights
8. **generate-report** — Format findings
9. **save-results** — Store in data warehouse or S3

### Agents
- **claude-opus** — Insight synthesis, interpretation
- **data-processing-bot** — ETL, cleaning, validation
- **visualization-bot** — Chart generation

### Triggers
- Scheduled daily/weekly analysis
- Manual upload/API call
- GitHub push to `data/` directory

### Error Handling
```yaml
data_fetch:
  retry: 3
  timeout: 60s
data_cleaning:
  on_too_many_missing: escalate
  outlier_handling: flag_and_report
analysis:
  min_data_points: 10
  on_insufficient_data: report_limitation
```

### Success Criteria
- Data fetched and validated
- Analysis completed
- Insights extracted
- Report generated

---

## 7. Multi-Agent Coordination Workflow

**File:** `workflows/multi-agent-coordination/workflow.yaml`

### Purpose
Orchestrate complex tasks across multiple Claude agents with different specializations.

### Inputs
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task` | string | yes | Main task description |
| `agents` | array | no | Specific agents to use (auto-select if not provided) |
| `coordination_mode` | enum | no | `sequential`, `parallel`, `supervisor` |
| `timeout` | integer | no | Max execution time in seconds |

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| `final_result` | string | Combined result from all agents |
| `agent_outputs` | object | Individual results by agent |
| `execution_time` | number | Total execution time (seconds) |
| `quality_score` | float | Combined quality assessment |

### Steps
1. **parse-task** — Understand task requirements
2. **agent-assignment** — Select and configure agents
3. **task-decomposition** — Break into sub-tasks for each agent
4. **kickoff-agents** — Launch agents (parallel or sequential)
5. **monitor-execution** — Track progress, handle timeouts
6. **collect-results** — Gather outputs as agents complete
7. **conflict-resolution** — Reconcile disagreements
8. **synthesis** — Combine into final result
9. **quality-assurance** — Verify completeness

### Agents
- **orchestrator** — Coordination and task management
- **claude-opus** (multiple instances) — Specialized reasoning
- **claude-sonnet** (multiple instances) — Execution

### Triggers
- Manual task submission via CLI or API
- Scheduled complex analysis
- Escalation from other workflows

### Error Handling
```yaml
agent_failure:
  retry: 1
  timeout_per_agent: 5min
  on_timeout: escalate_to_supervisor
  on_conflict: human_review
```

### Success Criteria
- All agents complete or timeout gracefully
- Final result synthesized
- Quality threshold met

---

## 8. Knowledge Base Generation Workflow

**File:** `workflows/kb-generation/workflow.yaml`

### Purpose
Scan documents, code, and issues to auto-generate and update a knowledge base.

### Inputs
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source_type` | enum | yes | `docs`, `code`, `issues`, `all` |
| `repo` | string | yes | Repository to scan |
| `kb_path` | string | no | Knowledge base storage location |
| `auto_publish` | boolean | no | Auto-publish generated KB (default: false) |

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| `kb_articles` | array | Generated KB articles |
| `article_count` | integer | Number of articles created/updated |
| `coverage_report` | string | What areas are documented |
| `publish_status` | enum | `draft`, `staged`, `published` |

### Steps
1. **scan-sources** — Find docs, code, issues in repo
2. **extract-content** — Parse documentation and code
3. **identify-topics** — Claude identifies KB topic areas
4. **generate-articles** — Create KB articles for each topic
5. **add-examples** — Extract code examples
6. **cross-reference** — Link related articles
7. **validate-links** — Ensure all links work
8. **stage-kb** — Store draft KB articles
9. **preview-review** — Human review before publish (optional)
10. **publish-kb** — Publish to knowledge base system

### Agents
- **claude-opus** — Article generation, content synthesis
- **code-analyzer** — Extract examples from codebase
- **kb-manager** — Organization, publishing

### Triggers
- Scheduled weekly regeneration
- Manual trigger after major documentation update
- GitHub push to `docs/` directory

### Error Handling
```yaml
content_extraction:
  timeout: 5s_per_file
  on_error: skip_file
article_generation:
  retry: 1
  quality_threshold: 0.8
publishing:
  require_approval: true
  fallback: draft_status
```

### Success Criteria
- Sources scanned
- Articles generated with examples
- Cross-references complete
- KB staged or published

---

## Common Patterns

### Error Handling Pattern
```yaml
steps:
  - name: operation
    error_handling:
      retry_attempts: 3
      backoff: exponential
      on_failure: [log, notify, fallback]
```

### Multi-Agent Hand-off
```yaml
steps:
  - agent: opus
    task: analyze
  - agent: sonnet
    task: implement
    input: ${{ steps.analyze.output }}
```

### Parallel Execution
```yaml
parallel:
  - agent: sonnet
    task: task-a
  - agent: sonnet
    task: task-b
combine: merge
```

### Conditional Branching
```yaml
if: ${{ steps.check.output.severity == 'critical' }}
then: escalate-to-human
else: auto-remediate
```

---

## Monitoring & Observability

All workflows emit:
- **Step-level logs** — Input, output, duration
- **Error traces** — Stack traces, error context
- **Metrics** — Success rate, latency, agent utilization
- **Events** — Workflow started, step completed, failed

View via:
```bash
xom-cli workflow logs --workflow-run <run-id> --follow
xom-cli workflow metrics --workflow <name>
```

---

## Next Steps

1. **Customize workflows** for your environment
2. **Configure triggers** (webhooks, schedules) in `hooks/`
3. **Set up monitoring** and alerting
4. **Run test executions** before production
5. **Document your custom workflows** using this template

See [docs/workflow-development.md](docs/workflow-development.md) for detailed customization guide.
