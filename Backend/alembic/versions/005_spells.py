"""spells schema

Revision ID: 005
Revises: 004
Create Date: 2026-07-11

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "005"
down_revision: Union[str, None] = "004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "spells",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("file_id", sa.Integer(), nullable=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("level", sa.String(length=16), nullable=False),
        sa.Column("school", sa.String(length=32), nullable=False),
        sa.Column("casting_time", sa.Integer(), nullable=False),
        sa.Column("casting_type", sa.String(length=32), nullable=False),
        sa.Column("trigger", sa.String(length=255), nullable=True),
        sa.Column("duration", sa.String(length=32), nullable=False),
        sa.Column("concentration", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("spell_range", sa.String(length=32), nullable=False),
        sa.Column("component_verbal", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("component_somatic", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("component_material", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("materials", sa.Text(), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("higher_levels", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["file_id"], ["files.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_spells_user_id"), "spells", ["user_id"], unique=False)
    op.create_index(op.f("ix_spells_file_id"), "spells", ["file_id"], unique=False)
    op.create_index(op.f("ix_spells_deleted_at"), "spells", ["deleted_at"], unique=False)

    op.create_table(
        "spell_classes",
        sa.Column("spell_id", sa.Integer(), nullable=False),
        sa.Column("class_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["class_id"], ["classes.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["spell_id"], ["spells.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("spell_id", "class_id"),
    )

    op.create_table(
        "spell_spell_tags",
        sa.Column("spell_id", sa.Integer(), nullable=False),
        sa.Column("spell_tag_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["spell_id"], ["spells.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["spell_tag_id"], ["spell_tags.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("spell_id", "spell_tag_id"),
    )
    op.create_index(
        op.f("ix_spell_spell_tags_spell_tag_id"),
        "spell_spell_tags",
        ["spell_tag_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_spell_spell_tags_spell_tag_id"), table_name="spell_spell_tags")
    op.drop_table("spell_spell_tags")
    op.drop_table("spell_classes")
    op.drop_index(op.f("ix_spells_deleted_at"), table_name="spells")
    op.drop_index(op.f("ix_spells_file_id"), table_name="spells")
    op.drop_index(op.f("ix_spells_user_id"), table_name="spells")
    op.drop_table("spells")
