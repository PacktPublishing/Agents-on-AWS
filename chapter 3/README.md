# Chapter 3: Agent Memory

This chapter explores how to add memory capabilities to AI agents, enabling them to maintain context across interactions and personalize responses based on user preferences.

## Examples

### 1. Strands Agents with Persistent Memory (`strands-agents_memory.ipynb`)

Demonstrates how to build personalized agents using [Strands Agents](https://github.com/strands-agents/sdk-python) with long-term memory powered by [Mem0](https://github.com/mem0ai/mem0). The agent remembers user preferences (dietary restrictions, drink preferences, etc.) and uses them to provide tailored recommendations via web search.

Key concepts covered:
- System prompts with per-user memory isolation
- Storing and retrieving user preferences with Mem0
- Combining memory recall with web search for personalized answers
- Building user-specific agent instances

### 2. LangGraph with AgentCore Memory Checkpointer (`agentcorememory_with_langgraph/`)

Demonstrates short-term conversational memory using [LangGraph](https://github.com/langchain-ai/langgraph) with the [Amazon Bedrock AgentCore Memory](https://docs.aws.amazon.com/bedrock/latest/userguide/agentcore-memory.html) checkpointer. A math agent performs multi-step calculations while maintaining conversation state across turns.

Key concepts covered:
- AgentCore Memory as a LangGraph checkpointer backend
- Automatic state persistence across conversation turns
- Session and actor-based conversation management
- Inspecting checkpoint history and conversation state

## Prerequisites

- Python 3.10+
- AWS account with access to Amazon Bedrock models
- AWS IAM role with appropriate permissions for AgentCore Memory

## Getting Started

Each example includes its own dependency list. Install requirements before running:

```bash
# For the LangGraph example
pip install -r agentcorememory_with_langgraph/requirements(4).txt

# For the Strands Agents example, dependencies are installed in the first notebook cell
```
