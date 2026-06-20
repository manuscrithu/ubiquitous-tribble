from datetime import datetime
from pydantic import BaseModel, field_validator


class LinkCreate(BaseModel):
    original_url: str
    slug: str | None = None
    expires_at: datetime | None = None

    @field_validator("original_url")
    @classmethod
    def must_be_http(cls, v: str) -> str:
        if not v.startswith(("http://", "https://")):
            raise ValueError("URL must start with http:// or https://")
        return v


class LinkUpdate(BaseModel):
    is_active: bool | None = None
    expires_at: datetime | None = None


class LinkResponse(BaseModel):
    id: int
    slug: str
    original_url: str
    is_active: bool
    created_at: datetime
    expires_at: datetime | None
    click_count: int = 0

    model_config = {"from_attributes": True}


class CountryBreakdown(BaseModel):
    country: str
    count: int


class DeviceBreakdown(BaseModel):
    device_type: str
    count: int


class ReferrerBreakdown(BaseModel):
    referrer: str
    count: int


class DailyClicks(BaseModel):
    date: str
    count: int


class AnalyticsResponse(BaseModel):
    total_clicks: int
    by_country: list[CountryBreakdown]
    by_device: list[DeviceBreakdown]
    by_referrer: list[ReferrerBreakdown]
    daily: list[DailyClicks]
