# Agent Observability

Companion code for the observability section of Chapter 7 of *Agents on AWS*.

## Notebooks and Files

| File | What It Covers | Key Services |
|------|---------------|--------------|
| [`observability.ipynb`](observability.ipynb) | 5 ways to trace a Strands agent | OpenTelemetry, Jaeger, Langfuse, LangSmith, CloudWatch |
| [`agentcore_agent.py`](agentcore_agent.py) | Standalone agent script for ADOT / CloudWatch instrumentation | Bedrock, ADOT, CloudWatch GenAI Observability |

---

## observability.ipynb

Walks through five tracing approaches, all built on OpenTelemetry. Strands emits OTel spans for every model call, tool invocation, and agent cycle automatically — you just choose where to send them.

| Approach | What you get | Setup required |
|----------|-------------|----------------|
| Console exporter | Spans printed to stdout | None |
| Jaeger | Visual waterfall trace UI on localhost | Docker |
| Langfuse | Open-source LLM observability (cloud or self-hosted) | Langfuse account |
| LangSmith | LangChain's observability and evaluation platform | LangSmith account |
| AgentCore / CloudWatch | Production traces via ADOT to CloudWatch GenAI Observability | AWS credentials, Transaction Search enabled |

### Quick Start

```bash
pip install 'strands-agents[otel]' strands-agents-tools boto3
jupyter notebook observability.ipynb
```

### Jaeger (optional)

```bash
docker run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 -p 4317:4317 -p 4318:4318 \
  jaegertracing/all-in-one:latest
# Open http://localhost:16686
```

---

## agentcore_agent.py

A standalone Python script used in the CloudWatch / ADOT section of `observability.ipynb`. It defines a simple customer account agent with two tools (`lookup_account`, `calculate_discount`) and is run via `opentelemetry-instrument` so ADOT can capture traces at the process level.

You do not need to run this file directly — the notebook handles it.

---

## Prerequisites

- Python 3.10+
- AWS credentials configured (`aws configure`)
- Amazon Bedrock model access enabled (Claude Sonnet)
- Docker — optional, only needed for the Jaeger section
- Langfuse account — optional, only needed for the Langfuse section
- LangSmith account — optional, only needed for the LangSmith section
- CloudWatch Transaction Search enabled — only needed for the AgentCore / CloudWatch section

## Cost

Minimal. Each section uses demo-level traffic. The CloudWatch section includes a cleanup cell to delete the log group when you are done.
