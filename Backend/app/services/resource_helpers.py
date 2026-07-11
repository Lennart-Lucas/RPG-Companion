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


async def get_file_owned(
    session: AsyncSession, file_id: int, user_id: int
) -> ResourceFile:
    result = await session.execute(
        select(ResourceFile).where(
            ResourceFile.id == file_id,
            ResourceFile.user_id == user_id,
            ResourceFile.deleted_at.is_(None),
        )
    )
    resource_file = result.scalar_one_or_none()
    if resource_file is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found",
        )
    return resource_file


async def assert_file_owned(
    session: AsyncSession, file_id: int | None, user_id: int
) -> None:
    if file_id is not None:
        await get_file_owned(session, file_id, user_id)


async def get_caster_class_owned(
    session: AsyncSession, class_id: int, user_id: int
):
    from app.models.character_class import CharacterClass

    result = await session.execute(
        select(CharacterClass).where(
            CharacterClass.id == class_id,
            CharacterClass.user_id == user_id,
            CharacterClass.deleted_at.is_(None),
        )
    )
    character_class = result.scalar_one_or_none()
    if character_class is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Class not found",
        )
    if not character_class.caster:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Class '{character_class.name}' is not a spell caster",
        )
    return character_class


async def assert_spell_tags_owned(
    session: AsyncSession, tag_ids: list[int], user_id: int
) -> None:
    if not tag_ids:
        return

    from app.models.spell_tag import SpellTag

    result = await session.execute(
        select(SpellTag.id).where(
            SpellTag.id.in_(tag_ids),
            SpellTag.user_id == user_id,
            SpellTag.deleted_at.is_(None),
        )
    )
    found = set(result.scalars().all())
    missing = set(tag_ids) - found
    if missing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Spell tag not found",
        )
