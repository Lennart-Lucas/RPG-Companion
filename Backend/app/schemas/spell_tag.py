from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.resource_common import ResourceListResponse, validate_name


class SpellTagCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    description: str | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str) -> str:
        return validate_name(v)


class SpellTagUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str | None) -> str | None:
        if v is None:
            return v
        return validate_name(v)


class SpellTagResponse(BaseModel):
    id: int
    name: str
    description: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class SpellTagListResponse(ResourceListResponse):
    items: list[SpellTagResponse]
