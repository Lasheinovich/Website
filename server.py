from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Welcome to AI SuperPlatform"}

@app.get("/auth/")
def auth_endpoint():
    return {"message": "Auth Endpoint Working"}

@app.get("/tasks/")
def tasks_endpoint():
    return {"message": "Tasks Endpoint Working"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
