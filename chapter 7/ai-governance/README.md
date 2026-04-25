# AI Governance

Companion code for the governance section of Chapter 7 of *Agents on AWS*.

This folder covers how to enforce policies on what your agent is allowed to say and do. More notebooks will be added here as the chapter expands.

## Notebooks

| Notebook | What It Covers | Key Services |
|----------|---------------|--------------|
| [`governance.ipynb`](governance.ipynb) | Content filtering and tool-call policies | Bedrock Guardrails, Cedar / AgentCore Policy |

## Coming Soon

| Notebook | What It Will Cover |
|----------|--------------------|
| `agentcore_policy.ipynb` | Deterministic tool-call control with Cedar policies via AgentCore Policy |

---

## governance.ipynb

Demonstrates two complementary governance mechanisms:

### 1. Bedrock Guardrails — what the agent *says*

Creates a guardrail programmatically with three policies:

| Policy | What it does |
|--------|-------------|
| Content filters | Blocks hate, violence, sexual, misconduct, and insult content at HIGH strength |
| Denied topics | Blocks legal advice requests |
| PII detection | Blocks SSN and credit card numbers; anonymizes email addresses |

The guardrail is attached to a `BedrockModel` and evaluates every model input and output automatically. When a guardrail fires, `response.stop_reason` is `guardrail_intervened`.

### 2. The gap guardrails leave — what the agent *does*

Shows that guardrails do not intercept tool calls. An agent with a `process_refund` tool will still call it with a $50,000 amount even when a guardrail is active, because the guardrail only sees text, not tool-call decisions.

This gap is what AgentCore Policy with Cedar rules is designed to close. See the [AgentCore Policy documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/policy-common-patterns.html) and the [quickstart](https://aws.github.io/bedrock-agentcore-starter-toolkit/user-guide/policy/quickstart.html).

---

## Prerequisites

- Python 3.10+
- AWS credentials configured (`aws configure`)
- Amazon Bedrock model access enabled (Claude Sonnet)
- IAM permissions: `bedrock:CreateGuardrail`, `bedrock:DeleteGuardrail`, `bedrock:InvokeModel`

## Setup

```bash
pip install strands-agents strands-agents-tools boto3
jupyter notebook governance.ipynb
```

## Cost

Minimal. Bedrock Guardrails charges per 1,000 text units processed. Each notebook includes a cleanup cell to delete the guardrail when you are done.
