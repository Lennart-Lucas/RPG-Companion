from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_active_user, get_db
from app.models.user import User
from app.schemas.file import (
    FileCreate,
    FileListResponse,
    FileResponse,
    FileUpdate,
)
from app.services import file_service

router = APIRouter(prefix="/files", tags=["files"])


@router.post("", response_model=FileResponse, status_code=201)
async def create_file(
    body: FileCreate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> FileResponse:
    resource_file = await file_service.create_file(session, user, body)
    await session.flush()
    await session.refresh(resource_file)
    return FileResponse.model_validate(resource_file)


@router.get("", response_model=FileListResponse)
async def list_files(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    author_id: int | None = Query(default=None),
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> FileListResponse:
    items, total = await file_service.list_files(
        session, user, limit=limit, offset=offset, author_id=author_id
    )
    return FileListResponse(
        items=[FileResponse.model_validate(f) for f in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{file_id}", response_model=FileResponse)
async def get_file(
    file_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> FileResponse:
    resource_file = await file_service.get_file(session, user, file_id)
    return FileResponse.model_validate(resource_file)


@router.patch("/{file_id}", response_model=FileResponse)
async def update_file(
    file_id: int,
    body: FileUpdate,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> FileResponse:
    resource_file = await file_service.update_file(session, user, file_id, body)
    await session.flush()
    await session.refresh(resource_file)
    return FileResponse.model_validate(resource_file)


@router.delete("/{file_id}", status_code=204)
async def delete_file(
    file_id: int,
    session: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_active_user),
) -> None:
    await file_service.delete_file(session, user, file_id)
