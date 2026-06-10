"""Sync endpoints — real persistence via Repository."""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.auth.dependencies import get_current_user_id
from app.db.repository import SyncRepository
from app.models import RemoteChangesResponse, SyncUploadRequest, SyncUploadResponse

router = APIRouter(prefix="/v1/sync", tags=["sync"])

# Repository singleton — replace with DI in production.
_repo: SyncRepository | None = None


def _get_repo() -> SyncRepository:
    global _repo
    if _repo is None:
        _repo = SyncRepository()
    return _repo


# ── Upload ────────────────────────────────────────────────────


@router.post("/upload", response_model=SyncUploadResponse)
async def upload_sync_records(
    request: SyncUploadRequest,
    user_id: UUID = Depends(get_current_user_id),
    repo: SyncRepository = Depends(_get_repo),
) -> SyncUploadResponse:
    accepted = 0
    rejected = 0

    for record in request.records:
        # Ownership guard — users can only upload their own data.
        if record.user_id != user_id:
            rejected += 1
            continue

        # Raw HealthKit sample guard — same check as iOS side.
        raw_keys = {"rawHealthSamples", "rawhealthsamples", "sleepSegments", "sleepsegments",
                    "hrvSamples", "hrvsamples", "restingHeartRateSamples", "restingheartratesamples"}
        if raw_keys.intersection(k.lower() for k in record.payload.keys()):
            rejected += 1
            continue

        try:
            await repo.upsert(user_id, record)
            accepted += 1
        except Exception:
            rejected += 1

    return SyncUploadResponse(accepted=accepted, rejected=rejected)


# ── Fetch remote changes ──────────────────────────────────────


@router.get("/changes", response_model=RemoteChangesResponse)
async def fetch_remote_changes(
    since: datetime | None = None,
    user_id: UUID = Depends(get_current_user_id),
    repo: SyncRepository = Depends(_get_repo),
) -> RemoteChangesResponse:
    records = await repo.fetch_changes(user_id, since)
    return RemoteChangesResponse(
        records=records,
        server_time=datetime.now(timezone.utc),
    )


# ── Delete ────────────────────────────────────────────────────


@router.delete("/{entity_type}/{entity_id}")
async def mark_deleted(
    entity_type: str,
    entity_id: str,
    user_id: UUID = Depends(get_current_user_id),
    repo: SyncRepository = Depends(_get_repo),
) -> dict[str, str]:
    await repo.mark_deleted(user_id, entity_type, entity_id)
    return {"status": "deleted", "entity_type": entity_type, "entity_id": entity_id}
