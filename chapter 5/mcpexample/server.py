"""
MCP Server — exposes a weather tool, a greeting resource, and a prompt
over stdio transport.

MCP (Model Context Protocol) lets LLMs discover and call tools, read
resources, and use prompt templates through a standardized protocol.

Run:  python server.py
"""

# FastMCP: high-level helper that makes it easy to create an MCP server.
# It handles JSON-RPC message parsing, tool/resource/prompt registration,
# and transport (stdio or HTTP).
from mcp.server.fastmcp import FastMCP

# Create the MCP server instance with a name.
# This name identifies the server when clients connect.
mcp = FastMCP("WeatherServer")


# --- Tool: get_weather ---------------------------------------------------
# Tools are functions that an LLM can call.
# The @mcp.tool() decorator registers this function so that:
#   - It appears in list_tools() responses
#   - Clients can call it via call_tool("get_weather", {"city": "London"})
# The docstring becomes the tool description the LLM sees.

@mcp.tool()
def get_weather(city: str) -> str:
    """Get the current weather for a given city."""
    # Fake data for demo purposes — a real server would call a weather API
    fake_weather = {
        "london": "15°C, cloudy",
        "paris": "18°C, sunny",
        "tokyo": "22°C, humid",
        "new york": "12°C, windy",
    }
    result = fake_weather.get(city.lower())
    if result:
        return f"Weather in {city}: {result}"
    return f"Sorry, no weather data available for '{city}'."


# --- Resource: greeting ---------------------------------------------------
# Resources are data that an LLM can read (similar to GET endpoints).
# The URI template "greeting://{name}" means clients can read any greeting
# by providing a name, e.g. read_resource("greeting://Developer").
# Resources are for data retrieval, not actions — use tools for actions.

@mcp.resource("greeting://{name}")
def get_greeting(name: str) -> str:
    """Return a personalized greeting."""
    return f"Hello, {name}! Welcome to the WeatherServer."


# --- Prompt: weather_report ------------------------------------------------
# Prompts are reusable prompt templates that clients can retrieve and fill in.
# They help standardize how LLMs are asked to perform specific tasks.
# Clients call get_prompt("weather_report", {"city": "Tokyo"}) to get
# a pre-built prompt message they can send to an LLM.

@mcp.prompt()
def weather_report(city: str) -> str:
    """Generate a prompt asking for a weather report."""
    return f"Please provide a detailed weather report for {city}, including temperature, humidity, and forecast."


# --- Start the Server ----------------------------------------------------
# mcp.run() starts the MCP server using the specified transport.
# "stdio" means it reads JSON-RPC messages from stdin and writes to stdout.
# This is how MCP clients (like the one in client.py) communicate with it —
# the client spawns this script as a subprocess and pipes messages through.

if __name__ == "__main__":
    mcp.run(transport="stdio")
