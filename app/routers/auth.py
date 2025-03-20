from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def auth_root():
    return {"message": "Auth Endpoint Working"}
