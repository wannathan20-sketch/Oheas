create extension if not exists "uuid-ossp";

create table if not exists profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null unique,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists user_goals (
  id uuid primary key,
  user_id uuid not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists daily_health_metrics (
  id uuid primary key,
  user_id uuid not null,
  metric_date date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists data_quality_reports (
  id uuid primary key,
  user_id uuid not null,
  report_date date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists coach_recommendations (
  id uuid primary key,
  user_id uuid not null,
  recommendation_date date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists daily_feedback (
  id uuid primary key,
  user_id uuid not null,
  feedback_date date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists verification_reports (
  id uuid primary key,
  user_id uuid not null,
  report_date date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists user_memory (
  id uuid primary key,
  user_id uuid not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists personal_experiments (
  id uuid primary key,
  user_id uuid not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists weekly_plans (
  id uuid primary key,
  user_id uuid not null,
  week_start_date date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists weekly_reviews (
  id uuid primary key,
  user_id uuid not null,
  week_start_date date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists privacy_settings (
  id uuid primary key,
  user_id uuid not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists effectiveness_reports (
  id uuid primary key,
  user_id uuid not null,
  period_start date,
  period_end date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists safety_assessments (
  id uuid primary key,
  user_id uuid not null,
  entity_type text not null,
  entity_id text not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists beta_analytics_events (
  id uuid primary key,
  user_id uuid not null,
  event_type text not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists sync_state (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null unique,
  last_synced_at timestamptz,
  mode text not null default 'localOnly',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists idx_daily_health_metrics_user_date on daily_health_metrics(user_id, metric_date);
create index if not exists idx_beta_analytics_user_event on beta_analytics_events(user_id, event_type, created_at);
create index if not exists idx_safety_assessments_user_entity on safety_assessments(user_id, entity_type, entity_id);
