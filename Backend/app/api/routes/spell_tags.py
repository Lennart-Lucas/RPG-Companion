from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_active_user, get_db
from app.models.user import User
from app.schemas.spell_tag import (
    SpellTagCreate,
    SpellTagListResponse,
    SpellTagResponse,
    SpellTagUpdate,
)
from app.services import spell_tag_service

router = APIRouter(prefix="/spell_tags", tags=["spell_tags"])


@router.post("", response_model=SpellTagResponse, status_code=201)
async def create_spell_tag(
    body: SpellTagCreate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> SpellTagResponse:
    spell_tag = await spell_tag_service.create_spell_tag(session, user, body)
    await session.flush()
    await session.refresh(spell_tag)
    return SpellTagResponse.model_validate(spell_tag)


@router.get("", response_model=SpellTagListResponse)
async def list_spell_tags(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> SpellTagListResponse:
    items, total = await spell_tag_service.list_spell_tags(
        session, user, limit=limit, offset=offset
    )
    return SpellTagListResponse(
        items=[SpellTagResponse.model_validate(item) for item in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{spell_tag_id}", response_model=SpellTagResponse)
async def get_spell_tag(
    spell_tag_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> SpellTagResponse:
    spell_tag = await spell_tag_service.get_spell_tag(session, user, spell_tag_id)
    return SpellTagResponse.model_validate(spell_tag)


@router.patch("/{spell_tag_id}", response_model=SpellTagResponse)
async def update_spell_tag(
    spell_tag_id: int,
    body: SpellTagUpdate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> SpellTagResponse:
    spell_tag = await spell_tag_service.update_spell_tag(
        session, user, spell_tag_id, body
    )
    await session.flush()
    await session.refresh(spell_tag)
    return SpellTagResponse.model_validate(spell_tag)


@router.delete("/{spell_tag_id}", status_code=204)
async def delete_spell_tag(
    spell_tag_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> None:
    await spell_tag_service.delete_spell_tag(session, user, spell_tag_id)
