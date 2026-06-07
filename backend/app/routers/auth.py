from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def auth_placeholder():
    return {"message": "auth router"}