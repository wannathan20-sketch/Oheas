# OHeas Backend

FastAPI backend for OHeas — JWT auth (Apple Sign In), PostgreSQL persistence, and Sync API.

Safe-by-default: no raw HealthKit samples, app-layer RLS via Repository, iOS LocalOnly mode works without backend.

## Quick Start

### Docker (recommended)

```sh
cd backend
cp .env.example .env
# Edit .env: set JWT_SECRET (openssl rand -hex 32) and APPLE_TEAM_ID
docker compose up -d
# → API at http://localhost:8000, PostgreSQL at localhost:5432
# → Alembic auto-migrates on startup
```

### Local Dev (no Docker)

```sh
cd backend
cp .env.example .env
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Requires PostgreSQL running locally with DB "oheas"
alembic upgrade head          # run migrations
uvicorn app.main:app --reload # start dev server
```

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | none | Health check + DB ping |
| POST | `/v1/auth/apple` | Apple identityToken | Sign in / sign up with Apple |
| POST | `/v1/auth/refresh` | refresh token | Rotate access token |
| DELETE | `/v1/auth/session` | Bearer | Sign out |
| POST | `/v1/sync/upload` | Bearer | Upload sync records |
| GET | `/v1/sync/changes?since=` | Bearer | Fetch remote changes |
| DELETE | `/v1/sync/{type}/{id}` | Bearer | Soft-delete entity |

## Database — 17 Tables

| Table | Purpose |
|-------|---------|
| `auth_users` | Apple Sign In users |
| `sync_records` | Unified sync envelope (last-write-wins) |
| `sync_state` | Per-user sync mode |
| 14 entity tables | user_goals, daily_health_metrics, data_quality_reports, coach_recommendations, daily_feedback, verification_reports, user_memory, personal_experiments, weekly_plans, weekly_reviews, privacy_settings, effectiveness_reports, safety_assessments, beta_analytics_events |

All 14 entity tables share the same schema: `id`, `user_id` (FK → auth_users), `payload` (JSONB), `created_at`, `updated_at`, `deleted_at` (soft delete).

### App-Layer RLS

Repository layer enforces `WHERE user_id = $user_id` on every query — no DB-level RLS required.

## Migrations (Alembic)

```sh
# After model changes
alembic revision --autogenerate -m "description"
alembic upgrade head

# Rollback
alembic downgrade -1

# Generate SQL without running
alembic upgrade head --sql
```

## Testing

```sh
pytest app/tests/ -v     # 15 tests (JWT + Auth + Health + Sync)
```

## Data Boundary

**Allowed** (aggregate summaries only):
DailyHealthMetrics, DataQualityReport, CoachRecommendation, DailyFeedback, VerificationReport, UserMemory, PersonalExperiment, WeeklyPlan, WeeklyReview, UserGoal, PrivacySettings, EffectivenessReport, SafetyAssessment, BetaAnalyticsEvent

**Never uploaded**:
Raw HealthKit samples, sleep segments, HRV arrays, workout routes, API keys

## Production Checklist

- [ ] Run `openssl rand -hex 32` and set JWT_SECRET
- [ ] Set APPLE_TEAM_ID and APPLE_CLIENT_ID
- [ ] Update DATABASE_URL to Supabase / hosted Postgres
- [ ] Set DEBUG=false
- [ ] Put CORS origins instead of `*`
- [ ] Enable HTTPS (reverse proxy — nginx / Caddy)
- [ ] Register Sign in with Apple Service ID in Apple Developer
