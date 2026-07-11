import re

from pydantic import BaseModel, field_validator

SOURCE_VALUES = frozenset(
    {
        "website",
        "patreon",
        "drive",
        "dropbox",
        "mega",
        "reddit",
        "homebrewery",
        "gmbinder",
    }
)

URL_PATTERN = re.compile(r"^https?://", re.IGNORECASE)


def validate_name(value: str) -> str:
    stripped = value.strip()
    if not stripped:
        raise ValueError("name must not be empty")
    return stripped


def validate_url(value: str) -> str:
    stripped = value.strip()
    if not stripped:
        raise ValueError("url must not be empty")
    if not URL_PATTERN.match(stripped):
        raise ValueError("url must start with http:// or https://")
    return stripped


class ResourceListResponse(BaseModel):
    total: int
    limit: int
    offset: int
