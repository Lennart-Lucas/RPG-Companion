from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    refresh_tokens: Mapped[list["RefreshToken"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    authors: Mapped[list["Author"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    files: Mapped[list["ResourceFile"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    classes: Mapped[list["CharacterClass"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    spell_tags: Mapped[list["SpellTag"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    damage_types: Mapped[list["DamageType"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="noload"
    )
    spells: Mapped[list["Spell"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
