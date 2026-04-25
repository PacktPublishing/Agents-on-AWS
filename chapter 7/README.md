# Chapter 7: Evaluation, Observability, and Governance

Code examples from Chapter 7 of *Agents on AWS*.

This chapter covers production-readiness for AI agents — how to measure how well your agent is performing, monitor what it is doing, and enforce policies on what it is allowed to do.

## Structure

```
chapter 7/
├── agent-evaluation/           # End-to-end agent evaluation
│   ├── end_to_end_eval.ipynb       # Full evaluation lifecycle notebook
│   ├── agent_app.py                # Travel assistant agent (deployed to AgentCore)
│   ├── travel_quality_metric.json  # Custom LLM-as-judge evaluator config
│   └── requirements.txt
│
├── agent-observability/        # Tracing and monitoring
│   ├── observability.ipynb         # 5 ways to trace a Strands agent
│   ├── agentcore_agent.py          # Agent script for ADOT / CloudWatch instrumentation
│   └── README.md
│
└── ai-governance/              # Policies and guardrails
    ├── governance.ipynb            # Bedrock Guardrails and AgentCore Policy
    └── README.md
```

---

## Part 1: Evaluation (`agent-evaluation/`)

### end_to_end_eval.ipynb

Full evaluation lifecycle in a single notebook:

| Step | What happens |
|------|-------------|
| 1 | Deploy a travel assistant agent to AgentCore Runtime via CodeBuild |
| 2 | Create a custom LLM-as-judge evaluator (5-point scale) |
| 3 | Invoke the agent with in-scope and out-of-scope prompts |
| 4 | Run built-in evaluators: GoalSuccessRate, Correctness, Helpfulness |
| 5 | Run the custom evaluator — verify out-of-scope detection |
| 6 | Print a summary score table and save results to JSON |

**Quick start:**
```bash
cd agent-evaluation
pip install -r requirements.txt
jupyter notebook end_to_end_eval.ipynb
```

Run all cells top to bottom. First deployment takes ~10 minutes (CodeBuild).

**Expected results:**
- In-scope prompts (flights, hotels, weather) → **Good / Very Good**
- Out-of-scope prompt (Python scripting) → **Very Poor** on the custom evaluator

---

## Part 2: Observability (`agent-observability/`)

### observability.ipynb

Walks through 5 ways to trace a Strands agent using OpenTelemetry:

| Approach | What you get |
|----------|-------------|
| Console exporter | Print spans to stdout — no setup required |
| Jaeger | Local Docker container with a visual trace UI |
| Langfuse | Open-source LLM observability platform |
| LangSmith | LangChain's observability and evaluation platform |
| AgentCore / CloudWatch | Production traces via ADOT to CloudWatch GenAI Observability |

**Quick start:**
```bash
cd agent-observability
pip install 'strands-agents[otel]' strands-agents-tools boto3
jupyter notebook observability.ipynb
```

For Jaeger (optional):
```bash
docker run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 -p 4317:4317 -p 4318:4318 \
  jaegertracing/all-in-one:latest
# Open http://localhost:16686
```

---

## Part 3: Governance (`ai-governance/`)

### governance.ipynb

Demonstrates two complementary governance mechanisms:

| Mechanism | Controls |
|-----------|---------|
| Bedrock Guardrails | What the agent *says* — content filters, denied topics, PII detection |
| AgentCore Policy (Cedar) | What the agent *does* — deterministic tool-call control |

Also shows the gap between the two: guardrails filter text but do not intercept tool calls, which is exactly what Cedar policies are designed to address.

**Quick start:**
```bash
cd ai-governance
pip install strands-agents strands-agents-tools boto3
jupyter notebook governance.ipynb
```

More notebooks will be added to `ai-governance/` as the chapter expands (AgentCore Policy, audit logging, etc.).

---

## Prerequisites

- Python 3.10+
- AWS credentials configured (`aws configure`)
- Amazon Bedrock model access enabled (Claude Sonnet or Nova Lite)
- IAM permissions: `bedrock-agentcore:*`, `bedrock:*`, `ecr:*`, `codebuild:*`, `s3:*`, `logs:*`, `iam:CreateRole`
- Docker — optional, only needed for Jaeger in `observability.ipynb`
