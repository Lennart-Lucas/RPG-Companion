from datetime import datetime
from enum import Enum
from typing import Self

from pydantic import BaseModel, Field, field_validator, model_validator

from app.schemas.resource_common import ResourceListResponse, validate_name


class SpellLevel(str, Enum):
    cantrip = "cantrip"
    first = "1st"
    second = "2nd"
    third = "3rd"
    fourth = "4th"
    fifth = "5th"
    sixth = "6th"
    seventh = "7th"
    eighth = "8th"
    ninth = "9th"


class SpellSchool(str, Enum):
    abjuration = "abjuration"
    conjuration = "conjuration"
    divination = "divination"
    enchantment = "enchantment"
    evocation = "evocation"
    illusion = "illusion"
    necromancy = "necromancy"
    transmutation = "transmutation"


class CastingType(str, Enum):
    action = "action"
    bonus_action = "bonus_action"
    reaction = "reaction"
    minutes = "minutes"
    hours = "hours"


class SpellDuration(str, Enum):
    instantaneous = "instantaneous"
    one_round = "1_round"
    one_minute = "1_minute"
    ten_minutes = "10_minutes"
    one_hour = "1_hour"
    eight_hours = "8_hours"
    twenty_four_hours = "24_hours"


class SpellRange(str, Enum):
    touch = "touch"
    self_range = "self"
    five_feet = "5_feet"
    ten_feet = "10_feet"
    self_15_feet = "self_15_feet"
    self_30_feet = "self_30_feet"
    thirty_feet = "30_feet"
    forty_feet = "40_feet"
    sixty_feet = "60_feet"
    ninety_feet = "90_feet"
    one_twenty_feet = "120_feet"


def _validate_trigger_and_materials(
    *,
    casting_type: CastingType,
    trigger: str | None,
    component_material: bool,
    materials: str | None,
) -> None:
    if casting_type == CastingType.reaction:
        if trigger is None or not trigger.strip():
            raise ValueError("Trigger is required when casting type is reaction")
    elif trigger is not None and trigger.strip():
        raise ValueError("Trigger is only allowed when casting type is reaction")

    if component_material:
        if materials is None or not materials.strip():
            raise ValueError("Materials are required when material component is selected")
    elif materials is not None and materials.strip():
        raise ValueError("Materials are only allowed when material component is selected")


class SpellCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    file_id: int | None = None
    level: SpellLevel
    school: SpellSchool
    casting_time: int = Field(ge=1)
    casting_type: CastingType
    trigger: str | None = Field(default=None, max_length=255)
    duration: SpellDuration
    concentration: bool = False
    range: SpellRange
    component_verbal: bool = False
    component_somatic: bool = False
    component_material: bool = False
    materials: str | None = None
    description: str | None = None
    higher_levels: str | None = None
    class_ids: list[int] = Field(min_length=1)
    spell_tag_ids: list[int] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str) -> str:
        return validate_name(v)

    @model_validator(mode="after")
    def validate_conditional_fields(self) -> Self:
        _validate_trigger_and_materials(
            casting_type=self.casting_type,
            trigger=self.trigger,
            component_material=self.component_material,
            materials=self.materials,
        )
        return self


class SpellUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    file_id: int | None = None
    level: SpellLevel | None = None
    school: SpellSchool | None = None
    casting_time: int | None = Field(default=None, ge=1)
    casting_type: CastingType | None = None
    trigger: str | None = Field(default=None, max_length=255)
    duration: SpellDuration | None = None
    concentration: bool | None = None
    range: SpellRange | None = None
    component_verbal: bool | None = None
    component_somatic: bool | None = None
    component_material: bool | None = None
    materials: str | None = None
    description: str | None = None
    higher_levels: str | None = None
    class_ids: list[int] | None = None
    spell_tag_ids: list[int] | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str | None) -> str | None:
        if v is None:
            return v
        return validate_name(v)

    @model_validator(mode="after")
    def validate_conditional_fields(self) -> Self:
        if self.class_ids is not None and len(self.class_ids) < 1:
            raise ValueError("At least one class is required")
        return self


class SpellResponse(BaseModel):
    id: int
    name: str
    file_id: int | None
    level: SpellLevel
    school: SpellSchool
    casting_time: int
    casting_type: CastingType
    trigger: str | None
    duration: SpellDuration
    concentration: bool
    range: SpellRange
    component_verbal: bool
    component_somatic: bool
    component_material: bool
    materials: str | None
    description: str | None
    higher_levels: str | None
    class_ids: list[int]
    spell_tag_ids: list[int]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class SpellListResponse(ResourceListResponse):
    items: list[SpellResponse]
