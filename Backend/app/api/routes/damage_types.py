from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_active_user_id, get_db
from app.schemas.damage_type import (
    DamageTypeCreate,
    DamageTypeListResponse,
    DamageTypeResponse,
    DamageTypeUpdate,
)
from app.services import damage_type_service

router = APIRouter(prefix="/damage_types", tags=["damage_types"])


@router.post("", response_model=DamageTypeResponse, status_code=201)
async def create_damage_type(
    body: DamageTypeCreate,
    session: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_active_user_id),
) -> DamageTypeResponse:
    return await damage_type_service.create_damage_type(session, user_id, body)


@router.get("", response_model=DamageTypeListResponse)
async def list_damage_types(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_active_user_id),
) -> DamageTypeListResponse:
    items, total = await damage_type_service.list_damage_types(
        session, user_id, limit=limit, offset=offset
    )
    return DamageTypeListResponse(
        items=items,
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{damage_type_id}", response_model=DamageTypeResponse)
async def get_damage_type(
    damage_type_id: int,
    session: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_active_user_id),
) -> DamageTypeResponse:
    return await damage_type_service.get_damage_type(session, user_id, damage_type_id)


@router.patch("/{damage_type_id}", response_model=DamageTypeResponse)
async def update_damage_type(
    damage_type_id: int,
    body: DamageTypeUpdate,
    session: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_active_user_id),
) -> DamageTypeResponse:
    return await damage_type_service.update_damage_type(
        session, user_id, damage_type_id, body
    )


@router.delete("/{damage_type_id}", status_code=204)
async def delete_damage_type(
    damage_type_id: int,
    session: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_active_user_id),
) -> None:
    await damage_type_service.delete_damage_type(session, user_id, damage_type_id)
