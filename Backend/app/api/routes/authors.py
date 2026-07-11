from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_active_user, get_db
from app.models.user import User
from app.schemas.author import (
    AuthorCreate,
    AuthorListResponse,
    AuthorResponse,
    AuthorUpdate,
)
from app.services import author_service

router = APIRouter(prefix="/authors", tags=["authors"])


@router.post("", response_model=AuthorResponse, status_code=201)
async def create_author(
    body: AuthorCreate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> AuthorResponse:
    author = await author_service.create_author(session, user, body)
    await session.flush()
    await session.refresh(author)
    return AuthorResponse.model_validate(author)


@router.get("", response_model=AuthorListResponse)
async def list_authors(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> AuthorListResponse:
    items, total = await author_service.list_authors(
        session, user, limit=limit, offset=offset
    )
    return AuthorListResponse(
        items=[AuthorResponse.model_validate(a) for a in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{author_id}", response_model=AuthorResponse)
async def get_author(
    author_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> AuthorResponse:
    author = await author_service.get_author(session, user, author_id)
    return AuthorResponse.model_validate(author)


@router.patch("/{author_id}", response_model=AuthorResponse)
async def update_author(
    author_id: int,
    body: AuthorUpdate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> AuthorResponse:
    author = await author_service.update_author(session, user, author_id, body)
    await session.flush()
    await session.refresh(author)
    return AuthorResponse.model_validate(author)


@router.delete("/{author_id}", status_code=204)
async def delete_author(
    author_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> None:
    await author_service.delete_author(session, user, author_id)
