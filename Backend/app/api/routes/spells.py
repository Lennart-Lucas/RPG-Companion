from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_active_user, get_db
from app.models.user import User
from app.schemas.spell import SpellCreate, SpellListResponse, SpellResponse, SpellUpdate
from app.services import spell_service

router = APIRouter(prefix="/spells", tags=["spells"])


@router.post("", response_model=SpellResponse, status_code=201)
async def create_spell(
    body: SpellCreate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> SpellResponse:
    return await spell_service.create_spell(session, user, body)


@router.get("", response_model=SpellListResponse)
async def list_spells(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> SpellListResponse:
    items, total = await spell_service.list_spells(
        session, user, limit=limit, offset=offset
    )
    return SpellListResponse(
        items=items,
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{spell_id}", response_model=SpellResponse)
async def get_spell(
    spell_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> SpellResponse:
    return await spell_service.get_spell(session, user, spell_id)


@router.patch("/{spell_id}", response_model=SpellResponse)
async def update_spell(
    spell_id: int,
    body: SpellUpdate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> SpellResponse:
    return await spell_service.update_spell(session, user, spell_id, body)


@router.delete("/{spell_id}", status_code=204)
async def delete_spell(
    spell_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> None:
    await spell_service.delete_spell(session, user, spell_id)
