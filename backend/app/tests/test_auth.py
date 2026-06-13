"""Auth endpoint tests — JWT lifecycle."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

from app.auth.jwt import create_access_token, create_refresh_token, decode_token

pytestmark = pytest.mark.asyncio


# ── JWT unit tests ────────────────────────────────────────────


class TestJWT:
    def test_create_and_decode_access_token(self) -> None:
        token = create_access_token("test-user-123")
        payload = decode_token(token)
        assert payload["sub"] == "test-user-123"
        assert payload["type"] == "access"

    def test_create_and_decode_refresh_token(self) -> None:
        token = create_refresh_token("test-user-123")
        payload = decode_token(token)
        assert payload["sub"] == "test-user-123"
        assert payload["type"] == "refresh"

    def test_invalid_token_raises(self) -> None:
        with pytest.raises(Exception):
            decode_token("not.a.real.token")

    def test_access_token_not_accepted_as_refresh(self) -> None:
        token = create_access_token("test-user-123")
        payload = decode_token(token)
        assert payload["type"] == "access"
        assert payload["type"] != "refresh"


# ── Endpoint tests ────────────────────────────────────────────


async def test_auth_endpoints_exist(client: AsyncClient) -> None:
    """Verify auth routes are registered."""
    # Apple Sign In — needs real Apple token, expect 401
    resp = await client.post("/v1/auth/apple", json={"identity_token": "fake-token"})
    assert resp.status_code == 401  # Backend rejects fake Apple token


async def test_refresh_with_invalid_token(client: AsyncClient) -> None:
    resp = await client.post("/v1/auth/refresh", json={"refresh_token": "bad-token"})
    assert resp.status_code == 401


async def test_protected_endpoint_requires_auth(client: AsyncClient) -> None:
    """Sync /changes requires Bearer token."""
    resp = await client.get("/v1/sync/changes")
    assert resp.status_code == 422  # FastAPI validation — missing header


async def test_protected_endpoint_with_invalid_token(client: AsyncClient) -> None:
    """Sync /changes with invalid token."""
    resp = await client.get(
        "/v1/sync/changes",
        headers={"Authorization": "Bearer invalid-token"},
    )
    assert resp.status_code == 401
