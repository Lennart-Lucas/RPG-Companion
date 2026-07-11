from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.author import Author
from app.models.user import User
from app.schemas.author import AuthorCreate, AuthorUpdate
from app.services.resource_helpers import (
    apply_list_filters,
    clamp_pagination,
    get_author_owned,
    soft_delete,
)


async def get_author(
    session: AsyncSession, user: User, author_id: int
) -> Author:
    return await get_author_owned(session, author_id, user.id)


async def create_author(
    session: AsyncSession, user: User, data: AuthorCreate
) -> Author:
    links = [link.model_dump() for link in data.links]
    author = Author(user_id=user.id, name=data.name, links=links)
    session.add(author)
    await session.flush()
    return author


async def list_authors(
    session: AsyncSession,
    user: User,
    *,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[Author], int]:
    limit, offset = clamp_pagination(limit, offset)
    base = select(Author).where(Author.user_id == user.id)
    base = apply_list_filters(base, Author)
    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await session.execute(count_stmt)).scalar_one()
    stmt = base.order_by(Author.name.asc()).limit(limit).offset(offset)
    result = await session.execute(stmt)
    return list(result.scalars().all()), total


async def update_author(
    session: AsyncSession, user: User, author_id: int, data: AuthorUpdate
) -> Author:
    author = await get_author_owned(session, author_id, user.id)
    if data.name is not None:
        author.name = data.name
    if data.links is not None:
        author.links = [link.model_dump() for link in data.links]
    await session.flush()
    return author


async def delete_author(
    session: AsyncSession, user: User, author_id: int
) -> None:
    author = await get_author_owned(session, author_id, user.id)
    await soft_delete(author)
