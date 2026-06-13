"""
SQLAlchemy ORM models — 17 tables matching postgres/schema.sql.

App-layer ownership enforcement replaces DB-level RLS:
every query must filter by user_id. The Repository layer enforces this.
"""

from __future__ import annotations

import uuid as _uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, Index, JSON, String, Text, func
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

try:
    from pgvector.sqlalchemy import Vector  # type: ignore[import-untyped]
    HAS_PGVECTOR = True
except ImportError:
    HAS_PGVECTOR = False


class Base(DeclarativeBase):
    pass


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


# ── Auth ──────────────────────────────────────────────────────


class AuthUser(Base):
    __tablename__ = "auth_users"

    id: Mapped[_uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=_uuid.uuid4
    )
    apple_user_id: Mapped[str | None] = mapped_column(
        String(256), unique=True, index=True, nullable=True
    )
    device_id: Mapped[str | None] = mapped_column(
        String(256), unique=True, index=True, nullable=True
    )
    email: Mapped[str | None] = mapped_column(String(320), nullable=True)
    nickname: Mapped[str | None] = mapped_column(
        String(64), unique=True, index=True, nullable=True
    )
    password_hash: Mapped[str | None] = mapped_column(String(256), nullable=True)
    full_name: Mapped[str | None] = mapped_column(String(256), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )
    last_login_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )


# ── Sync records (unified envelope table) ─────────────────────


class SyncRecordModel(Base):
    __tablename__ = "sync_records"

    id: Mapped[_uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=_uuid.uuid4
    )
    user_id: Mapped[_uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("auth_users.id", ondelete="cascade"),
        index=True, nullable=False,
    )
    entity_type: Mapped[str] = mapped_column(String(64), nullable=False)
    entity_id: Mapped[str] = mapped_column(String(128), nullable=False)
    operation: Mapped[str] = mapped_column(String(16), nullable=False, default="upsert")
    payload: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False, onupdate=_utcnow
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    __table_args__ = (
        Index("idx_sync_user_entity", "user_id", "entity_type", "entity_id"),
        Index("idx_sync_user_updated", "user_id", "updated_at"),
    )


# ── Per-entity tables (14 business-domain tables) ─────────────


class _EntityMixin:
    """Shared columns for all entity tables."""

    id: Mapped[_uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=_uuid.uuid4
    )
    user_id: Mapped[_uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("auth_users.id", ondelete="cascade"),
        index=True, nullable=False,
    )
    payload: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False, onupdate=_utcnow
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )


class UserGoal(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "user_goals"


class DailyHealthMetrics(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "daily_health_metrics"
    metric_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    __table_args__ = (
        Index("idx_dhm_user_date", "user_id", "metric_date"),
    )


class DataQualityReport(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "data_quality_reports"
    report_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class CoachRecommendation(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "coach_recommendations"
    recommendation_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class DailyFeedback(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "daily_feedback"
    feedback_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class VerificationReport(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "verification_reports"
    report_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class UserMemory(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "user_memory"


class PersonalExperiment(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "personal_experiments"


class WeeklyPlan(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "weekly_plans"
    week_start_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class WeeklyReview(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "weekly_reviews"
    week_start_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class PrivacySettings(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "privacy_settings"


class EffectivenessReport(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "effectiveness_reports"
    period_start: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    period_end: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class SafetyAssessment(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "safety_assessments"
    entity_type: Mapped[str] = mapped_column(Text, nullable=False, default="")
    entity_id: Mapped[str] = mapped_column(Text, nullable=False, default="")
    __table_args__ = (
        Index("idx_safety_user_entity", "user_id", "entity_type", "entity_id"),
    )


class BetaAnalyticsEvent(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "beta_analytics_events"
    event_type: Mapped[str] = mapped_column(Text, nullable=False, default="")
    __table_args__ = (
        Index("idx_beta_user_event", "user_id", "event_type", "created_at"),
    )


class SyncState(Base, _EntityMixin):  # type: ignore[misc]
    __tablename__ = "sync_state"
    # Override payload to default to 'localOnly' mode
    payload: Mapped[dict] = mapped_column(JSON, nullable=False, default=lambda: {"mode": "localOnly"})


# ── RAG / pgvector ──────────────────────────────────────────────


class MemoryEmbedding(Base):  # type: ignore[misc]
    __tablename__ = "memory_embeddings"

    id: Mapped[_uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=_uuid.uuid4
    )
    user_id: Mapped[_uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("auth_users.id", ondelete="cascade"),
        index=True, nullable=False,
    )
    source_type: Mapped[str] = mapped_column(
        String(32), nullable=False, index=True,
        comment="pattern / intervention / feedback / experiment / recommendation / review",
    )
    source_id: Mapped[str] = mapped_column(String(128), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    embedding: Mapped[list[float] | None] = mapped_column(
        # pgvector: VECTOR(1536) for text-embedding-3-small
        Vector(1536) if HAS_PGVECTOR else ARRAY(Float),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_utcnow, nullable=False
    )

    __table_args__ = (
        Index("idx_emb_user_source", "user_id", "source_type"),
    )
