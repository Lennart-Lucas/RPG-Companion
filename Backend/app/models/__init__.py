"""Import all model modules here so Alembic autogenerate discovers them."""

from app.models.author import Author
from app.models.base import Base
from app.models.character_class import CharacterClass
from app.models.damage_type import DamageType
from app.models.file import ResourceFile
from app.models.refresh_token import RefreshToken
from app.models.spell import Spell
from app.models.spell_tag import SpellTag
from app.models.user import User

__all__ = [
    "Author",
    "Base",
    "CharacterClass",
    "DamageType",
    "RefreshToken",
    "ResourceFile",
    "SpellTag",
    "Spell",
    "User",
]
