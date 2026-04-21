import chromadb

from app.services.config import settings


class VectorStore:

    def __init__(self):
        try:
            self.client = chromadb.EphemeralClient()
        except Exception:
            self.client = chromadb.Client()

        self.collection = self.client.get_or_create_collection(
            name="medical_reports"
        )

    def get_existing_ids(self):
        try:
            result = self.collection.get()
            return set(result["ids"]) if result and result["ids"] else set()
        except Exception:
            return set()

    def add_documents(self, docs, ids):
        self.collection.add(documents=docs, ids=ids)

    def query(self, query_text, n_results=3):
        if self.collection.count() == 0:
            return []

        results = self.collection.query(
            query_texts=[query_text],
            n_results=min(n_results, self.collection.count())
        )

        return results.get("documents", [[]])[0]
