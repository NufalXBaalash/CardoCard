import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    def __init__(self):
        self.ENV = os.getenv("ENV", "dev")
        self.MOCK_MODE = os.getenv("MOCK_MODE", "false").lower() == "true"

        # GROQ
        self.GROQ_API_KEY = os.getenv("GROQ_API_KEY")
        self.GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

        # SUPABASE (replaces Firebase)
        self.SUPABASE_URL = os.getenv("SUPABASE_URL")
        self.SUPABASE_KEY = os.getenv("SUPABASE_KEY")

        # VECTOR DB
        self.VECTOR_DB_PATH = os.getenv("VECTOR_DB_PATH", "./chroma_db")

        # CACHE
        self.CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))


settings = Settings()
