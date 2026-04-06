import json
import os
from strands import Agent
from strands.models.bedrock import BedrockModel

# Initialize outside the handler so it persists across warm invocations.
# The first request pays the setup cost. Subsequent requests reuse this agent.
model = BedrockModel(
    model_id=os.environ.get("MODEL_ID", "us.anthropic.claude-sonnet-4-20250514-v1:0"),
)

agent = Agent(
    model=model,
    system_prompt="""You are a document analysis assistant.
    When given a contract or document, you:
    1. Extract key terms and parties involved
    2. Flag any risky or unusual clauses
    3. Provide a clear summary

    Be concise and specific. Cite the exact language from the document when flagging risks.""",
)


def lambda_handler(event, context):
    """Handle API Gateway POST requests."""
    # Parse the request body
    if isinstance(event.get("body"), str):
        body = json.loads(event["body"])
    else:
        body = event

    document_text = body.get("document_text", "")

    if not document_text:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Missing 'document_text' in request body"}),
        }

    result = agent(f"Analyze this contract:\n\n{document_text}")

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"analysis": str(result)}),
    }
