"""
Apple ID identity token verification.

Verifies the JWT that Apple issues to the client during Sign in with Apple,
using Apple's public JWKS endpoint.
"""

from __future__ import annotations

from datetime import datetime, timezone

import httpx
from fastapi import HTTPException
from jose import jwt as jose_jwt

from app.config import settings

APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"


async def verify_apple_identity_token(identity_token: str) -> str:
    """
    Verify a Sign in with Apple identity token.

    Returns the Apple `sub` (user identifier) on success.
    Raises HTTPException(401) on any validation failure.
    """
    # 1. Fetch Apple's JWKS.
    async with httpx.AsyncClient() as client:
        resp = await client.get(APPLE_JWKS_URL)
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail="Failed to fetch Apple JWKS")
        jwks = resp.json()

    # 2. Decode without verification first to get the kid.
    try:
        unverified_header = jose_jwt.get_unverified_header(identity_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid Apple identity token header")

    # 3. Find the matching key.
    kid = unverified_header.get("kid")
    if not kid:
        raise HTTPException(status_code=401, detail="Missing kid in Apple identity token")

    key_dict = None
    for key in jwks.get("keys", []):
        if key.get("kid") == kid:
            key_dict = key
            break

    if key_dict is None:
        raise HTTPException(status_code=401, detail="Apple signing key not found")

    # 4. Verify the token.
    try:
        payload = jose_jwt.decode(
            identity_token,
            key_dict,
            algorithms=["RS256"],
            audience=settings.apple_client_id,
            issuer=APPLE_ISSUER,
        )
    except jose_jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Apple identity token has expired")
    except jose_jwt.JWTClaimsError as e:
        raise HTTPException(status_code=401, detail=f"Apple identity token claims invalid: {e}")
    except Exception:
        raise HTTPException(status_code=401, detail="Apple identity token verification failed")

    apple_sub = payload.get("sub")
    if not apple_sub:
        raise HTTPException(status_code=401, detail="Missing sub in Apple identity token")

    return apple_sub
