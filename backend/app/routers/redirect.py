from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db, AsyncSessionLocal
from app.models.link import Link
from app.models.click import Click

router = APIRouter()


def _parse_device(user_agent: str) -> str:
    ua = user_agent.lower()
    if any(kw in ua for kw in ("mobile", "android", "iphone", "ipad")):
        return "mobile"
    return "desktop"


async def _record_click(
    link_id: int,
    country: str | None,
    device_type: str,
    referrer: str | None,
) -> None:
    async with AsyncSessionLocal() as db:
        db.add(Click(link_id=link_id, country=country, device_type=device_type, referrer=referrer))
        await db.commit()


@router.get("/{slug}")
async def redirect_to_url(
    slug: str,
    request: Request,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    redis = getattr(request.app.state, "redis", None)

    link_id: int | None = None
    original_url: str | None = None

    if redis:
        cached = await redis.get(f"slug:{slug}")
        if cached:
            raw = cached.decode()
            sep = raw.index("|")
            link_id = int(raw[:sep])
            original_url = raw[sep + 1:]

    if original_url is None:
        result = await db.execute(select(Link).where(Link.slug == slug))
        link = result.scalar_one_or_none()

        if not link or not link.is_active:
            raise HTTPException(status_code=404, detail="Link not found")

        if link.expires_at is not None:
            expires = link.expires_at
            if expires.tzinfo is None:
                expires = expires.replace(tzinfo=timezone.utc)
            if expires < datetime.now(timezone.utc):
                raise HTTPException(status_code=410, detail="Link has expired")

        link_id = link.id
        original_url = link.original_url

        if redis:
            await redis.set(f"slug:{slug}", f"{link_id}|{original_url}", ex=3600)

    ua = request.headers.get("user-agent", "")
    referrer = request.headers.get("referer")
    # In production Nginx/Cloudflare set this header; unknown locally
    country = request.headers.get("cf-ipcountry") or request.headers.get("x-country")

    background_tasks.add_task(_record_click, link_id, country, _parse_device(ua), referrer)

    return RedirectResponse(url=original_url, status_code=302)
