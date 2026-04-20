import os
from strands import Agent, tool
from strands.models import BedrockModel


@tool
def lookup_account(account_id: str) -> str:
    """Look up account details by account ID."""
    # Simulated account data
    accounts = {
        "ACC-001": {"name": "Acme Corp", "tier": "Enterprise", "balance": 142500.00},
        "ACC-002": {"name": "Startup Inc", "tier": "Growth", "balance": 28750.00},
    }
    account = accounts.get(account_id)
    if account:
        return f"Account {account_id}: {account['name']}, Tier: {account['tier']}, Balance: ${account['balance']:,.2f}"
    return f"Account {account_id} not found."


@tool
def calculate_discount(amount: float, tier: str) -> str:
    """Calculate discount based on customer tier."""
    rates = {"Enterprise": 0.15, "Growth": 0.10, "Starter": 0.05}
    rate = rates.get(tier, 0.0)
    discount = amount * rate
    return f"{tier} tier discount: {rate*100:.0f}% off ${amount:,.2f} = ${discount:,.2f} savings"


model = BedrockModel(
    model_id="us.anthropic.claude-sonnet-4-20250514-v1:0",
)

agent = Agent(
    model=model,
    system_prompt="You are a customer account assistant. Use the available tools to help with account inquiries.",
    tools=[lookup_account, calculate_discount],
)

response = agent("Look up account ACC-001 and calculate what discount they would get on a $50,000 purchase.")
print(response)
