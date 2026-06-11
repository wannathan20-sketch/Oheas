#!/bin/bash
# OHeas Backend — Startup script
# Runs DB migrations then starts uvicorn.
# Zeabur injects PORT; defaults to 8000 for local Docker.

set -e

echo "[oheas] Starting up..."
echo "[oheas] Running database migrations..."
alembic upgrade head

echo "[oheas] Starting uvicorn on port ${PORT:-8000}..."
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
