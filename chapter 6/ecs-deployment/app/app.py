"""Hospital scheduling agent deployed on ECS Fargate.

A FastAPI application that hosts a Strands agent for coordinating
surgical scheduling across provider calendars and hospital systems.
"""

import os
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from strands import Agent, tool
from strands.models.bedrock import BedrockModel

app = FastAPI(title="Hospital Scheduling Agent")

# Serve the web UI
STATIC_DIR = Path(__file__).parent / "static"
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

MODEL_ID = os.environ.get("MODEL_ID", "us.anthropic.claude-sonnet-4-20250514-v1:0")

SYSTEM_PROMPT = """You are a hospital surgical scheduling coordinator. You help staff
find available time slots for procedures by checking provider availability,
equipment needs, and operating room schedules.

When a scheduling request comes in:
1. Identify the procedure type and required specialists
2. Check provider availability across calendars
3. Verify equipment availability for the requested time
4. Suggest the best available slots
5. Confirm the booking details

Be concise and professional. Present scheduling options clearly with dates,
times, and any constraints. If conflicts exist, explain them and offer alternatives."""


# --- Mock tools (replace with real integrations in production) ---

@tool
def check_provider_availability(provider_name: str, date: str) -> dict:
    """Check a healthcare provider's calendar availability for a given date.

    Args:
        provider_name: Name of the doctor or specialist
        date: Date to check in YYYY-MM-DD format

    Returns:
        Dictionary with available time slots
    """
    # In production, this would query the EHR/calendar system
    return {
        "provider": provider_name,
        "date": date,
        "available_slots": ["09:00-10:00", "11:00-12:00", "14:00-15:30"],
        "notes": "No conflicts found"
    }


@tool
def check_equipment_availability(equipment_type: str, date: str, time_slot: str) -> dict:
    """Check if specific medical equipment is available for a procedure.

    Args:
        equipment_type: Type of equipment needed (e.g., 'laparoscopic tower', 'C-arm')
        date: Date to check in YYYY-MM-DD format
        time_slot: Time slot to check (e.g., '09:00-10:00')

    Returns:
        Dictionary with equipment availability status
    """
    return {
        "equipment": equipment_type,
        "date": date,
        "time_slot": time_slot,
        "available": True,
        "location": "OR-3"
    }


@tool
def book_procedure(
    patient_id: str, procedure: str, provider_name: str,
    date: str, time_slot: str, operating_room: str
) -> dict:
    """Book a surgical procedure after confirming all resources are available.

    Args:
        patient_id: Patient identifier
        procedure: Name of the procedure
        provider_name: Lead surgeon or provider
        date: Scheduled date in YYYY-MM-DD format
        time_slot: Confirmed time slot
        operating_room: Assigned operating room

    Returns:
        Booking confirmation with reference number
    """
    return {
        "status": "confirmed",
        "booking_ref": "BK-2026-04821",
        "patient_id": patient_id,
        "procedure": procedure,
        "provider": provider_name,
        "date": date,
        "time": time_slot,
        "room": operating_room,
        "message": "Booking confirmed. SMS notification sent to patient and provider."
    }


# Shared model instance (stateless, safe to reuse across requests)
model = BedrockModel(model_id=MODEL_ID)

AGENT_TOOLS = [check_provider_availability, check_equipment_availability, book_procedure]


class HistoryMessage(BaseModel):
    role: str
    content: str


class ScheduleRequest(BaseModel):
    message: str
    history: list[HistoryMessage] = []


def build_agent_with_history(history: list[HistoryMessage]) -> Agent:
    """Create a fresh Agent seeded with prior conversation turns."""
    agent = Agent(
        model=model,
        system_prompt=SYSTEM_PROMPT,
        tools=AGENT_TOOLS,
    )
    # Seed the agent's message buffer with previous turns so it
    # remembers everything the user already said in this session.
    for msg in history:
        agent.messages.append({"role": msg.role, "content": [{"text": msg.content}]})
    return agent


@app.get("/health")
def health_check():
    """Health check endpoint for the ALB."""
    return {"status": "healthy"}


@app.get("/")
def root():
    """Serve the web UI."""
    return FileResponse(str(STATIC_DIR / "index.html"))


@app.post("/schedule")
async def schedule(request: ScheduleRequest):
    """Send a scheduling request to the hospital agent."""
    if not request.message:
        raise HTTPException(status_code=400, detail="No message provided")

    try:
        agent = build_agent_with_history(request.history)
        response = agent(request.message)
        return PlainTextResponse(content=str(response))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", "8080"))
    uvicorn.run(app, host="0.0.0.0", port=port)
