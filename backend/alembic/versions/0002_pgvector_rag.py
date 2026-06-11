"""pgvector + memory_embeddings for RAG

Revision: 0002
Revises: 0001
Create Date: 2026-06-11

Enables pgvector extension and creates memory_embeddings table
for semantic search over health memory sources.
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Enable pgvector extension
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    op.create_table(
        "memory_embeddings",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("auth_users.id", ondelete="cascade"),
                  index=True, nullable=False),
        sa.Column("source_type", sa.String(32), index=True, nullable=False,
                  comment="pattern / intervention / feedback / experiment / recommendation / review"),
        sa.Column("source_id", sa.String(128), nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column(
            "embedding",
            postgresql.ARRAY(sa.Float),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
    )
    # Cast the ARRAY column to VECTOR for pgvector index support
    op.execute(
        "ALTER TABLE memory_embeddings ALTER COLUMN embedding TYPE vector(1536) USING embedding::vector(1536)"
    )
    op.create_index("idx_emb_user_source", "memory_embeddings", ["user_id", "source_type"])

    # IVFFlat index for cosine similarity search (build after data exists)
    op.execute(
        "CREATE INDEX IF NOT EXISTS idx_emb_cosine "
        "ON memory_embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100)"
    )


def downgrade() -> None:
    op.drop_index("idx_emb_cosine", table_name="memory_embeddings")
    op.drop_index("idx_emb_user_source", table_name="memory_embeddings")
    op.drop_table("memory_embeddings")
