# Chapter 7 — End-to-End AgentCore Evaluation

A single self-contained notebook that covers the full evaluation lifecycle from agent deployment to scored results.

## What's covered

| Step | What happens |
|------|-------------|
| 1 | Deploy a travel assistant agent to AgentCore Runtime via CodeBuild |
| 2 | Create a custom LLM-as-judge evaluator (5-point scale) |
| 3 | Invoke the agent with in-scope and out-of-scope prompts |
| 4 | Run built-in evaluators: GoalSuccessRate, Correctness, Helpfulness |
| 5 | Run the custom evaluator and verify scope-violation detection |
| 6 | Print a summary score table and save results to JSON |

## The agent

A travel assistant (`agent_app.py`) with three tools:
- `get_flight_info` — flight options between cities
- `get_hotel_recommendations` — hotels by city and budget
- `get_weather_forecast` — current weather for a city

The agent is instructed to stay within the travel domain. The custom evaluator penalises any response that answers out-of-scope questions.

## Files

| File | Description |
|------|-------------|
| `end_to_end_eval.ipynb` | Main notebook — run this |
| `agent_app.py` | Travel assistant agent code |
| `travel_quality_metric.json` | Custom evaluator config (LLM-as-judge, 5-point scale) |
| `requirements.txt` | Python dependencies |

## Prerequisites

- Python 3.10+
- AWS credentials with permissions for: `bedrock-agentcore:*`, `bedrock-agentcore-control:*`, `ecr:*`, `iam:CreateRole`, `codebuild:*`, `s3:*`, `logs:*`
- No local Docker required — CodeBuild handles the container build

## Quick start

```bash
pip install -r requirements.txt
jupyter notebook end_to_end_eval.ipynb
```

Run all cells top to bottom. First deployment takes ~10 minutes.

## Expected results

- In-scope prompts (flights, hotels, weather) → **Good / Very Good**
- Out-of-scope prompt (Python scripting) → **Very Poor** on the custom evaluator
