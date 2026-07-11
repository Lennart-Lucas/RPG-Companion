from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.author import Author
from app.models.file import ResourceFile


def clamp_pagination(limit: int, offset: int) -> tuple[int, int]:
    return min(max(limit, 1), 100), max(offset, 0)


def apply_list_filters(stmt, model, *, updated_since: datetime | None = None):
    stmt = stmt.where(model.deleted_at.is_(None))
    if updated_since is not None:
        since = updated_since if updated_since.tzinfo else updated_since.replace(tzinfo=UTC)
        stmt = stmt.where(model.updated_at > since)
    return stmt


async def soft_delete(entity) -> None:
    entity.deleted_at = datetime.now(UTC)


async def get_author_owned(
    session: AsyncSession, author_id: int, user_id: int
) -> Author:
    result = await session.execute(
        select(Author).where(
            Author.id == author_id,
            Author.user_id == user_id,
            Author.deleted_at.is_(None),
        )
    )
    author = result.scalar_one_or_none()
    if author is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Author not found",
        )
    return author


async def assert_author_owned(
    session: AsyncSession, author_id: int | None, user_id: int
) -> None:
    if author_id is not None:
        await get_author_owned(session, author_id, user_id)
