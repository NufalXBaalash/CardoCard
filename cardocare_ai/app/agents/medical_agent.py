from groq import Groq
import json

from app.services.config import settings
from app.models.schemas import AgentState


class MedicalAgent:

    def __init__(self):
        self.client = Groq(api_key=settings.GROQ_API_KEY)
        self.model = settings.GROQ_MODEL

    def build_prompt(self, message: str) -> str:
        return f"""
You are a medical AI assistant for the CardoCard health app.

Your task:
- Analyze medical reports, lab results, or symptoms
- Identify abnormal values and health risks
- Provide clear medical summaries
- Give actionable recommendations

IMPORTANT:
Always return JSON only in this format:
{{
  "reply": "clear medical explanation for the patient",
  "action": "show_analysis",
  "payload": {{
    "abnormal_values": ["list of abnormal findings"],
    "risks": ["list of health risks detected"],
    "summary": "brief medical summary",
    "recommendation": ["list of actionable recommendations"]
  }}
}}

User message:
{message}
"""

    def run(self, state: AgentState) -> AgentState:
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a strict medical JSON generator."},
                    {"role": "user", "content": self.build_prompt(state.message)}
                ],
                temperature=0.2
            )

            content = response.choices[0].message.content

            try:
                data = json.loads(content)
            except json.JSONDecodeError:
                print(f"[MedicalAgent] JSON parse failed, raw: {content}")
                state.reply = "I couldn't parse the medical analysis. Please try again."
                state.action = "show_alert"
                state.payload = {"raw_response": content}
                return state

            state.reply = data.get("reply", "")
            state.action = data.get("action", "show_analysis")
            state.payload = data.get("payload", {})

        except Exception as e:
            print(f"[MedicalAgent] Error: {e}")
            state.reply = "Error processing medical analysis"
            state.action = "show_alert"
            state.payload = {"error": str(e)}

        return state
