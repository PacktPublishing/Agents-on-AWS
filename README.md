# AI Agents on AWS

A collection of examples for building agentic AI applications using AWS services including Amazon Bedrock and AgentCore, using the Strands Agents SDK.

## Chapters

| Chapter | Topic | Key Concepts |
|---|---|---|
| [Chapter 1](chapter%201/) | Hello World Agents | First agent with Strands, LangGraph basics |
| [Chapter 2](chapter%202/) | Building Agents with Tools | `@tool` decorator, prebuilt tools, AWS integration |
| [Chapter 3](chapter%203/) | Agent Memory | Personalized memory with Strands + Mem0, session persistence with LangGraph + AgentCore Memory checkpointer |
| [Chapter 4](chapter%204/) | Advanced Agent Patterns | Supervisor-worker, agent-as-tool, graph-based routing, swarm |
| [Chapter 5](chapter%205/) | MCP and A2A Protocols | MCP server/client, Agent-to-Agent communication |
| [Chapter 6](chapter%206/) | Deploying Agents to Production | AgentCore Runtime, ECS, Lambda deployments |
| [Chapter 7](chapter%207/) | Evaluation, Observability, and Governance | LLM-as-judge evaluation, OpenTelemetry tracing, Bedrock Guardrails, AgentCore Policy |

---

## Setup Guide

### Option 1: Amazon SageMaker Studio

#### Step 1: Create or update your SageMaker execution role

Your Studio domain execution role needs the following permissions. Attach this as an inline policy to your Studio domain execution role in IAM:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels",
        "bedrock:CreateGuardrail",
        "bedrock:DeleteGuardrail",
        "bedrock:GetGuardrail"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "bedrock-agentcore:InvokeAgentRuntime",
        "bedrock-agentcore:CreateAgentRuntime",
        "bedrock-agentcore:GetAgentRuntime",
        "bedrock-agentcore:ListAgentRuntimes",
        "bedrock-agentcore:DeleteAgentRuntime"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": ["arn:aws:s3:::*", "arn:aws:s3:::*/*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:CreateRepository",
        "ecr:BatchDeleteImage",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:DeleteLogGroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:DetachRolePolicy"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:StartBuild",
        "codebuild:BatchGetBuilds",
        "codebuild:CreateProject",
        "codebuild:DeleteProject"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Step 2: Verify Bedrock model access

Amazon Bedrock models are enabled by default in your AWS account. No manual approval is needed.

If you get an `AccessDeniedException`, check that your execution role has `bedrock:InvokeModel` permissions (covered in Step 1) and that you are in a region where Bedrock is available (e.g. `us-east-1`).

The examples in this book use the following models:
- `us.amazon.nova-lite-v1:0`
- `us.anthropic.claude-3-5-haiku-20241022-v1:0`
- `us.anthropic.claude-sonnet-4-20250514-v1:0`
- `us.anthropic.claude-sonnet-4-5-20250929-v1:0`

#### Step 3: Configure your Studio Space

- Instance type: `ml.m5.large` recommended (2 vCPU, 8 GB RAM) — Chapter 3 installs heavy packages (faiss, qdrant, scikit-learn) and Chapter 5 runs multiple local servers simultaneously
- Disk size: at least **20 GB** recommended — Python packages across all chapters are substantial, and Chapter 6 builds Docker images locally which requires additional space

#### Step 4: Clone the repository

```bash
git clone https://github.com/PacktPublishing/AI-Agents-on-AWS
cd AI-Agents-on-AWS
```

Install dependencies per chapter — each chapter has its own `requirements.txt`:

```bash
# Example for Chapter 1
cd "chapter 1"
pip install -r requirements.txt
```

#### Step 5: Set environment variables

```bash
export AWS_DEFAULT_REGION=us-east-1
```

---

### Option 2: Local IDE (VS Code, Kiro, or any IDE)

#### Step 1: Configure AWS credentials

**Option A — AWS CLI (recommended):**

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region, output format
```

**Option B — AWS SSO:**

```bash
aws configure sso
aws sso login --profile your-profile
export AWS_PROFILE=your-profile
```

**Option C — Environment variables:**

```bash
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
```

#### Step 2: IAM permissions for your user/role

Your IAM user or role needs the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels",
        "bedrock:CreateGuardrail",
        "bedrock:DeleteGuardrail",
        "bedrock:GetGuardrail"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "bedrock-agentcore:InvokeAgentRuntime",
        "bedrock-agentcore:CreateAgentRuntime",
        "bedrock-agentcore:GetAgentRuntime",
        "bedrock-agentcore:ListAgentRuntimes",
        "bedrock-agentcore:DeleteAgentRuntime"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": ["arn:aws:s3:::*", "arn:aws:s3:::*/*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:CreateRepository",
        "ecr:BatchDeleteImage",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:DeleteLogGroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:DetachRolePolicy"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:StartBuild",
        "codebuild:BatchGetBuilds",
        "codebuild:CreateProject",
        "codebuild:DeleteProject"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Step 3: Verify Bedrock model access

Same as SageMaker Studio — Bedrock models are enabled by default. If you get an `AccessDeniedException`, check that your IAM user or role has `bedrock:InvokeModel` permissions (covered in Step 2) and that your `AWS_DEFAULT_REGION` is set to a region where Bedrock is available.

#### Step 4: Install dependencies

Install per chapter — each chapter has its own `requirements.txt`:

```bash
# Example for Chapter 1
cd "chapter 1"
pip install -r requirements.txt
```

#### Step 5: Set environment variables

Add to your shell profile (`~/.bashrc`, `~/.zshrc`) or a `.env` file:

```bash
export AWS_DEFAULT_REGION=us-east-1
```

For Kiro, credentials are picked up automatically from `~/.aws/credentials` or environment variables — no additional configuration needed.

#### Step 6: Verify your setup

```python
import boto3

# Test Bedrock
bedrock = boto3.client("bedrock", region_name="us-east-1")
models = bedrock.list_foundation_models()
print(f"✅ Bedrock OK — {len(models['modelSummaries'])} models available")
```

---

## Prerequisites Summary

| Requirement | SageMaker Studio | Local IDE |
|---|---|---|
| AWS credentials | Automatic (execution role) | `aws configure` or env vars |
| IAM permissions | Attach to execution role | Attach to IAM user/role |
| Bedrock model access | Enabled by default | Enabled by default |
| Python packages | `pip install` in notebook | `pip install` locally |
| Region | Set in Studio domain | `AWS_DEFAULT_REGION` env var |

## Requirements

- Python 3.10+
- AWS account with access to Amazon Bedrock
- AWS credentials configured (see Setup Guide above)
