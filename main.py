from fastapi import FastAPI
from app.routers import auth, tasks

app = FastAPI(title="AI SuperPlatform API")

app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(tasks.router, prefix="/tasks", tags=["Tasks"])

@app.get("/")
def read_root():
    return {"message": "Welcome to AI SuperPlatform"}
