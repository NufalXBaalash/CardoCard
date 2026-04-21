from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from enum import Enum


class ActionType(str, Enum):
    SHOW_ANALYSIS = "show_analysis"
    SHOW_SLOTS = "show_slots"
    SHOW_DOCTORS = "show_doctors"
    SHOW_ALERT = "show_alert"
    NONE = "none"


class Message(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    user_id: str
    message: str
    history: Optional[List[Message]] = []


class ChatResponse(BaseModel):
    reply: str
    action: ActionType
    payload: Dict[str, Any] = {}


class UploadRequest(BaseModel):
    patient_id: str
    doctor_id: Optional[str] = None
    content: str
    diagnosis: Optional[str] = ""
    treatment: Optional[str] = ""
    notes: Optional[str] = ""
    date: Optional[str] = None


class AgentState(BaseModel):
    user_id: str
    message: str
    history: List[Message] = []

    intent: Optional[str] = None
    retrieved_docs: Optional[List[str]] = None

    reply: Optional[str] = None
    action: Optional[ActionType] = ActionType.NONE
    payload: Optional[Dict[str, Any]] = {}
