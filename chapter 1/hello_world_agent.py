"""Chapter 1: Hello World Agent using Strands Agents SDK."""

from strands import Agent

# Create a basic agent powered by Amazon Bedrock
agent = Agent()

# Run the agent with a simple prompt
response = agent("Hello! Tell me a fun fact about AI agents.")
print(response)
