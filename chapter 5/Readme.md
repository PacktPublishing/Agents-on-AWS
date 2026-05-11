# Chapter 5: Agent Protocol Examples

Code examples from Chapter 5 of *AI Agents on AWS*.

This chapter covers two open protocols for agent communication: **MCP** (Model Context Protocol) and **A2A** (Agent-to-Agent).

```
chapter 5/
├── mcpexample/             # MCP example — tool/resource/prompt server + client
│   ├── server.py
│   ├── client.py
│   ├── requirements.txt
│   └── README.md
│
└── a2aexample/             # A2A example — multi-agent travel planner
    ├── weather_agent_server.py
    ├── flights_agent_server.py
    ├── travel_orchestrator.py
    ├── requirements.txt
    └── README.md
```

---

## MCP — Model Context Protocol (`mcpexample/`)

MCP defines how an LLM connects to external tools, data sources, and prompt templates through a standardized protocol. Think of it as a USB-C port for AI — any LLM can plug into any MCP server.

### What's in the example

- `server.py` — An MCP server that exposes three primitives over stdio:
  - **Tool**: `get_weather` — a function the LLM can call to look up weather
  - **Resource**: `greeting://{name}` — data the LLM can read (like a GET endpoint)
  - **Prompt**: `weather_report` — a reusable prompt template

- `client.py` — An MCP client that spawns the server as a subprocess, discovers all available tools/resources/prompts, and calls each one

### How it works

```
Client (client.py)  ◄── stdio (stdin/stdout) ──►  Server (server.py)
```

The client spawns the server as a child process. They exchange JSON-RPC messages over stdin/stdout. No HTTP, no ports — everything runs locally through pipes.

### Running

```bash
cd mcpexample
pip install -r requirements.txt
python client.py          # starts the server automatically
```

---

## A2A — Agent-to-Agent Protocol (`a2aexample/`)

A2A defines how AI agents discover and communicate with each other over HTTP. Unlike MCP (which connects an LLM to tools), A2A connects agents to other agents — each with their own LLM, tools, and capabilities.

### What's in the example

- `weather_agent_server.py` — A Strands Agent with a `get_weather` tool, served as an A2A server on port 9001. Publishes an agent card with skills so clients can discover it.

- `flights_agent_server.py` — A Strands Agent with `search_flights` and `book_flight` tools, served as an A2A server on port 9002. Also publishes an agent card with skills.

- `travel_orchestrator.py` — The A2A client. Connects to both agent servers, sends them questions using the A2A protocol, and prints a combined trip summary.

### How it works

```
Orchestrator (client)
    │
    ├── GET  /.well-known/agent-card.json  →  discover agent capabilities
    └── POST /  (JSON-RPC: message/send)   →  send question, get answer
         │                                          │
         ▼                                          ▼
  Weather Agent (:9001)                    Flights Agent (:9002)
  LLM + get_weather tool                   LLM + search/book tools
```

### Running

```bash
cd a2aexample
pip install -r requirements.txt

# Terminal 1
python weather_agent_server.py

# Terminal 2
python flights_agent_server.py

# Terminal 3
python travel_orchestrator.py
# or with custom args:
python travel_orchestrator.py "Rome" "Paris" "Rome"
```

---

## MCP vs A2A — Key Differences

| | MCP | A2A |
|---|---|---|
| Purpose | Connect an LLM to tools/data | Connect agents to other agents |
| Transport | stdio, HTTP/SSE | HTTP (JSON-RPC, SSE) |
| Discovery | `list_tools()`, `list_resources()` | Agent card at `/.well-known/agent-card.json` |
| Who has the LLM | The client (LLM calls tools on the server) | Both sides (each agent has its own LLM) |
| Communication | Function calls (tool invocations) | Natural language messages |
| Use case | Give an LLM access to APIs, databases, files | Multi-agent collaboration across services |

In short: MCP is for **LLM ↔ Tool** communication. A2A is for **Agent ↔ Agent** communication.

---

## Prerequisites

- Python 3.11+
- AWS credentials configured (`~/.aws/credentials`) for the A2A example — Strands defaults to Amazon Bedrock
- The MCP example has no LLM dependency — it's pure tool/client communication
