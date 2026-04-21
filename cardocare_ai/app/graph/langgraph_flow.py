from langgraph.graph import StateGraph, END

from app.models.schemas import AgentState
from app.agents.orchestrator import OrchestratorAgent
from app.agents.medical_agent import MedicalAgent
from app.agents.rag_agent import RAGAgent
from app.agents.appointment_agent import AppointmentAgent
from app.agents.general_agent import GeneralAgent

orchestrator = OrchestratorAgent()
medical = MedicalAgent()
rag = RAGAgent()
appointment = AppointmentAgent()
general = GeneralAgent()


def orchestrator_node(state: AgentState):
    return orchestrator.run(state)


def router(state: AgentState):
    intent = state.intent

    if intent == "analyze_report":
        return "medical_agent"
    elif intent == "book_appointment":
        return "appointment_agent"
    elif intent == "upload_file":
        return "rag_agent"
    else:
        return "general_agent"


def rag_agent(state: AgentState):
    return rag.run(state)


def medical_agent(state: AgentState):
    return medical.run(state)


def appointment_agent(state: AgentState):
    return appointment.run(state)


def general_agent(state: AgentState):
    return general.run(state)


def build_graph():
    graph = StateGraph(AgentState)

    graph.add_node("orchestrator", orchestrator_node)
    graph.add_node("rag_agent", rag_agent)
    graph.add_node("medical_agent", medical_agent)
    graph.add_node("appointment_agent", appointment_agent)
    graph.add_node("general_agent", general_agent)

    graph.set_entry_point("orchestrator")

    graph.add_conditional_edges(
        "orchestrator",
        router,
        {
            "rag_agent": "rag_agent",
            "medical_agent": "medical_agent",
            "appointment_agent": "appointment_agent",
            "general_agent": "general_agent",
        }
    )

    graph.add_edge("rag_agent", END)
    graph.add_edge("medical_agent", END)
    graph.add_edge("appointment_agent", END)
    graph.add_edge("general_agent", END)

    return graph.compile()
