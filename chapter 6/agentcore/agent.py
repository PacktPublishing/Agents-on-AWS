from bedrock_agentcore import BedrockAgentCoreApp
from strands import Agent, tool
from strands.models.bedrock import BedrockModel

app = BedrockAgentCoreApp()


@tool
def extract_clauses(text: str) -> dict:
    """Extract key clauses from contract text."""
    # In production, this would use NLP or a specialized model.
    # For this example, we return a structured placeholder.
    return {"clauses": ["termination", "liability", "indemnification"]}


model = BedrockModel(model_id="us.anthropic.claude-sonnet-4-20250514-v1:0")
agent = Agent(
    model=model,
    tools=[extract_clauses],
    system_prompt="You are a document analysis assistant. Extract and summarize key contract clauses.",
)


@app.entrypoint
def handle(payload):
    response = agent(payload.get("prompt"))
    return response.message["content"][0]["text"]


if __name__ == "__main__":
    app.run()
