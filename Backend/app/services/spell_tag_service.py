from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.spell_tag import SpellTag
from app.models.user import User
from app.schemas.spell_tag import SpellTagCreate, SpellTagUpdate
from app.services.resource_helpers import apply_list_filters, clamp_pagination, soft_delete


async def get_spell_tag(
    session: AsyncSession, user: User, spell_tag_id: int
) -> SpellTag:
    result = await session.execute(
        select(SpellTag).where(
            SpellTag.id == spell_tag_id,
            SpellTag.user_id == user.id,
            SpellTag.deleted_at.is_(None),
        )
    )
    spell_tag = result.scalar_one_or_none()
    if spell_tag is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Spell tag not found",
        )
    return spell_tag


async def create_spell_tag(
    session: AsyncSession, user: User, data: SpellTagCreate
) -> SpellTag:
    spell_tag = SpellTag(
        user_id=user.id,
        name=data.name,
        description=data.description,
    )
    session.add(spell_tag)
    await session.flush()
    return spell_tag


async def list_spell_tags(
    session: AsyncSession,
    user: User,
    *,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[SpellTag], int]:
    limit, offset = clamp_pagination(limit, offset)
    base = select(SpellTag).where(SpellTag.user_id == user.id)
    base = apply_list_filters(base, SpellTag)
    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await session.execute(count_stmt)).scalar_one()
    stmt = base.order_by(SpellTag.name.asc()).limit(limit).offset(offset)
    result = await session.execute(stmt)
    return list(result.scalars().all()), total


async def update_spell_tag(
    session: AsyncSession, user: User, spell_tag_id: int, data: SpellTagUpdate
) -> SpellTag:
    spell_tag = await get_spell_tag(session, user, spell_tag_id)
    fields_set = data.model_fields_set
    if data.name is not None:
        spell_tag.name = data.name
    if "description" in fields_set:
        spell_tag.description = data.description
    await session.flush()
    return spell_tag


async def delete_spell_tag(
    session: AsyncSession, user: User, spell_tag_id: int
) -> None:
    spell_tag = await get_spell_tag(session, user, spell_tag_id)
    await soft_delete(spell_tag)
