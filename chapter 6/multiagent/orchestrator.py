"""
Finance Orchestrator — A2A agent that delegates to the Stock sub-agent.

Local:
    1. python stock_mcp_server.py
    2. python stock_a2a_agent.py
    3. python orchestrator.py

Deploy: agentcore configure -e orchestrator.py --protocol A2A
"""

import logging
import os

import uvicorn
from fastapi import FastAPI
from strands import Agent
from strands.multiagent.a2a import A2AAgent, A2AServer
from a2a.types import AgentSkill

logging.basicConfig(level=logging.INFO)

RUNTIME_URL = os.environ.get("AGENTCORE_RUNTIME_URL", "http://127.0.0.1:9000/")
STOCK_A2A_URL = os.environ.get("STOCK_A2A_URL", "http://127.0.0.1:9001")

stock_agent = A2AAgent(STOCK_A2A_URL)

orchestrator = Agent(
    name="Finance Orchestrator",
    description="Provides financial advice by coordinating with the Stock agent.",
    system_prompt=(
        "You are a financial advisor assistant. When users ask about stocks, "
        "investments, or market conditions, use the stock agent to get current prices. "
        "Provide helpful analysis and context with the data."
    ),
    tools=[stock_agent],
    callback_handler=None,
)

SKILLS = [
    AgentSkill(
        id="finance_advisor",
        name="Finance Advisor",
        description="Answers finance questions using real-time stock data.",
        tags=["finance", "stocks", "investing", "market"],
        examples=[
            "How are the FAANG stocks doing?",
            "Should I look at NVDA right now?",
            "Compare AAPL and MSFT prices",
        ],
    ),
]

a2a_server = A2AServer(
    agent=orchestrator,
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
    print(f"Finance Orchestrator on http://0.0.0.0:9000 (Stock Agent: {STOCK_A2A_URL})")
    uvicorn.run(app, host="0.0.0.0", port=9000)
