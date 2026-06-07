from fastapi import APIRouter

router = APIRouter()


@router.get("/ping")
async def redirect_placeholder():
    return {"message": "redirect router"}