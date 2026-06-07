from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def links_placeholder():
    return {"message": "links router"}