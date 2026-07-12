from datetime import UTC, datetime

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.damage_type import (
    DamageTypeCreate,
    DamageTypeResponse,
    DamageTypeUpdate,
)
from app.services.resource_helpers import clamp_pagination

_INSERT_SQL = text(
    """
    INSERT INTO damage_types (user_id, name, description, icon, color)
    VALUES (:user_id, :name, :description, :icon, :color)
    RETURNING id, name, description, icon, color, created_at, updated_at
    """
)

_SELECT_SQL = text(
    """
    SELECT id, name, description, icon, color, created_at, updated_at
    FROM damage_types
    WHERE id = :damage_type_id
      AND user_id = :user_id
      AND deleted_at IS NULL
    """
)

_LIST_SQL = text(
    """
    SELECT id, name, description, icon, color, created_at, updated_at
    FROM damage_types
    WHERE user_id = :user_id
      AND deleted_at IS NULL
    ORDER BY name ASC
    LIMIT :limit OFFSET :offset
    """
)

_COUNT_SQL = text(
    """
    SELECT COUNT(*)
    FROM damage_types
    WHERE user_id = :user_id
      AND deleted_at IS NULL
    """
)

_DELETE_SQL = text(
    """
    UPDATE damage_types
    SET deleted_at = :deleted_at
    WHERE id = :damage_type_id
      AND user_id = :user_id
      AND deleted_at IS NULL
    RETURNING id
    """
)


def _response_from_row(row) -> DamageTypeResponse:
    mapping = row._mapping if hasattr(row, "_mapping") else row
    return DamageTypeResponse(
        id=mapping["id"],
        name=mapping["name"],
        description=mapping["description"],
        icon=mapping["icon"],
        color=mapping["color"],
        created_at=mapping["created_at"],
        updated_at=mapping["updated_at"],
    )


def _update_params(data: DamageTypeUpdate) -> dict[str, object]:
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
    return values


def _build_update_sql(values: dict[str, object]):
    assignments = ", ".join(f"{column} = :{column}" for column in values)
    return text(
        f"""
        UPDATE damage_types
        SET {assignments}
        WHERE id = :damage_type_id
          AND user_id = :user_id
          AND deleted_at IS NULL
        RETURNING id, name, description, icon, color, created_at, updated_at
        """
    )


async def get_damage_type(
    session: AsyncSession, user_id: int, damage_type_id: int
) -> DamageTypeResponse:
    result = await session.execute(
        _SELECT_SQL,
        {"damage_type_id": damage_type_id, "user_id": user_id},
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
        _INSERT_SQL,
        {
            "user_id": user_id,
            "name": data.name,
            "description": data.description,
            "icon": data.icon,
            "color": data.color,
        },
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
    total = (
        await session.execute(_COUNT_SQL, {"user_id": user_id})
    ).scalar_one()
    result = await session.execute(
        _LIST_SQL,
        {"user_id": user_id, "limit": limit, "offset": offset},
    )
    items = [_response_from_row(row) for row in result.all()]
    return items, total


async def update_damage_type(
    session: AsyncSession,
    user_id: int,
    damage_type_id: int,
    data: DamageTypeUpdate,
) -> DamageTypeResponse:
    values = _update_params(data)
    if not values:
        return await get_damage_type(session, user_id, damage_type_id)

    result = await session.execute(
        _build_update_sql(values),
        {
            **values,
            "damage_type_id": damage_type_id,
            "user_id": user_id,
        },
    )
    row = result.one_or_none()
    if row is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Damage type not found",
        )
    return _response_from_row(row)


async def delete_damage_type(
    session: AsyncSession, user_id: int, damage_type_id: int
) -> None:
    result = await session.execute(
        _DELETE_SQL,
        {
            "damage_type_id": damage_type_id,
            "user_id": user_id,
            "deleted_at": datetime.now(UTC),
        },
    )
    if result.one_or_none() is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Damage type not found",
        )
