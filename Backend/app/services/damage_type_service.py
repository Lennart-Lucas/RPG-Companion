from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.damage_type import DamageType
from app.models.user import User
from app.schemas.damage_type import DamageTypeCreate, DamageTypeUpdate
from app.services.resource_helpers import apply_list_filters, clamp_pagination, soft_delete


async def get_damage_type(
    session: AsyncSession, user: User, damage_type_id: int
) -> DamageType:
    result = await session.execute(
        select(DamageType).where(
            DamageType.id == damage_type_id,
            DamageType.user_id == user.id,
            DamageType.deleted_at.is_(None),
        )
    )
    damage_type = result.scalar_one_or_none()
    if damage_type is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Damage type not found",
        )
    return damage_type


async def create_damage_type(
    session: AsyncSession, user: User, data: DamageTypeCreate
) -> DamageType:
    damage_type = DamageType(
        user_id=user.id,
        name=data.name,
        description=data.description,
        icon=data.icon,
        color=data.color,
    )
    session.add(damage_type)
    await session.flush()
    return damage_type


async def list_damage_types(
    session: AsyncSession,
    user: User,
    *,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[DamageType], int]:
    limit, offset = clamp_pagination(limit, offset)
    base = select(DamageType).where(DamageType.user_id == user.id)
    base = apply_list_filters(base, DamageType)
    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await session.execute(count_stmt)).scalar_one()
    stmt = base.order_by(DamageType.name.asc()).limit(limit).offset(offset)
    result = await session.execute(stmt)
    return list(result.scalars().all()), total


async def update_damage_type(
    session: AsyncSession, user: User, damage_type_id: int, data: DamageTypeUpdate
) -> DamageType:
    damage_type = await get_damage_type(session, user, damage_type_id)
    fields_set = data.model_fields_set
    if data.name is not None:
        damage_type.name = data.name
    if "description" in fields_set:
        damage_type.description = data.description
    if "icon" in fields_set:
        damage_type.icon = data.icon
    if "color" in fields_set:
        damage_type.color = data.color
    await session.flush()
    return damage_type


async def delete_damage_type(
    session: AsyncSession, user: User, damage_type_id: int
) -> None:
    damage_type = await get_damage_type(session, user, damage_type_id)
    await soft_delete(damage_type)
