"""Sync endpoint tests."""

from __future__ import annotations

import uuid

import pytest
from httpx import AsyncClient

from app.auth.jwt import create_access_token

pytestmark = pytest.mark.asyncio


def _auth_header(user_id: str = "00000000-0000-0000-0000-000000000001") -> dict:
    token = create_access_token(user_id)
    return {"Authorization": f"Bearer {token}"}


# ── Upload tests ──────────────────────────────────────────────


async def test_upload_rejects_raw_health_samples(client: AsyncClient) -> None:
    """Payloads containing raw HealthKit sample keys are rejected."""
    user_id = uuid.uuid4()
    record = {
        "id": str(uuid.uuid4()),
        "user_id": str(user_id),
        "entity_type": "daily_health_metrics",
        "entity_id": "2026-06-10",
        "operation": "upsert",
        "payload": {
            "sleepSegments": [{"asleep": True, "start": "2026-06-10T00:00:00Z"}],
            "steps": 8000,
        },
        "updated_at": "2026-06-10T10:00:00Z",
    }
    resp = await client.post(
        "/v1/sync/upload",
        json={"records": [record]},
        headers=_auth_header(str(user_id)),
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["accepted"] == 0
    assert data["rejected"] == 1


async def test_upload_user_id_mismatch_rejected(client: AsyncClient) -> None:
    """A record claiming a different user_id than the JWT is rejected."""
    # JWT claims user 001, but record claims user 002.
    token = create_access_token("00000000-0000-0000-0000-000000000001")
    record = {
        "id": str(uuid.uuid4()),
        "user_id": "00000000-0000-0000-0000-000000000002",  # different user!
        "entity_type": "coach_recommendation",
        "entity_id": str(uuid.uuid4()),
        "operation": "upsert",
        "payload": {"title": "Test"},
        "updated_at": "2026-06-10T10:00:00Z",
    }
    resp = await client.post(
        "/v1/sync/upload",
        json={"records": [record]},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["rejected"] == 1


async def test_upload_valid_record_accepted(client: AsyncClient) -> None:
    """A clean record matching the JWT user is accepted."""
    user_id = uuid.uuid4()
    token = create_access_token(str(user_id))
    record = {
        "id": str(uuid.uuid4()),
        "user_id": str(user_id),
        "entity_type": "coach_recommendation",
        "entity_id": str(uuid.uuid4()),
        "operation": "upsert",
        "payload": {
            "title": "Rest day",
            "summary": "Take it easy",
            "recommendation": "Walk 10 min",
            "safetyNote": "Not medical advice.",
        },
        "updated_at": "2026-06-10T10:00:00Z",
    }
    resp = await client.post(
        "/v1/sync/upload",
        json={"records": [record]},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["accepted"] == 1
    assert data["rejected"] == 0


# ── Fetch changes test ────────────────────────────────────────


async def test_fetch_changes_requires_auth(client: AsyncClient) -> None:
    resp = await client.get("/v1/sync/changes")
    assert resp.status_code == 422  # missing header


async def test_fetch_changes_with_valid_token(client: AsyncClient) -> None:
    token = create_access_token("00000000-0000-0000-0000-000000000001")
    resp = await client.get(
        "/v1/sync/changes",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "records" in data
    assert "server_time" in data
    assert isinstance(data["records"], list)


# ── Delete test ───────────────────────────────────────────────


async def test_delete_with_valid_token(client: AsyncClient) -> None:
    token = create_access_token("00000000-0000-0000-0000-000000000001")
    resp = await client.delete(
        "/v1/sync/coach_recommendation/some-uuid",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "deleted"
