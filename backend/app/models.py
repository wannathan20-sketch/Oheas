from datetime import datetime
from enum import Enum
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class EntityType(str, Enum):
    user_goal = "user_goal"
    daily_health_metrics = "daily_health_metrics"
    data_quality_report = "data_quality_report"
    coach_recommendation = "coach_recommendation"
    daily_feedback = "daily_feedback"
    verification_report = "verification_report"
    user_memory = "user_memory"
    personal_experiment = "personal_experiment"
    weekly_plan = "weekly_plan"
    weekly_review = "weekly_review"
    privacy_settings = "privacy_settings"
    effectiveness_report = "effectiveness_report"
    safety_assessment = "safety_assessment"
    beta_analytics_event = "beta_analytics_event"


class SyncOperation(str, Enum):
    upsert = "upsert"
    delete = "delete"


class SyncEnvelope(BaseModel):
    id: UUID
    user_id: UUID
    entity_type: EntityType
    entity_id: str
    operation: SyncOperation = SyncOperation.upsert
    payload: dict[str, Any] = Field(default_factory=dict)
    updated_at: datetime
    deleted_at: datetime | None = None


class SyncUploadRequest(BaseModel):
    records: list[SyncEnvelope]


class SyncUploadResponse(BaseModel):
    accepted: int
    rejected: int = 0


class RemoteChangesResponse(BaseModel):
    records: list[SyncEnvelope]
    server_time: datetime
