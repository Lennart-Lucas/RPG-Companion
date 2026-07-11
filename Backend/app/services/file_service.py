from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.file import ResourceFile
from app.models.user import User
from app.schemas.file import FileCreate, FileUpdate
from app.services.resource_helpers import (
    apply_list_filters,
    assert_author_owned,
    clamp_pagination,
    get_author_owned,
    soft_delete,
)


async def get_file(
    session: AsyncSession, user: User, file_id: int
) -> ResourceFile:
    result = await session.execute(
        select(ResourceFile).where(
            ResourceFile.id == file_id,
            ResourceFile.user_id == user.id,
            ResourceFile.deleted_at.is_(None),
        )
    )
    resource_file = result.scalar_one_or_none()
    if resource_file is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found",
        )
    return resource_file


async def create_file(
    session: AsyncSession, user: User, data: FileCreate
) -> ResourceFile:
    await assert_author_owned(session, data.author_id, user.id)
    resource_file = ResourceFile(
        user_id=user.id,
        name=data.name,
        address=data.address,
        author_id=data.author_id,
    )
    session.add(resource_file)
    await session.flush()
    return resource_file


async def list_files(
    session: AsyncSession,
    user: User,
    *,
    limit: int = 50,
    offset: int = 0,
    author_id: int | None = None,
) -> tuple[list[ResourceFile], int]:
    limit, offset = clamp_pagination(limit, offset)
    if author_id is not None:
        await get_author_owned(session, author_id, user.id)
    base = select(ResourceFile).where(ResourceFile.user_id == user.id)
    base = apply_list_filters(base, ResourceFile)
    if author_id is not None:
        base = base.where(ResourceFile.author_id == author_id)
    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await session.execute(count_stmt)).scalar_one()
    stmt = base.order_by(ResourceFile.name.asc()).limit(limit).offset(offset)
    result = await session.execute(stmt)
    return list(result.scalars().all()), total


async def update_file(
    session: AsyncSession, user: User, file_id: int, data: FileUpdate
) -> ResourceFile:
    resource_file = await get_file(session, user, file_id)
    fields_set = data.model_fields_set
    if "author_id" in fields_set:
        if data.author_id is not None:
            await assert_author_owned(session, data.author_id, user.id)
        resource_file.author_id = data.author_id
    if data.name is not None:
        resource_file.name = data.name
    if data.address is not None:
        resource_file.address = data.address
    await session.flush()
    return resource_file


async def delete_file(
    session: AsyncSession, user: User, file_id: int
) -> None:
    resource_file = await get_file(session, user, file_id)
    await soft_delete(resource_file)
