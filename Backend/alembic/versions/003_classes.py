"""classes schema

Revision ID: 003
Revises: 002
Create Date: 2026-07-11

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "classes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("file_id", sa.Integer(), nullable=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("caster", sa.Boolean(), server_default=sa.text("false"), nullable=False),
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
    op.create_index(op.f("ix_classes_user_id"), "classes", ["user_id"], unique=False)
    op.create_index(op.f("ix_classes_file_id"), "classes", ["file_id"], unique=False)
    op.create_index(
        op.f("ix_classes_deleted_at"), "classes", ["deleted_at"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_classes_deleted_at"), table_name="classes")
    op.drop_index(op.f("ix_classes_file_id"), table_name="classes")
    op.drop_index(op.f("ix_classes_user_id"), table_name="classes")
    op.drop_table("classes")
