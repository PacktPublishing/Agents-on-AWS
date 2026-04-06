# Multi-Agent Finance Example: MCP + A2A on Amazon Bedrock AgentCore

A multi-agent finance system: one MCP server for stock price tools, one A2A sub-agent with web search, one A2A orchestrator.

## Architecture

```
    ┌──────────────────┐
    │    Finance       │
    │  Orchestrator    │
    │  (A2A :9000)     │
    └────────┬─────────┘
             │ A2A
             ▼
    ┌──────────────────┐
    │   Stock Agent    │
    │  (A2A :9001)     │
    │  + web search    │
    └───┬──────────────┘
        │ MCP
        ▼
    ┌──────────────────┐
    │   Stock Tools    │
    │  (MCP :8000)     │
    │  yfinance prices │
    └──────────────────┘
```

- MCP Server uses yfinance to fetch real stock prices
- Stock A2A Agent connects to MCP for prices + uses Strands `http_request` for web data
- Orchestrator delegates finance questions to the Stock Agent via A2A

## Files

| File | Protocol | Port | Description |
|---|---|---|---|
| `stock_mcp_server.py` | MCP | 8000 | Stock price tools (yfinance) |
| `stock_a2a_agent.py` | A2A | 9001 | Sub-agent with MCP tools + web search |
| `orchestrator.py` | A2A | 9000 | Main agent delegating to stock agent |

## Local Testing

```bash
pip install -r requirements.txt

# Terminal 1: Start MCP server
python stock_mcp_server.py

# Terminal 2: Start Stock A2A agent
python stock_a2a_agent.py

# Terminal 3: Start Orchestrator (or test stock agent directly via curl)
python orchestrator.py
```

Test the stock agent directly:
```bash
curl -X POST http://localhost:9001/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0", "id": "1", "method": "message/send",
    "params": {"message": {"role": "user",
      "parts": [{"kind": "text", "text": "What is the current price of AAPL?"}],
      "messageId": "test-1"}}
  }' | jq .
```

## Deploy to AgentCore

### Step 1: Install tools

```bash
pip install -r requirements.txt
pip install bedrock-agentcore-starter-toolkit
```

### Step 2: Set up Cognito auth

```bash
export REGION=us-east-1
export USERNAME=testuser
export PASSWORD='YourPassword123!'

POOL_ID=$(aws cognito-idp create-user-pool \
  --pool-name "FinanceAgentPool" \
  --policies '{"PasswordPolicy":{"MinimumLength":8}}' \
  --region $REGION --query "UserPool.Id" --output text)

CLIENT_ID=$(aws cognito-idp create-user-pool-client \
  --user-pool-id $POOL_ID --client-name "FinanceClient" \
  --no-generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --region $REGION --query "UserPoolClient.ClientId" --output text)

aws cognito-idp admin-create-user \
  --user-pool-id $POOL_ID --username $USERNAME \
  --region $REGION --message-action SUPPRESS

aws cognito-idp admin-set-user-password \
  --user-pool-id $POOL_ID --username $USERNAME \
  --password $PASSWORD --region $REGION --permanent

BEARER_TOKEN=$(aws cognito-idp initiate-auth \
  --client-id $CLIENT_ID --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters "USERNAME=$USERNAME,PASSWORD=$PASSWORD" \
  --region $REGION --query "AuthenticationResult.AccessToken" --output text)

echo "Discovery URL: https://cognito-idp.$REGION.amazonaws.com/$POOL_ID/.well-known/openid-configuration"
echo "Client ID: $CLIENT_ID"
echo "Bearer Token: $BEARER_TOKEN"
```

### Step 3: Deploy MCP Server

```bash
agentcore configure -e stock_mcp_server.py --protocol MCP
agentcore launch
```

Get the MCP invoke URL:
```bash
MCP_ARN_ENCODED=$(echo -n "<mcp-runtime-arn>" | jq -sRr '@uri')
export STOCK_MCP_URL="https://bedrock-agentcore.$REGION.amazonaws.com/runtimes/$MCP_ARN_ENCODED/invocations/mcp"
```

### Step 4: Deploy Stock A2A Agent

```bash
export STOCK_MCP_URL="<url-from-step-3>"
agentcore configure -e stock_a2a_agent.py --protocol A2A
agentcore launch
```

### Step 5: Deploy Orchestrator

```bash
A2A_ARN_ENCODED=$(echo -n "<stock-a2a-runtime-arn>" | jq -sRr '@uri')
export STOCK_A2A_URL="https://bedrock-agentcore.$REGION.amazonaws.com/runtimes/$A2A_ARN_ENCODED/invocations/"

agentcore configure -e orchestrator.py --protocol A2A
agentcore launch
```

### Step 6: Test

```bash
ORCH_ARN_ENCODED=$(echo -n "<orchestrator-runtime-arn>" | jq -sRr '@uri')

curl -X POST "https://bedrock-agentcore.$REGION.amazonaws.com/runtimes/$ORCH_ARN_ENCODED/invocations?qualifier=DEFAULT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -d '{
    "jsonrpc": "2.0", "id": "1", "method": "message/send",
    "params": {"message": {"role": "user",
      "parts": [{"kind": "text", "text": "How is NVDA stock doing today?"}],
      "messageId": "test-1"}}
  }' | jq .
```
