from sqlalchemy import delete, func, insert, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.spell import Spell, spell_classes, spell_spell_tags
from app.models.user import User
from app.schemas.spell import (
    CastingType,
    SpellCreate,
    SpellResponse,
    SpellUpdate,
)
from app.services.resource_helpers import (
    apply_list_filters,
    assert_file_owned,
    assert_spell_tags_owned,
    clamp_pagination,
    get_caster_class_owned,
    soft_delete,
)


def _validate_trigger_and_materials_for_update(
    spell: Spell,
    data: SpellUpdate,
) -> None:
    casting_type = (
        data.casting_type.value
        if data.casting_type is not None
        else spell.casting_type
    )
    trigger = (
        data.trigger
        if "trigger" in data.model_fields_set
        else spell.trigger
    )
    component_material = (
        data.component_material
        if data.component_material is not None
        else spell.component_material
    )
    materials = (
        data.materials
        if "materials" in data.model_fields_set
        else spell.materials
    )

    if casting_type == CastingType.reaction.value:
        if trigger is None or not str(trigger).strip():
            from fastapi import HTTPException, status

            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Trigger is required when casting type is reaction",
            )
    elif trigger is not None and str(trigger).strip():
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Trigger is only allowed when casting type is reaction",
        )

    if component_material:
        if materials is None or not str(materials).strip():
            from fastapi import HTTPException, status

            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Materials are required when material component is selected",
            )
    elif materials is not None and str(materials).strip():
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Materials are only allowed when material component is selected",
        )


async def _fetch_class_ids(session: AsyncSession, spell_id: int) -> list[int]:
    result = await session.execute(
        select(spell_classes.c.class_id).where(spell_classes.c.spell_id == spell_id)
    )
    return list(result.scalars().all())


async def _fetch_spell_tag_ids(session: AsyncSession, spell_id: int) -> list[int]:
    result = await session.execute(
        select(spell_spell_tags.c.spell_tag_id).where(
            spell_spell_tags.c.spell_id == spell_id
        )
    )
    return list(result.scalars().all())


async def _replace_spell_classes(
    session: AsyncSession, spell_id: int, class_ids: list[int]
) -> None:
    await session.execute(
        delete(spell_classes).where(spell_classes.c.spell_id == spell_id)
    )
    if class_ids:
        await session.execute(
            insert(spell_classes),
            [{"spell_id": spell_id, "class_id": class_id} for class_id in class_ids],
        )


async def _replace_spell_tags(
    session: AsyncSession, spell_id: int, tag_ids: list[int]
) -> None:
    await session.execute(
        delete(spell_spell_tags).where(spell_spell_tags.c.spell_id == spell_id)
    )
    if tag_ids:
        await session.execute(
            insert(spell_spell_tags),
            [
                {"spell_id": spell_id, "spell_tag_id": tag_id}
                for tag_id in tag_ids
            ],
        )


async def _clear_spell_relations(session: AsyncSession, spell_id: int) -> None:
    await _replace_spell_classes(session, spell_id, [])
    await _replace_spell_tags(session, spell_id, [])


def spell_to_response(
    spell: Spell,
    *,
    class_ids: list[int],
    spell_tag_ids: list[int],
) -> SpellResponse:
    return SpellResponse(
        id=spell.id,
        name=spell.name,
        file_id=spell.file_id,
        level=spell.level,
        school=spell.school,
        casting_time=spell.casting_time,
        casting_type=spell.casting_type,
        trigger=spell.trigger,
        duration=spell.duration,
        concentration=spell.concentration,
        range=spell.spell_range,
        component_verbal=spell.component_verbal,
        component_somatic=spell.component_somatic,
        component_material=spell.component_material,
        materials=spell.materials,
        description=spell.description,
        higher_levels=spell.higher_levels,
        class_ids=class_ids,
        spell_tag_ids=spell_tag_ids,
        created_at=spell.created_at,
        updated_at=spell.updated_at,
    )


async def get_spell(session: AsyncSession, user: User, spell_id: int) -> SpellResponse:
    result = await session.execute(
        select(Spell).where(
            Spell.id == spell_id,
            Spell.user_id == user.id,
            Spell.deleted_at.is_(None),
        )
    )
    spell = result.scalar_one_or_none()
    if spell is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Spell not found",
        )
    class_ids = await _fetch_class_ids(session, spell.id)
    spell_tag_ids = await _fetch_spell_tag_ids(session, spell.id)
    return spell_to_response(
        spell,
        class_ids=class_ids,
        spell_tag_ids=spell_tag_ids,
    )


