"""spell_tags schema

Revision ID: 004
Revises: 003
Create Date: 2026-07-11

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "004"
down_revision: Union[str, None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "spell_tags",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
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
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_spell_tags_user_id"), "spell_tags", ["user_id"], unique=False
    )
    op.create_index(
        op.f("ix_spell_tags_deleted_at"), "spell_tags", ["deleted_at"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_spell_tags_deleted_at"), table_name="spell_tags")
    op.drop_index(op.f("ix_spell_tags_user_id"), table_name="spell_tags")
    op.drop_table("spell_tags")
