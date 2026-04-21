from groq import Groq

from app.services.config import settings
from app.models.schemas import AgentState


class GeneralAgent:

    def __init__(self):
        self.client = Groq(api_key=settings.GROQ_API_KEY)
        self.model = settings.GROQ_MODEL

    def run(self, state: AgentState) -> AgentState:
        try:
            history_messages = []
            for msg in state.history[-6:]:
                history_messages.append({
                    "role": msg.role if hasattr(msg, 'role') else msg.get("role", "user"),
                    "content": msg.content if hasattr(msg, 'content') else msg.get("content", ""),
                })

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are CardoCard AI, a friendly and knowledgeable health assistant for the CardoCard medical app. "
                            "You help patients and doctors with:\n"
                            "- General health questions and medical advice\n"
                            "- Questions about the CardoCard app features (appointments, medical records, medications, health metrics, NFC card login, doctor management)\n"
                            "- Questions about yourself and your capabilities\n"
                            "- Information about doctors and specialties available in the app\n"
                            "- Health tips and wellness guidance\n\n"
                            "Important guidelines:\n"
                            "- Always be helpful, clear, and conversational\n"
                            "- For medical questions, give general guidance but remind the user to consult a doctor for specific diagnoses\n"
                            "- If asked about the app, explain features like: booking appointments with doctors, viewing medical records, "
                            "uploading reports for AI analysis, tracking medications, monitoring health metrics, NFC card authentication\n"
                            "- If asked about doctors, mention that users can browse doctors by specialty and book appointments directly\n"
                            "- Keep responses concise but informative\n"
                            "- You are powered by AI (Groq LLM) and are part of the CardoCard health platform"
                        )
                    },
                    *history_messages,
                    {"role": "user", "content": state.message}
                ],
                temperature=0.4,
                max_tokens=500,
            )

            state.reply = response.choices[0].message.content
            state.action = "none"
            state.payload = {}

        except Exception as e:
            print(f"[GeneralAgent] Error: {e}")
            state.reply = "I'm having trouble responding right now. Please try again."
            state.action = "show_alert"
            state.payload = {"error": str(e)}

        return state