async def create_spell(
    session: AsyncSession, user: User, data: SpellCreate
) -> SpellResponse:
    await assert_file_owned(session, data.file_id, user.id)
    for class_id in data.class_ids:
        await get_caster_class_owned(session, class_id, user.id)
    await assert_spell_tags_owned(session, data.spell_tag_ids, user.id)

    spell = Spell(
        user_id=user.id,
        file_id=data.file_id,
        name=data.name,
        level=data.level.value,
        school=data.school.value,
        casting_time=data.casting_time,
        casting_type=data.casting_type.value,
        trigger=data.trigger.strip() if data.trigger else None,
        duration=data.duration.value,
        concentration=data.concentration,
        spell_range=data.range.value,
        component_verbal=data.component_verbal,
        component_somatic=data.component_somatic,
        component_material=data.component_material,
        materials=data.materials.strip() if data.materials else None,
        description=data.description,
        higher_levels=data.higher_levels,
    )
    session.add(spell)
    await session.flush()
    await _replace_spell_classes(session, spell.id, data.class_ids)
    await _replace_spell_tags(session, spell.id, data.spell_tag_ids)
    await session.flush()
    return spell_to_response(
        spell,
        class_ids=data.class_ids,
        spell_tag_ids=data.spell_tag_ids,
    )


async def list_spells(
    session: AsyncSession,
    user: User,
    *,
    limit: int = 50,
    offset: int = 0,
) -> tuple[list[SpellResponse], int]:
    limit, offset = clamp_pagination(limit, offset)
    base = select(Spell).where(Spell.user_id == user.id)
    base = apply_list_filters(base, Spell)
    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await session.execute(count_stmt)).scalar_one()
    stmt = base.order_by(Spell.name.asc()).limit(limit).offset(offset)
    result = await session.execute(stmt)
    spells = list(result.scalars().all())

    responses: list[SpellResponse] = []
    for spell in spells:
        class_ids = await _fetch_class_ids(session, spell.id)
        spell_tag_ids = await _fetch_spell_tag_ids(session, spell.id)
        responses.append(
            spell_to_response(
                spell,
                class_ids=class_ids,
                spell_tag_ids=spell_tag_ids,
            )
        )
    return responses, total


async def update_spell(
    session: AsyncSession, user: User, spell_id: int, data: SpellUpdate
) -> SpellResponse:
    result = await session.execute(
        select(Spell).where(
            Spell.id == spell_id,
            Spell.user_id == user.id,
            Spell.deleted_at.is_(None),
        )
    )
    spell = result.scalar_one_or_none()
    if spell is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Spell not found",
        )

    fields_set = data.model_fields_set
    if "file_id" in fields_set:
        if data.file_id is not None:
            await assert_file_owned(session, data.file_id, user.id)
        spell.file_id = data.file_id
    if data.name is not None:
        spell.name = data.name
    if data.level is not None:
        spell.level = data.level.value
    if data.school is not None:
        spell.school = data.school.value
    if data.casting_time is not None:
        spell.casting_time = data.casting_time
    if data.casting_type is not None:
        spell.casting_type = data.casting_type.value
    if "trigger" in fields_set:
        spell.trigger = data.trigger.strip() if data.trigger else None
    if data.duration is not None:
        spell.duration = data.duration.value
    if data.concentration is not None:
        spell.concentration = data.concentration
    if data.range is not None:
        spell.spell_range = data.range.value
    if data.component_verbal is not None:
        spell.component_verbal = data.component_verbal
    if data.component_somatic is not None:
        spell.component_somatic = data.component_somatic
    if data.component_material is not None:
        spell.component_material = data.component_material
    if "materials" in fields_set:
        spell.materials = data.materials.strip() if data.materials else None
    if "description" in fields_set:
        spell.description = data.description
    if "higher_levels" in fields_set:
        spell.higher_levels = data.higher_levels

    _validate_trigger_and_materials_for_update(spell, data)

    if data.class_ids is not None:
        for class_id in data.class_ids:
            await get_caster_class_owned(session, class_id, user.id)
        await _replace_spell_classes(session, spell.id, data.class_ids)
    if data.spell_tag_ids is not None:
        await assert_spell_tags_owned(session, data.spell_tag_ids, user.id)
        await _replace_spell_tags(session, spell.id, data.spell_tag_ids)

    await session.flush()
    class_ids = await _fetch_class_ids(session, spell.id)
    spell_tag_ids = await _fetch_spell_tag_ids(session, spell.id)
    return spell_to_response(
        spell,
        class_ids=class_ids,
        spell_tag_ids=spell_tag_ids,
    )


async def delete_spell(session: AsyncSession, user: User, spell_id: int) -> None:
    result = await session.execute(
        select(Spell).where(
            Spell.id == spell_id,
            Spell.user_id == user.id,
            Spell.deleted_at.is_(None),
        )
    )
    spell = result.scalar_one_or_none()
    if spell is None:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Spell not found",
        )
    await _clear_spell_relations(session, spell.id)
    await soft_delete(spell)
