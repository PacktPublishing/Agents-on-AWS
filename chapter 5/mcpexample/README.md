# MCP Weather Server Example

A simple [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server and client demonstrating tools, resources, and prompts over stdio transport.

## Architecture

```
┌────────────┐  stdio (stdin/stdout)  ┌────────────┐
│  client.py │ ◄────────────────────► │  server.py │
│            │                        │            │
│ MCP Client │                        │ MCP Server │
│            │                        │ (FastMCP)  │
└────────────┘                        └────────────┘
```

The client spawns the server as a subprocess and communicates over stdio using the MCP protocol. No HTTP, no ports — everything runs locally through stdin/stdout pipes.

## Files

| File | Description |
|---|---|
| `server.py` | MCP server exposing a weather tool, a greeting resource, and a weather report prompt |
| `client.py` | MCP client that connects to the server and exercises all three capabilities |

## How the Code Works

### Server (`server.py`)

Uses `FastMCP` to create a server with three MCP primitives:

```python
from mcp.server.fastmcp import FastMCP
mcp = FastMCP("WeatherServer")
```

**Tool** — a function the LLM can call:
```python
@mcp.tool()
def get_weather(city: str) -> str:
    """Get the current weather for a given city."""
    # Looks up city in a dictionary, returns weather string
```

**Resource** — data the LLM can read (like a GET endpoint):
```python
@mcp.resource("greeting://{name}")
def get_greeting(name: str) -> str:
    """Return a personalized greeting."""
```

**Prompt** — a reusable prompt template:
```python
@mcp.prompt()
def weather_report(city: str) -> str:
    """Generate a prompt asking for a weather report."""
```

The server runs over stdio transport (`mcp.run(transport="stdio")`), meaning it reads JSON-RPC messages from stdin and writes responses to stdout.

### Client (`client.py`)

Connects to the server by spawning it as a subprocess:

```python
server_params = StdioServerParameters(command="python", args=["server.py"])

async with stdio_client(server_params) as (read_stream, write_stream):
    async with ClientSession(read_stream, write_stream) as session:
        await session.initialize()
```

Then it demonstrates each MCP capability:
- `session.list_tools()` — discover available tools
- `session.call_tool("get_weather", {"city": "London"})` — invoke a tool
- `session.list_resource_templates()` — discover resources
- `session.read_resource("greeting://Developer")` — read a resource
- `session.list_prompts()` / `session.get_prompt(...)` — list and use prompts

## Setup & Running

```bash
pip install -r requirements.txt
```

Run the client (it starts the server automatically):

```bash
python client.py
```

Expected output:

```
=== Available Tools ===
  - get_weather: Get the current weather for a given city.

=== Available Resources ===
  - greeting://{name}: Return a personalized greeting.

=== Available Prompts ===
  - weather_report: Generate a prompt asking for a weather report.

=== Calling get_weather('London') ===
  Result: Weather in London: 15°C, cloudy

=== Calling get_weather('Berlin') ===
  Result: Sorry, no weather data available for 'Berlin'.

=== Reading greeting resource ===
  Result: Hello, Developer! Welcome to the WeatherServer.

=== Getting weather_report prompt ===
  Result: Please provide a detailed weather report for Tokyo...
```

## Available Weather Cities

London, Paris, Tokyo, New York
