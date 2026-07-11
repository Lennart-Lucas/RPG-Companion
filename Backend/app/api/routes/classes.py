from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_active_user, get_db
from app.models.user import User
from app.schemas.character_class import (
    ClassCreate,
    ClassListResponse,
    ClassResponse,
    ClassUpdate,
)
from app.services import class_service

router = APIRouter(prefix="/classes", tags=["classes"])


@router.post("", response_model=ClassResponse, status_code=201)
async def create_class(
    body: ClassCreate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> ClassResponse:
    character_class = await class_service.create_class(session, user, body)
    await session.flush()
    await session.refresh(character_class)
    return ClassResponse.model_validate(character_class)


@router.get("", response_model=ClassListResponse)
async def list_classes(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> ClassListResponse:
    items, total = await class_service.list_classes(
        session, user, limit=limit, offset=offset
    )
    return ClassListResponse(
        items=[ClassResponse.model_validate(item) for item in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{class_id}", response_model=ClassResponse)
async def get_class(
    class_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> ClassResponse:
    character_class = await class_service.get_class(session, user, class_id)
    return ClassResponse.model_validate(character_class)


@router.patch("/{class_id}", response_model=ClassResponse)
async def update_class(
    class_id: int,
    body: ClassUpdate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> ClassResponse:
    character_class = await class_service.update_class(
        session, user, class_id, body
    )
    await session.flush()
    await session.refresh(character_class)
    return ClassResponse.model_validate(character_class)


@router.delete("/{class_id}", status_code=204)
async def delete_class(
    class_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> None:
    await class_service.delete_class(session, user, class_id)
