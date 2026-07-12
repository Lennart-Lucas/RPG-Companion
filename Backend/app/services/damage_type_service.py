from datetime import UTC, datetime

from sqlalchemy import func, insert, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.damage_type import DamageType
from app.schemas.damage_type import (
    DamageTypeCreate,
    DamageTypeResponse,
    DamageTypeUpdate,
)
from app.services.resource_helpers import clamp_pagination

_damage_types = DamageType.__table__

_RETURNING = (
    _damage_types.c.id,
    _damage_types.c.name,
    _damage_types.c.description,
    _damage_types.c.icon,
    _damage_types.c.color,
    _damage_types.c.created_at,
    _damage_types.c.updated_at,
)

_ACTIVE = _damage_types.c.deleted_at.is_(None)


def _response_from_row(row) -> DamageTypeResponse:
    return DamageTypeResponse(**row._mapping)


def _owned(user_id: int, damage_type_id: int):
    return (
        _damage_types.c.id == damage_type_id,
        _damage_types.c.user_id == user_id,
        _ACTIVE,
    )


async def get_damage_type(
    session: AsyncSession, user_id: int, damage_type_id: int
) -> DamageTypeResponse:
    result = await session.execute(
        select(*_RETURNING).where(*_owned(user_id, damage_type_id))
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
    session: AsyncSession, user_id: int, data: DamageTypeCreate
) -> DamageTypeResponse:
    result = await session.execute(
        insert(_damage_types)
        .values(
            user_id=user_id,
            name=data.name,
            description=data.description,
            icon=data.icon,
            color=data.color,
        )
        .returning(*_RETURNING)
    )
    return _response_from_row(result.one())


async def list_damage_types(
    session: AsyncSession,
    user_id: int,
    *,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[DamageTypeResponse], int]:
    limit, offset = clamp_pagination(limit, offset)
    count_stmt = (
        select(func.count())
        .select_from(_damage_types)
        .where(_damage_types.c.user_id == user_id, _ACTIVE)
    )
    total = (await session.execute(count_stmt)).scalar_one()
    stmt = (
        select(*_RETURNING)
        .where(_damage_types.c.user_id == user_id, _ACTIVE)
        .order_by(_damage_types.c.name.asc())
        .limit(limit)
        .offset(offset)
    )
    result = await session.execute(stmt)
    items = [_response_from_row(row) for row in result.all()]
    return items, total


async def update_damage_type(
    session: AsyncSession,
    user_id: int,
    damage_type_id: int,
    data: DamageTypeUpdate,
) -> DamageTypeResponse:
    await get_damage_type(session, user_id, damage_type_id)

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
        return await get_damage_type(session, user_id, damage_type_id)

    result = await session.execute(
        update(_damage_types)
        .where(*_owned(user_id, damage_type_id))
        .values(**values)
        .returning(*_RETURNING)
    )
    return _response_from_row(result.one())


async def delete_damage_type(
    session: AsyncSession, user_id: int, damage_type_id: int
) -> None:
    result = await session.execute(
        update(_damage_types)
        .where(*_owned(user_id, damage_type_id))
        .values(deleted_at=datetime.now(UTC))
        .returning(_damage_types.c.id)
    )
    if result.one_or_none() is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Damage type not found",
        )
