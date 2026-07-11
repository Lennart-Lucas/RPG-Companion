from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Table,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

spell_classes = Table(
    "spell_classes",
    Base.metadata,
    Column(
        "spell_id",
        ForeignKey("spells.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "class_id",
        ForeignKey("classes.id", ondelete="CASCADE"),
        primary_key=True,
    ),
)

spell_spell_tags = Table(
    "spell_spell_tags",
    Base.metadata,
    Column(
        "spell_id",
        ForeignKey("spells.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "spell_tag_id",
        ForeignKey("spell_tags.id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


class Spell(Base):
    __tablename__ = "spells"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    file_id: Mapped[int | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL"), nullable=True, index=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    level: Mapped[str] = mapped_column(String(16), nullable=False)
    school: Mapped[str] = mapped_column(String(32), nullable=False)
    casting_time: Mapped[int] = mapped_column(Integer, nullable=False)
    casting_type: Mapped[str] = mapped_column(String(32), nullable=False)
    trigger: Mapped[str | None] = mapped_column(String(255), nullable=True)
    duration: Mapped[str] = mapped_column(String(32), nullable=False)
    concentration: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    spell_range: Mapped[str] = mapped_column(String(32), nullable=False)
    component_verbal: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    component_somatic: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    component_material: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    materials: Mapped[str | None] = mapped_column(Text, nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    higher_levels: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )

    user: Mapped["User"] = relationship(back_populates="spells")
    source_file: Mapped["ResourceFile | None"] = relationship()
    classes: Mapped[list["CharacterClass"]] = relationship(
        secondary=spell_classes,
    )
    spell_tags: Mapped[list["SpellTag"]] = relationship(
        secondary=spell_spell_tags,
    )
