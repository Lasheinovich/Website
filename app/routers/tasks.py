from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def tasks_root():
    return {"message": "Tasks Endpoint Working"}
