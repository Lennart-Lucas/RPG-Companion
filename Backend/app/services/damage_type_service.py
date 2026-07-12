from sqlalchemy import func, insert, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.damage_type import DamageType
from app.models.user import User
from app.schemas.damage_type import (
    DamageTypeCreate,
    DamageTypeResponse,
    DamageTypeUpdate,
)
from app.services.resource_helpers import apply_list_filters, clamp_pagination, soft_delete

_DAMAGE_TYPE_RESPONSE_COLUMNS = (
    DamageType.id,
    DamageType.name,
    DamageType.description,
    DamageType.icon,
    DamageType.color,
    DamageType.created_at,
    DamageType.updated_at,
)


def _response_from_row(row) -> DamageTypeResponse:
    return DamageTypeResponse(**row._mapping)


async def _fetch_damage_type_response(
    session: AsyncSession, damage_type_id: int, user_id: int
) -> DamageTypeResponse:
    result = await session.execute(
        select(*_DAMAGE_TYPE_RESPONSE_COLUMNS).where(
            DamageType.id == damage_type_id,
            DamageType.user_id == user_id,
            DamageType.deleted_at.is_(None),
        )
    )
    row = result.one()
    return _response_from_row(row)


async def get_damage_type(
    session: AsyncSession, user: User, damage_type_id: int
) -> DamageTypeResponse:
    result = await session.execute(
        select(*_DAMAGE_TYPE_RESPONSE_COLUMNS).where(
            DamageType.id == damage_type_id,
            DamageType.user_id == user.id,
            DamageType.deleted_at.is_(None),
        )
    )
    row = result.one_or_none()
    if row is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Damage type not found",
        )
    return _response_from_row(row)


async def create_damage_type(
    session: AsyncSession, user: User, data: DamageTypeCreate
) -> DamageTypeResponse:
    result = await session.execute(
        insert(DamageType)
        .values(
            user_id=user.id,
            name=data.name,
            description=data.description,
            icon=data.icon,
            color=data.color,
        )
        .returning(*_DAMAGE_TYPE_RESPONSE_COLUMNS)
    )
    return _response_from_row(result.one())


async def list_damage_types(
    session: AsyncSession,
    user: User,
    *,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[DamageTypeResponse], int]:
    limit, offset = clamp_pagination(limit, offset)
    base = select(DamageType).where(DamageType.user_id == user.id)
    base = apply_list_filters(base, DamageType)
    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await session.execute(count_stmt)).scalar_one()
    stmt = (
        select(*_DAMAGE_TYPE_RESPONSE_COLUMNS)
        .where(
            DamageType.user_id == user.id,
            DamageType.deleted_at.is_(None),
        )
        .order_by(DamageType.name.asc())
        .limit(limit)
        .offset(offset)
    )
    result = await session.execute(stmt)
    items = [_response_from_row(row) for row in result.all()]
    return items, total


async def update_damage_type(
    session: AsyncSession, user: User, damage_type_id: int, data: DamageTypeUpdate
) -> DamageTypeResponse:
    await get_damage_type(session, user, damage_type_id)

    values: dict[str, object] = {}
    fields_set = data.model_fields_set
    if data.name is not None:
        values["name"] = data.name
    if "description" in fields_set:
        values["description"] = data.description
    if "icon" in fields_set:
        values["icon"] = data.icon
    if "color" in fields_set:
        values["color"] = data.color

    if not values:
        return await _fetch_damage_type_response(session, damage_type_id, user.id)

    result = await session.execute(
        update(DamageType)
        .where(
            DamageType.id == damage_type_id,
            DamageType.user_id == user.id,
            DamageType.deleted_at.is_(None),
        )
        .values(**values)
        .returning(*_DAMAGE_TYPE_RESPONSE_COLUMNS)
    )
    row = result.one()
    return _response_from_row(row)


async def delete_damage_type(
    session: AsyncSession, user: User, damage_type_id: int
) -> None:
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
    await soft_delete(damage_type)
