"""initial schema

Revision: 0001
Revises: None
Create Date: 2026-06-10

Creates all 17 tables for OHeas MVP:
  - auth_users (1)
  - sync_records (unified envelope) (1)
  - 14 business-domain tables
  - sync_state (1)
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── Auth ────────────────────────────────────────────────────────
    op.create_table(
        "auth_users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("apple_user_id", sa.String(256), unique=True, index=True, nullable=False),
        sa.Column("email", sa.String(320), nullable=True),
        sa.Column("full_name", sa.String(256), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
    )

    # ── Sync records (unified envelope) ────────────────────────────
    op.create_table(
        "sync_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("auth_users.id", ondelete="cascade"),
                  index=True, nullable=False),
        sa.Column("entity_type", sa.String(64), nullable=False),
        sa.Column("entity_id", sa.String(128), nullable=False),
        sa.Column("operation", sa.String(16), nullable=False, server_default="upsert"),
        sa.Column("payload", postgresql.JSON, nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("idx_sync_user_entity", "sync_records", ["user_id", "entity_type", "entity_id"])
    op.create_index("idx_sync_user_updated", "sync_records", ["user_id", "updated_at"])

    # ── 14 business-domain tables (shared _EntityMixin columns) ────
    _entity_tables = [
        "user_goals",
        "daily_health_metrics",
        "data_quality_reports",
        "coach_recommendations",
        "daily_feedback",
        "verification_reports",
        "user_memory",
        "personal_experiments",
        "weekly_plans",
        "weekly_reviews",
        "privacy_settings",
        "effectiveness_reports",
        "safety_assessments",
        "beta_analytics_events",
    ]

    for table_name in _entity_tables:
        cols: list[sa.Column] = [
            sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True,
                      server_default=sa.text("gen_random_uuid()")),
            sa.Column("user_id", postgresql.UUID(as_uuid=True),
                      sa.ForeignKey("auth_users.id", ondelete="cascade"),
                      index=True, nullable=False),
            sa.Column("payload", postgresql.JSON, nullable=False, server_default="{}"),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                      server_default=sa.text("now()")),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                      server_default=sa.text("now()")),
            sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        ]
        op.create_table(table_name, *cols)

    # ── Per-table extra columns ────────────────────────────────────
    # daily_health_metrics
    op.add_column("daily_health_metrics",
                  sa.Column("metric_date", sa.DateTime(timezone=True), nullable=True))
    op.create_index("idx_dhm_user_date", "daily_health_metrics", ["user_id", "metric_date"])

    # data_quality_reports
    op.add_column("data_quality_reports",
                  sa.Column("report_date", sa.DateTime(timezone=True), nullable=True))

    # coach_recommendations
    op.add_column("coach_recommendations",
                  sa.Column("recommendation_date", sa.DateTime(timezone=True), nullable=True))

    # daily_feedback
    op.add_column("daily_feedback",
                  sa.Column("feedback_date", sa.DateTime(timezone=True), nullable=True))

    # verification_reports
    op.add_column("verification_reports",
                  sa.Column("report_date", sa.DateTime(timezone=True), nullable=True))

    # weekly_plans
    op.add_column("weekly_plans",
                  sa.Column("week_start_date", sa.DateTime(timezone=True), nullable=True))

    # weekly_reviews
    op.add_column("weekly_reviews",
                  sa.Column("week_start_date", sa.DateTime(timezone=True), nullable=True))

    # effectiveness_reports
    op.add_column("effectiveness_reports",
                  sa.Column("period_start", sa.DateTime(timezone=True), nullable=True))
    op.add_column("effectiveness_reports",
                  sa.Column("period_end", sa.DateTime(timezone=True), nullable=True))

    # safety_assessments
    op.add_column("safety_assessments",
                  sa.Column("entity_type", sa.Text, nullable=False, server_default=""))
    op.add_column("safety_assessments",
                  sa.Column("entity_id", sa.Text, nullable=False, server_default=""))
    op.create_index("idx_safety_user_entity", "safety_assessments",
                    ["user_id", "entity_type", "entity_id"])

    # beta_analytics_events
    op.add_column("beta_analytics_events",
                  sa.Column("event_type", sa.Text, nullable=False, server_default=""))
    op.create_index("idx_beta_user_event", "beta_analytics_events",
                    ["user_id", "event_type", "created_at"])

    # ── sync_state ─────────────────────────────────────────────────
    op.create_table(
        "sync_state",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("auth_users.id", ondelete="cascade"),
                  index=True, nullable=False),
        sa.Column("payload", postgresql.JSON, nullable=False,
                  server_default='{"mode": "localOnly"}'),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_table("sync_state")
    op.drop_index("idx_beta_user_event", table_name="beta_analytics_events")
    op.drop_index("idx_safety_user_entity", table_name="safety_assessments")
    for table_name in reversed([
        "user_goals",
        "daily_health_metrics",
        "data_quality_reports",
        "coach_recommendations",
        "daily_feedback",
        "verification_reports",
        "user_memory",
        "personal_experiments",
        "weekly_plans",
        "weekly_reviews",
        "privacy_settings",
        "effectiveness_reports",
        "safety_assessments",
        "beta_analytics_events",
    ]):
        op.drop_table(table_name)
    op.drop_table("sync_records")
    op.drop_table("auth_users")
