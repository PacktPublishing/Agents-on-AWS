"""
Chapter 7 - End-to-End AgentCore Evaluation Example
Simple travel assistant agent deployed on AgentCore Runtime.
"""
from strands import Agent, tool
from strands.models import BedrockModel
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()


@tool
def get_flight_info(origin: str, destination: str) -> str:
    """Get flight information between two cities."""
    flights = {
        ("new york", "london"): "Flight AA100 departs JFK at 22:00, arrives LHR at 10:00+1. Duration: 7h. Price: $650.",
        ("london", "new york"): "Flight BA178 departs LHR at 11:00, arrives JFK at 14:00. Duration: 8h. Price: $720.",
        ("new york", "paris"): "Flight AF007 departs JFK at 19:30, arrives CDG at 09:15+1. Duration: 7h45m. Price: $580.",
        ("paris", "new york"): "Flight AF008 departs CDG at 10:45, arrives JFK at 12:30. Duration: 8h45m. Price: $610.",
        ("london", "paris"): "Flight BA304 departs LHR at 08:00, arrives CDG at 10:15. Duration: 1h15m. Price: $120.",
    }
    key = (origin.lower(), destination.lower())
    return flights.get(key, f"No direct flights found from {origin} to {destination}. Please check connecting options.")


@tool
def get_hotel_recommendations(city: str, budget: str = "medium") -> str:
    """Get hotel recommendations for a city within a budget range (low/medium/high)."""
    hotels = {
        "london": {
            "low": "Premier Inn London City (£80/night) - Clean, central, great transport links.",
            "medium": "The Hoxton Shoreditch (£150/night) - Trendy area, rooftop bar, free mini-bar.",
            "high": "The Savoy (£500/night) - Iconic luxury on the Thames, butler service.",
        },
        "paris": {
            "low": "Generator Paris (€60/night) - Modern hostel with private rooms near Canal Saint-Martin.",
            "medium": "Hotel des Grands Boulevards (€180/night) - Boutique hotel, rooftop terrace, great location.",
            "high": "Le Bristol Paris (€800/night) - Palace hotel, Michelin-starred restaurant, garden pool.",
        },
        "new york": {
            "low": "Pod 51 Hotel ($120/night) - Compact rooms, great Midtown location.",
            "medium": "The Arlo NoMad ($220/night) - Rooftop bar, stylish rooms, central location.",
            "high": "The Plaza Hotel ($700/night) - Iconic landmark, Central Park views, luxury suites.",
        },
    }
    city_hotels = hotels.get(city.lower())
    if not city_hotels:
        return f"No hotel recommendations available for {city}."
    return city_hotels.get(budget.lower(), city_hotels["medium"])


@tool
def get_weather_forecast(city: str) -> str:
    """Get a simple weather forecast for a city."""
    forecasts = {
        "london": "Partly cloudy, 15°C (59°F). Light rain expected in the afternoon. Bring an umbrella.",
        "paris": "Sunny with light clouds, 22°C (72°F). Perfect weather for sightseeing.",
        "new york": "Clear skies, 18°C (64°F). Great day to explore Central Park.",
    }
    return forecasts.get(city.lower(), f"Weather data not available for {city}.")


model = BedrockModel(model_id="us.anthropic.claude-3-5-haiku-20241022-v1:0")

agent = Agent(
    model=model,
    tools=[get_flight_info, get_hotel_recommendations, get_weather_forecast],
    system_prompt=(
        "You are a helpful travel assistant. You can provide flight information, "
        "hotel recommendations, and weather forecasts for travel planning. "
        "Only answer questions related to travel — flights, hotels, and weather. "
        "For anything outside travel, politely decline and redirect to travel topics."
    ),
)


@app.entrypoint
def travel_agent(payload):
    user_input = payload.get("prompt", "")
    print(f"User input: {user_input}")
    response = agent(user_input)
    return response.message["content"][0]["text"]


if __name__ == "__main__":
    app.run()
