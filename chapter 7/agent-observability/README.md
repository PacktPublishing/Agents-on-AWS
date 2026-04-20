# Chapter 7: Observability and Governance

Companion code for Chapter 7 of the book.

## Included Examples

| File | Topic | Key Services |
|---|---|---|
| [`observability.ipynb`](observability.ipynb) | Agent tracing and monitoring | OpenTelemetry, Jaeger, Langfuse, LangSmith, CloudWatch |
| [`governance.ipynb`](governance.ipynb) | Content filtering and tool-call policies | Bedrock Guardrails, Cedar / AgentCore Policy |
| [`agentcore_agent.py`](agentcore_agent.py) | Standalone agent script for ADOT instrumentation | Bedrock, ADOT, CloudWatch GenAI Observability |

## Observability (`observability.ipynb`)

Walks through five ways to trace a Strands agent:

1. **Console exporter** — print spans to stdout, no setup required
2. **Jaeger** — local Docker container with a visual trace UI
3. **Langfuse** — open-source LLM observability platform (cloud or self-hosted)
4. **LangSmith** — LangChain's observability and evaluation platform
5. **AgentCore / CloudWatch** — send traces to CloudWatch GenAI Observability via ADOT

All approaches use OpenTelemetry under the hood. Strands emits OTel spans for every model call, tool invocation, and agent cycle automatically.

### Jaeger Quick Start

```bash
docker run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

Then open http://localhost:16686 and select the `strands-agents` service.

## Governance (`governance.ipynb`)

Demonstrates two governance mechanisms:

1. **Bedrock Guardrails** — content filtering on model inputs and outputs (what the agent *says*). Creates a guardrail with content filters, denied topics, and PII detection, then attaches it to a Strands agent.
2. **Cedar Policies via AgentCore Policy** — deterministic control over tool calls (what the agent *does*). Shows the gap guardrails leave and points to Cedar policy patterns for closing it.

## Prerequisites

- AWS account with credentials configured (`aws sts get-caller-identity`)
- Amazon Bedrock model access enabled for Claude (Anthropic) models
- Python 3.12+ with `strands-agents`, `strands-agents-tools`, `boto3`
- Docker (for Jaeger)
- Langfuse / LangSmith accounts (optional, for those sections)

## Cost

Demo-level usage. Costs are minimal if you clean up after testing. Each notebook includes cleanup cells at the end.
