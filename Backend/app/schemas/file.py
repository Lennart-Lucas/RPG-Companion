from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.resource_common import ResourceListResponse, validate_name, validate_url


class FileCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    address: str = Field(min_length=1, max_length=512)
    author_id: int | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str) -> str:
        return validate_name(v)

    @field_validator("address")
    @classmethod
    def strip_address(cls, v: str) -> str:
        return validate_url(v)


class FileUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    address: str | None = Field(default=None, min_length=1, max_length=512)
    author_id: int | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str | None) -> str | None:
        if v is None:
            return v
        return validate_name(v)

    @field_validator("address")
    @classmethod
    def strip_address(cls, v: str | None) -> str | None:
        if v is None:
            return v
        return validate_url(v)


class FileResponse(BaseModel):
    id: int
    name: str
    address: str
    author_id: int | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class FileListResponse(ResourceListResponse):
    items: list[FileResponse]
