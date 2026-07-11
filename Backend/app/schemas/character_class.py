from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.resource_common import ResourceListResponse, validate_name


class ClassCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    file_id: int | None = None
    caster: bool = False

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str) -> str:
        return validate_name(v)


class ClassUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    file_id: int | None = None
    caster: bool | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str | None) -> str | None:
        if v is None:
            return v
        return validate_name(v)


class ClassResponse(BaseModel):
    id: int
    name: str
    file_id: int | None
    caster: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ClassListResponse(ResourceListResponse):
    items: list[ClassResponse]
