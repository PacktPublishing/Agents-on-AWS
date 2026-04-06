"""
Stock A2A Agent — uses Strands web search tool + MCP stock tools.

Combines web search (for news/analysis) with MCP stock price lookup
to answer finance questions.

Local:
    1. python stock_mcp_server.py
    2. python stock_a2a_agent.py

Deploy: agentcore configure -e stock_a2a_agent.py --protocol A2A
"""

import logging
import os

import uvicorn
from fastapi import FastAPI
from strands import Agent
from strands.tools.mcp import MCPClient
from strands_tools import http_request
from mcp.client.streamable_http import streamablehttp_client
from strands.multiagent.a2a import A2AServer
from a2a.types import AgentSkill

logging.basicConfig(level=logging.INFO)

STOCK_MCP_URL = os.environ.get("STOCK_MCP_URL", "http://localhost:8000/mcp")
RUNTIME_URL = os.environ.get("AGENTCORE_RUNTIME_URL", "http://127.0.0.1:9001/")

# MCP client for stock price tools
mcp_client = MCPClient(lambda: streamablehttp_client(STOCK_MCP_URL))

stock_agent = Agent(
    name="Stock Agent",
    description="Provides stock prices and financial information.",
    system_prompt=(
        "You are a financial assistant. Use get_stock_price to look up current stock prices. "
        "Use http_request to fetch data from financial websites when needed. "
        "Always provide the ticker symbol, current price, and any relevant context."
    ),
    tools=[mcp_client, http_request],
    callback_handler=None,
)

SKILLS = [
    AgentSkill(
        id="stock_lookup",
        name="Stock Price Lookup",
        description="Get latest stock prices and financial info for any publicly traded company.",
        tags=["stocks", "finance", "prices", "market"],
        examples=[
            "What is the current price of AAPL?",
            "How is AMZN doing today?",
            "Get me the stock price for MSFT and GOOGL",
        ],
    ),
]

a2a_server = A2AServer(
    agent=stock_agent,
    http_url=RUNTIME_URL,
    serve_at_root=True,
    skills=SKILLS,
    version="1.0.0",
    enable_a2a_compliant_streaming=True,
)

app = FastAPI()


@app.get("/ping")
def ping():
    return {"status": "healthy"}


app.mount("/", a2a_server.to_fastapi_app())

if __name__ == "__main__":
    print(f"Stock A2A Agent on http://0.0.0.0:9001 (MCP: {STOCK_MCP_URL})")
    uvicorn.run(app, host="0.0.0.0", port=9001)
