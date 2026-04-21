from fastapi import APIRouter, UploadFile, File, Form
from datetime import date

from app.models.schemas import ChatRequest, ChatResponse, AgentState, UploadRequest
from app.graph.langgraph_flow import build_graph
from app.services.supabase_service import SupabaseService

router = APIRouter()
graph = build_graph()
supabase = SupabaseService()


@router.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest):
    state = AgentState(
        user_id=request.user_id,
        message=request.message,
        history=request.history or []
    )

    result = graph.invoke(state)

    if hasattr(result, "reply"):
        return ChatResponse(
            reply=result.reply or "",
            action=result.action or "none",
            payload=result.payload or {}
        )
    else:
        return ChatResponse(
            reply=result.get("reply", ""),
            action=result.get("action", "none"),
            payload=result.get("payload", {})
        )


@router.post("/upload")
def upload_report(request: UploadRequest):
    """Upload a medical report for a patient."""
    try:
        data = {
            "date": request.date or str(date.today()),
            "diagnosis": request.diagnosis or "",
            "treatment": request.treatment or "",
            "notes": request.content or request.notes or "",
        }

        result = supabase.upload_report(
            patient_id=request.patient_id,
            doctor_id=request.doctor_id or "",
            data=data
        )

        if result:
            return {"status": "success", "message": "Report uploaded successfully", "data": result}
        else:
            return {"status": "error", "message": "Failed to upload report"}

    except Exception as e:
        return {"status": "error", "message": str(e)}


@router.get("/health")
def health_check():
    return {"status": "ok", "service": "CardoCard AI System"}
