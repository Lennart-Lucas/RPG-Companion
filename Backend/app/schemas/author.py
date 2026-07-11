from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, field_validator

from app.schemas.resource_common import (
    ResourceListResponse,
    validate_name,
    validate_url,
)


class AuthorSource(str, Enum):
    website = "website"
    patreon = "patreon"
    drive = "drive"
    dropbox = "dropbox"
    mega = "mega"
    reddit = "reddit"
    homebrewery = "homebrewery"
    gmbinder = "gmbinder"


class AuthorLinkSchema(BaseModel):
    source: AuthorSource
    url: str = Field(min_length=1, max_length=512)

    @field_validator("url")
    @classmethod
    def check_url(cls, v: str) -> str:
        return validate_url(v)


class AuthorCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    links: list[AuthorLinkSchema] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str) -> str:
        return validate_name(v)


class AuthorUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    links: list[AuthorLinkSchema] | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str | None) -> str | None:
        if v is None:
            return v
        return validate_name(v)


class AuthorResponse(BaseModel):
    id: int
    name: str
    links: list[AuthorLinkSchema]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @field_validator("links", mode="before")
    @classmethod
    def normalize_links(cls, v):
        if v is None:
            return []
        return v


class AuthorListResponse(ResourceListResponse):
    items: list[AuthorResponse]
