alter table profiles enable row level security;
alter table user_goals enable row level security;
alter table daily_health_metrics enable row level security;
alter table data_quality_reports enable row level security;
alter table coach_recommendations enable row level security;
alter table daily_feedback enable row level security;
alter table verification_reports enable row level security;
alter table user_memory enable row level security;
alter table personal_experiments enable row level security;
alter table weekly_plans enable row level security;
alter table weekly_reviews enable row level security;
alter table privacy_settings enable row level security;
alter table effectiveness_reports enable row level security;
alter table safety_assessments enable row level security;
alter table beta_analytics_events enable row level security;
alter table sync_state enable row level security;

-- Replace auth.uid() with the equivalent JWT subject helper if not using Supabase.

create policy profiles_owner_all on profiles
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy user_goals_owner_all on user_goals
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy daily_health_metrics_owner_all on daily_health_metrics
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy data_quality_reports_owner_all on data_quality_reports
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy coach_recommendations_owner_all on coach_recommendations
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy daily_feedback_owner_all on daily_feedback
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy verification_reports_owner_all on verification_reports
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy user_memory_owner_all on user_memory
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy personal_experiments_owner_all on personal_experiments
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy weekly_plans_owner_all on weekly_plans
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy weekly_reviews_owner_all on weekly_reviews
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy privacy_settings_owner_all on privacy_settings
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy effectiveness_reports_owner_all on effectiveness_reports
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy safety_assessments_owner_all on safety_assessments
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy sync_state_owner_all on sync_state
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy beta_analytics_events_owner_insert on beta_analytics_events
  for insert
  with check (user_id = auth.uid());

create policy beta_analytics_events_owner_select_none on beta_analytics_events
  for select
  using (false);
