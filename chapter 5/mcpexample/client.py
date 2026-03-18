"""
MCP Client — connects to server.py over stdio and exercises all three
MCP primitives: tools, resources, and prompts.

The client spawns server.py as a subprocess and communicates over
stdin/stdout using the MCP protocol (JSON-RPC messages).

Run:  python client.py
"""

import asyncio

# ClientSession: manages the MCP protocol session (initialize, list, call, etc.)
# StdioServerParameters: tells the client how to spawn the server subprocess
from mcp import ClientSession, StdioServerParameters

# stdio_client: context manager that spawns the server process and gives us
# read/write streams for the MCP protocol
from mcp.client.stdio import stdio_client


async def main():
    # --- Connect to the MCP Server --------------------------------------
    # StdioServerParameters defines the command to spawn the server.
    # The client will run "python server.py" as a subprocess and
    # communicate with it over stdin/stdout pipes.
    server_params = StdioServerParameters(
        command="python",
        args=["server.py"],  # path relative to where client.py runs
    )

    # stdio_client spawns the server process and returns read/write streams.
    # ClientSession wraps those streams into a high-level MCP session.
    async with stdio_client(server_params) as (read_stream, write_stream):
        async with ClientSession(read_stream, write_stream) as session:

            # Initialize the MCP connection — required before any calls.
            # This exchanges protocol version and capabilities.
            await session.initialize()

            # --- 1. Discover Tools -----------------------------------
            # list_tools() asks the server what tools are available.
            # Each tool has a name, description, and input schema.
            tools = await session.list_tools()
            print("=== Available Tools ===")
            for tool in tools.tools:
                print(f"  - {tool.name}: {tool.description}")

            # --- 2. Discover Resources --------------------------------
            # list_resource_templates() returns URI templates for resources.
            # Resources are data the LLM can read (like GET endpoints).
            print("\n=== Available Resources ===")
            resources = await session.list_resource_templates()
            for rt in resources.resourceTemplates:
                print(f"  - {rt.uriTemplate}: {rt.description}")

            # --- 3. Discover Prompts ----------------------------------
            # list_prompts() returns available prompt templates.
            # Prompts are reusable templates for common LLM tasks.
            print("\n=== Available Prompts ===")
            prompts = await session.list_prompts()
            for p in prompts.prompts:
                print(f"  - {p.name}: {p.description}")

            # --- 4. Call a Tool (known city) --------------------------
            # call_tool() invokes a tool by name with arguments.
            # The server runs the function and returns the result.
            print("\n=== Calling get_weather('London') ===")
            result = await session.call_tool("get_weather", {"city": "London"})
            # result.content is a list of content blocks; [0].text is the string
            print(f"  Result: {result.content[0].text}")

            # --- 5. Call a Tool (unknown city) ------------------------
            # Demonstrates the tool's error handling for missing data.
            print("\n=== Calling get_weather('Berlin') ===")
            result = await session.call_tool("get_weather", {"city": "Berlin"})
            print(f"  Result: {result.content[0].text}")

            # --- 6. Read a Resource -----------------------------------
            # read_resource() fetches data from a resource URI.
            # "greeting://Developer" fills in {name} = "Developer".
            print("\n=== Reading greeting resource ===")
            resource = await session.read_resource("greeting://Developer")
            print(f"  Result: {resource.contents[0].text}")

            # --- 7. Get a Prompt --------------------------------------
            # get_prompt() retrieves a filled-in prompt template.
            # Returns a list of messages ready to send to an LLM.
            print("\n=== Getting weather_report prompt ===")
            prompt = await session.get_prompt("weather_report", {"city": "Tokyo"})
            print(f"  Result: {prompt.messages[0].content.text}")


# --- Entry Point ---------------------------------------------------------
# Run the async main function. The client spawns the server automatically,
# so you only need to run: python client.py

if __name__ == "__main__":
    asyncio.run(main())
