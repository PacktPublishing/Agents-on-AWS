# Chapter 6: Deploying Agents to Production

This chapter covers deploying Strands agents to production environments on AWS: AgentCore Runtime, ECS Fargate, Lambda, and a multi-agent system combining MCP and A2A on AgentCore.

## Examples

| Folder | Deployment Target | Description |
|---|---|---|
| `agentcore/` | Amazon Bedrock AgentCore | Document analysis agent (contract clause extraction) deployed as a managed runtime |
| `ecs-deployment/` | Amazon ECS (Fargate) | Hospital surgical scheduling agent deployed as a containerized service behind an ALB |
| `lambda-deployment/` | AWS Lambda | Document analysis agent deployed as a serverless function behind API Gateway |
| `multiagent/` | AgentCore (multi-agent) | Finance orchestrator delegating to a stock sub-agent via A2A, with MCP tools for real-time stock prices |

## Prerequisites

- Python 3.10+
- AWS account with access to Amazon Bedrock and AgentCore
- AWS credentials configured
- Docker (for ECS and Lambda deployments)
- AWS SAM CLI (for Lambda deployment) — install from https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

## Quick Start

### AgentCore Deployment

```bash
cd agentcore
pip install -r requirements.txt
pip install bedrock-agentcore-starter-toolkit

# Test locally
python agent.py

# Deploy via the Starter Toolkit (see agentcore_runtime_deploy.ipynb for the full walkthrough)
```

Open `agentcore_runtime_deploy.ipynb` and run all cells. The notebook uses the `Runtime` class from `bedrock-agentcore-starter-toolkit` to configure, build, and launch the agent — no CLI required.

### ECS Deployment

```bash
cd ecs-deployment
# Follow the README inside for full setup
bash deploy.sh
```

### Lambda Deployment

```bash
cd lambda-deployment
# Follow the README inside for full setup
bash deploy.sh
```

### Multi-Agent (Finance Orchestrator)

```bash
cd multiagent
pip install -r requirements.txt

# Terminal 1: Start MCP server first
python stock_mcp_server.py

# Terminal 2: Start Stock A2A agent (connects to MCP server on port 8000)
python stock_a2a_agent.py

# Terminal 3: Start orchestrator (listens on port 9000, delegates to stock agent on port 9001)
python orchestrator.py
```

For AgentCore deployment, follow the step-by-step instructions in `multiagent/README.md`.

## Notes

- The AgentCore, ECS, and Lambda examples all use `us.anthropic.claude-sonnet-4-20250514-v1:0` — this model is available by default in Bedrock
- The `multiagent/` example requires Cognito OAuth setup for AgentCore deployment — see `setup_cognito.sh` in the chapter 6 root folder
