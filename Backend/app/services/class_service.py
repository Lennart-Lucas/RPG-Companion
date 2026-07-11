from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.character_class import CharacterClass
from app.models.user import User
from app.schemas.character_class import ClassCreate, ClassUpdate
from app.services.resource_helpers import (
    apply_list_filters,
    assert_file_owned,
    clamp_pagination,
    soft_delete,
)


async def get_class(
    session: AsyncSession, user: User, class_id: int
) -> CharacterClass:
    result = await session.execute(
        select(CharacterClass).where(
            CharacterClass.id == class_id,
            CharacterClass.user_id == user.id,
            CharacterClass.deleted_at.is_(None),
        )
    )
    character_class = result.scalar_one_or_none()
    if character_class is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Class not found",
        )
    return character_class


async def create_class(
    session: AsyncSession, user: User, data: ClassCreate
) -> CharacterClass:
    await assert_file_owned(session, data.file_id, user.id)
    character_class = CharacterClass(
        user_id=user.id,
        name=data.name,
        file_id=data.file_id,
        caster=data.caster,
    )
    session.add(character_class)
    await session.flush()
    return character_class


async def list_classes(
    session: AsyncSession,
    user: User,
    *,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[CharacterClass], int]:
    limit, offset = clamp_pagination(limit, offset)
    base = select(CharacterClass).where(CharacterClass.user_id == user.id)
    base = apply_list_filters(base, CharacterClass)
    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await session.execute(count_stmt)).scalar_one()
    stmt = base.order_by(CharacterClass.name.asc()).limit(limit).offset(offset)
    result = await session.execute(stmt)
    return list(result.scalars().all()), total


async def update_class(
    session: AsyncSession, user: User, class_id: int, data: ClassUpdate
) -> CharacterClass:
    character_class = await get_class(session, user, class_id)
    fields_set = data.model_fields_set
    if "file_id" in fields_set:
        if data.file_id is not None:
            await assert_file_owned(session, data.file_id, user.id)
        character_class.file_id = data.file_id
    if data.name is not None:
        character_class.name = data.name
    if data.caster is not None:
        character_class.caster = data.caster
    await session.flush()
    return character_class


async def delete_class(
    session: AsyncSession, user: User, class_id: int
) -> None:
    character_class = await get_class(session, user, class_id)
    await soft_delete(character_class)
