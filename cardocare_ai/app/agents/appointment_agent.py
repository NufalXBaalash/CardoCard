from app.models.schemas import AgentState
from app.services.supabase_service import SupabaseService


class AppointmentAgent:

    def __init__(self):
        self.supabase = SupabaseService()

    def _detect_specialty(self, message: str) -> str:
        message_lower = message.lower()

        keywords = {
            "Cardiologist": ["heart", "cardiac", "chest pain", "قلب", "صدر"],
            "Neurologist": ["headache", "migraine", "brain", "head", "صداع", "رأس"],
            "Dermatologist": ["skin", "acne", "rash", "جلد", "حبوب"],
            "Orthopedist": ["bone", "joint", "knee", "back", "عظم", "مفصل", "ركبة"],
            "Pediatrician": ["child", "kid", "baby", "طفل", "أطفال"],
            "Gastroenterologist": ["stomach", "digestion", "acid", "معدة", "هضم"],
            "Psychiatrist": ["anxiety", "depression", "mental", "قلق", "اكتئاب"],
            "Oncologist": ["cancer", "tumor", "سرطان", "ورم"],
            "Endocrinologist": ["diabetes", "sugar", "thyroid", "سكر", "غدة"],
            "Pulmonologist": ["lung", "breathing", "asthma", "رئة", "تنفس", "ربو"],
        }

        for specialty, words in keywords.items():
            for word in words:
                if word in message_lower:
                    return specialty

        return "General Physician"

    def run(self, state: AgentState) -> AgentState:
        try:
            specialty = self._detect_specialty(state.message)

            # Fetch real doctors from Supabase
            doctors = self.supabase.get_available_doctors(specialty)

            if not doctors:
                # Try without specialty filter
                doctors = self.supabase.get_available_doctors()
                specialty = "General Physician"

            # Format doctor info for response
            doctor_list = []
            for doc in doctors[:5]:
                doctor_list.append({
                    "id": doc.get("id"),
                    "name": doc.get("name", "Unknown"),
                    "specialty": doc.get("specialty", ""),
                    "rating": doc.get("rating", 0),
                    "price": doc.get("price", 0),
                })

            state.reply = f"I found {len(doctor_list)} doctors for you" + (f" in {specialty}" if specialty != "General Physician" else "") + ". Here are the available options:"
            state.action = "show_doctors"
            state.payload = {
                "specialty": specialty,
                "doctors": doctor_list,
            }

        except Exception as e:
            print(f"[AppointmentAgent] Error: {e}")
            state.reply = "I'm having trouble finding doctors right now. Please try booking through the appointments page."
            state.action = "show_alert"
            state.payload = {"error": str(e)}

        return state
