from fastapi import FastAPI
from app.api.routes import router

app = FastAPI(title="CardoCard AI System", version="1.0.0")
app.include_router(router)


@app.get("/")
def root():
    return {"message": "CardoCard AI System is running", "version": "1.0.0"}
