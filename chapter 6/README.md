# Chapter 6: Deploying Agents to Production

This chapter covers deploying Strands agents to production environments on AWS using three approaches: AgentCore Runtime, ECS, and Lambda.

## Examples

| Folder | Deployment Target | Description |
|---|---|---|
| `agentcore/` | Amazon Bedrock AgentCore | Contract analysis agent deployed as a managed runtime |
| `ecs-deployment/` | Amazon ECS (Fargate) | Agent deployed as a containerized service |
| `lambda-deployment/` | AWS Lambda | Agent deployed as a serverless function |
| `multiagent/` | AgentCore (multi-agent) | Stock price agent with MCP tools + A2A orchestration |

## Prerequisites

- Python 3.10+
- AWS account with access to Amazon Bedrock and AgentCore
- AWS credentials configured
- Docker (for ECS deployment)
- AWS SAM CLI (for Lambda deployment): `pip install aws-sam-cli`

## Quick Start

### AgentCore Deployment

```bash
cd agentcore
pip install -r requirements.txt
pip install bedrock-agentcore-starter-toolkit

# Test locally
python agent.py

# Deploy to AgentCore
agentcore configure -e agent.py
agentcore launch
```

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

### Multi-Agent (Stock Price)

```bash
cd multiagent
pip install -r requirements.txt

# Start MCP server
python stock_mcp_server.py &

# Start A2A agent
python stock_a2a_agent.py &

# Run orchestrator
python orchestrator.py
```

## Notes

- The AgentCore example uses `claude-sonnet-4` — ensure this model is enabled in Bedrock Model Access
- If you get `ResourceNotFoundException: Legacy model`, switch to `us.amazon.nova-lite-v1:0` in `agent.py`
- AgentCore deployments require Cognito OAuth setup — see `setup_cognito.sh`
