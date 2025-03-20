import sys
import os

# Add the project directory and 'app' to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(os.path.dirname(__file__), "app"))

from fastapi import FastAPI
from app.routers import auth, tasks

app = FastAPI(title="AI SuperPlatform API")

app.include_router(auth.router)
app.include_router(tasks.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to AI SuperPlatform"}
