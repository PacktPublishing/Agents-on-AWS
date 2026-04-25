# Chapter 4: Advanced Agent Architecture Patterns

Code examples from Chapter 4 of *Agents on AWS*.

## Notebooks

| Notebook | What It Covers |
|----------|---------------|
| `01_supervisor_worker.ipynb` | Supervisor-worker pattern — market research assistant with news, financial, and sentiment worker agents coordinated by a supervisor |
| `02_agent_as_tool.ipynb` | Agent-as-tool pattern — tutoring assistant where a teacher agent delegates to specialist tutors (math, writing, science) |
| `03_graph_pattern.ipynb` | Graph pattern — e-commerce order processing with explicit, auditable routing through risk analysis, fraud detection, inventory, shipping, and refund nodes |
| `04_swarm_pattern.ipynb` | Swarm pattern — game level design where agents (level designer, game designer, narrative designer, difficulty balancer) hand off control to each other dynamically |

## Setup

```bash
pip install -r requirements.txt
```

Notebook `01_supervisor_worker.ipynb` requires the following things - 
1. A **Tavily API key** for web search. Get one free at https://www.tavily.com/

2. Optionally uses an **Alpha Vantage API key** for financial data. If not set, it falls back to `yfinance` (free, no key needed). Get one at https://www.alphavantage.co/support/#api-key

## Pattern Summary

| Pattern | Routing | Best For |
|---------|---------|----------|
| Supervisor-Worker | Central supervisor delegates to workers | Parallel research, aggregating results from specialists |
| Agent-as-Tool | Orchestrator calls agents like functions | Simple delegation where the orchestrator always stays in control |
| Graph | Explicit conditional edges in code | Fixed procedures with auditable paths (compliance, order processing) |
| Swarm | Agents hand off to each other | Emergent workflows where the path can't be predicted upfront |

## Prerequisites

- Python 3.10+
- AWS account with Bedrock access
