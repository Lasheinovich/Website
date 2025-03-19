from fastapi import FastAPI
from app.routers import auth, tasks

app = FastAPI(title="AI SuperPlatform API")

app.include_router(auth.router)
app.include_router(tasks.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to AI SuperPlatform"}
