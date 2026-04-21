from groq import Groq

from app.services.config import settings
from app.services.vector_store import VectorStore
from app.services.supabase_service import SupabaseService
from app.models.schemas import AgentState


class RAGAgent:

    def __init__(self):
        self.client = Groq(api_key=settings.GROQ_API_KEY)
        self.model = settings.GROQ_MODEL
        self.vector_store = VectorStore()
        self.supabase = SupabaseService()

    def load_user_data(self, user_id: str):
        return self.supabase.get_unprocessed_reports(user_id)

    def build_prompt(self, question: str, context_docs: list) -> str:
        context = "\n\n".join(context_docs)

        return f"""
You are a medical assistant for the CardoCard health app.

Answer based on the patient data below. If the question is related to the data, answer it clearly and medically. If it's a general health question, answer it helpfully using the data as context.

Patient Data:
{context}

Question:
{question}

Answer clearly and medically in a conversational tone.
"""

    def run(self, state: AgentState) -> AgentState:
        try:
            # 1. Load data from Supabase
            all_docs, doc_ids = self.load_user_data(state.user_id)

            # 2. Add new docs to vector store
            if all_docs:
                existing = self.vector_store.get_existing_ids()
                new_docs = []
                new_ids = []

                for doc, doc_id in zip(all_docs, doc_ids):
                    if doc_id not in existing:
                        new_docs.append(doc)
                        new_ids.append(doc_id)

                if new_docs:
                    self.vector_store.add_documents(docs=new_docs, ids=new_ids)

            # 3. Query vector store
            docs = self.vector_store.query(state.message)

            if not docs:
                docs = all_docs if all_docs else []

            if not docs:
                state.reply = "I don't have any medical records for you yet. You can upload reports through the app and I'll be able to answer questions about them."
                state.action = "show_alert"
                state.payload = {}
                return state

            # 4. LLM response
            prompt = self.build_prompt(state.message, docs)

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a helpful medical assistant for CardoCard. Answer based on the patient data provided."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.2
            )

            answer = response.choices[0].message.content

            state.reply = answer
            state.action = "none"
            state.payload = {"used_docs": docs}

        except Exception as e:
            print(f"[RAGAgent] Error: {e}")
            state.reply = "Error retrieving your medical data. Please try again."
            state.action = "show_alert"
            state.payload = {"error": str(e)}

        return state
