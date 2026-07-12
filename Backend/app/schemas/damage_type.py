from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.resource_common import ResourceListResponse, validate_name


class DamageTypeCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    description: str | None = None
    icon: str | None = Field(default=None, max_length=255)
    color: int | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str) -> str:
        return validate_name(v)

    @field_validator("icon")
    @classmethod
    def strip_icon(cls, v: str | None) -> str | None:
        if v is None:
            return v
        trimmed = v.strip()
        return trimmed or None


class DamageTypeUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    icon: str | None = Field(default=None, max_length=255)
    color: int | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str | None) -> str | None:
        if v is None:
            return v
        return validate_name(v)

    @field_validator("icon")
    @classmethod
    def strip_icon(cls, v: str | None) -> str | None:
        if v is None:
            return v
        trimmed = v.strip()
        return trimmed or None


class DamageTypeResponse(BaseModel):
    id: int
    name: str
    description: str | None
    icon: str | None
    color: int | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class DamageTypeListResponse(ResourceListResponse):
    items: list[DamageTypeResponse]
