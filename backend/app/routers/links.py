from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, cast, Date
from app.database import get_db
from app.models.user import User
from app.models.link import Link
from app.models.click import Click
from app.schemas.link import (
    LinkCreate, LinkUpdate, LinkResponse, AnalyticsResponse,
    CountryBreakdown, DeviceBreakdown, ReferrerBreakdown, DailyClicks,
)
from app.dependencies import get_current_user
from app.utils.slug import generate_slug

router = APIRouter()


@router.get("/", response_model=list[LinkResponse])
async def list_links(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(Link, func.count(Click.id).label("click_count"))
        .outerjoin(Click, Click.link_id == Link.id)
        .where(Link.user_id == current_user.id)
        .group_by(Link.id)
        .order_by(Link.created_at.desc())
    )
    rows = (await db.execute(stmt)).all()
    return [
        LinkResponse(
            id=link.id, slug=link.slug, original_url=link.original_url,
            is_active=link.is_active, created_at=link.created_at,
            expires_at=link.expires_at, click_count=count or 0,
        )
        for link, count in rows
    ]


@router.post("/", response_model=LinkResponse, status_code=status.HTTP_201_CREATED)
async def create_link(
    body: LinkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    slug = body.slug or generate_slug()

    if body.slug:
        existing = await db.execute(select(Link).where(Link.slug == slug))
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=409, detail="Slug already taken")
    else:
        for _ in range(5):
            existing = await db.execute(select(Link).where(Link.slug == slug))
            if not existing.scalar_one_or_none():
                break
            slug = generate_slug()
        else:
            raise HTTPException(status_code=500, detail="Could not generate unique slug")

    link = Link(
        user_id=current_user.id,
        slug=slug,
        original_url=body.original_url,
        expires_at=body.expires_at,
    )
    db.add(link)
    await db.commit()
    await db.refresh(link)
    return LinkResponse(
        id=link.id, slug=link.slug, original_url=link.original_url,
        is_active=link.is_active, created_at=link.created_at,
        expires_at=link.expires_at, click_count=0,
    )


@router.patch("/{link_id}", response_model=LinkResponse)
async def update_link(
    link_id: int,
    body: LinkUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Link).where(Link.id == link_id, Link.user_id == current_user.id)
    )
    link = result.scalar_one_or_none()
    if not link:
        raise HTTPException(status_code=404, detail="Link not found")

    if body.is_active is not None:
        link.is_active = body.is_active
    if body.expires_at is not None:
        link.expires_at = body.expires_at

    await db.commit()
    await db.refresh(link)

    count = (await db.execute(
        select(func.count()).select_from(Click).where(Click.link_id == link.id)
    )).scalar() or 0

    return LinkResponse(
        id=link.id, slug=link.slug, original_url=link.original_url,
        is_active=link.is_active, created_at=link.created_at,
        expires_at=link.expires_at, click_count=count,
    )


@router.delete("/{link_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_link(
    link_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Link).where(Link.id == link_id, Link.user_id == current_user.id)
    )
    link = result.scalar_one_or_none()
    if not link:
        raise HTTPException(status_code=404, detail="Link not found")
    await db.delete(link)
    await db.commit()


@router.get("/{link_id}/analytics", response_model=AnalyticsResponse)
async def get_analytics(
    link_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Link).where(Link.id == link_id, Link.user_id == current_user.id)
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Link not found")

    total = (await db.execute(
        select(func.count()).select_from(Click).where(Click.link_id == link_id)
    )).scalar() or 0

    countries = (await db.execute(
        select(Click.country, func.count().label("n"))
        .where(Click.link_id == link_id)
        .group_by(Click.country)
        .order_by(func.count().desc())
    )).all()

    devices = (await db.execute(
        select(Click.device_type, func.count().label("n"))
        .where(Click.link_id == link_id)
        .group_by(Click.device_type)
        .order_by(func.count().desc())
    )).all()

    referrers = (await db.execute(
        select(Click.referrer, func.count().label("n"))
        .where(Click.link_id == link_id)
        .group_by(Click.referrer)
        .order_by(func.count().desc())
        .limit(10)
    )).all()

    daily = (await db.execute(
        select(cast(Click.clicked_at, Date).label("date"), func.count().label("n"))
        .where(Click.link_id == link_id)
        .group_by(cast(Click.clicked_at, Date))
        .order_by(cast(Click.clicked_at, Date))
    )).all()

    return AnalyticsResponse(
        total_clicks=total,
        by_country=[CountryBreakdown(country=r[0] or "Unknown", count=r[1]) for r in countries],
        by_device=[DeviceBreakdown(device_type=r[0] or "Unknown", count=r[1]) for r in devices],
        by_referrer=[ReferrerBreakdown(referrer=r[0] or "Direct", count=r[1]) for r in referrers],
        daily=[DailyClicks(date=str(r[0]), count=r[1]) for r in daily],
    )
