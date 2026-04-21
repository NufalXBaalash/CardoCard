from groq import Groq
import json

from app.services.config import settings
from app.models.schemas import AgentState


class OrchestratorAgent:

    def __init__(self):
        self.client = Groq(api_key=settings.GROQ_API_KEY)
        self.model = settings.GROQ_MODEL

    def build_prompt(self, message: str) -> str:
        return f"""
You are an intent classification system for a medical app called CardoCard.

Classify the user message into ONE of the following intents:

- analyze_report: User wants to analyze a medical report, lab results, or symptoms
- ask_question: User is asking a general health question or about their medical data
- book_appointment: User wants to book, schedule, or find an appointment with a doctor
- upload_file: User wants to upload or share a medical document/report
- general: Greetings, questions about the app, about you (the AI), about doctors, health tips, general conversation, or anything else not covered above

Return ONLY valid JSON:
{{"intent": "one_of_the_above"}}

Do not add any explanation.

User message:
{message}
"""

    def detect_intent(self, message: str) -> str:
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a strict JSON generator."},
                    {"role": "user", "content": self.build_prompt(message)}
                ],
                temperature=0
            )

            content = response.choices[0].message.content
            data = json.loads(content)
            return data.get("intent", "general")

        except Exception as e:
            print(f"[Orchestrator] Intent detection error: {e}")
            return "general"

    def run(self, state: AgentState) -> AgentState:
        intent = self.detect_intent(state.message)
        state.intent = intent
        print(f"[Orchestrator] Detected intent: {intent}")
        return state
