# OHeas

OHeas is a SwiftUI MVP for an Apple Watch / Apple Health driven personal body-state agent.

The app reads HealthKit data when available, falls back to deterministic mock data when HealthKit is unavailable or unauthorized, builds baseline-relative health context, prepares an LLM-ready prompt payload, and can run as a proactive weekly planning agent with local fallback rules.

## What Is Included

- `HealthKitReader`: requests HealthKit authorization and reads sleep, HRV, resting heart rate, steps, active energy, exercise minutes, and workouts.
- `MockHealthDataProvider`: generates 30 days of demo data including normal days, short sleep, HRV drops, missing watch-wear recovery data, and low activity.
- `DailyMetricsAggregator`: converts raw daily samples into `DailyHealthMetrics` without treating missing data as zero.
- `BaselineEngine`: computes 7 / 14 / 30 day style baselines; the app uses 14 days for today comparison.
- `DataCoverageLayer`: reports per-metric status and overall confidence.
- `SignalDetector`: detects baseline-relative signals and downgrades interpretation when confidence is low.
- `AgentContextBuilder`: creates structured JSON context for an LLM agent.
- `CoachPromptBuilder`: creates system prompt plus user context payload.
- `OpenAIClient`: optional OpenAI Responses API client using structured JSON output.
- `RuleBasedRecommendationGenerator`: local fallback recommendation generator.
- `FeedbackStore`: local Codable JSON persistence for daily feedback.
- `VerificationEngine`: reviews whether yesterday's recommendation may have helped.
- `MemoryStore`: local long-term memory for preferences, candidate patterns, interventions, and risk notes.
- `PatternMiner`: simple rule-based pattern candidate mining from metrics, feedback, recommendations, and verification reports.
- `ExperimentPlanner` / `ExperimentStore`: proposes, tracks, and evaluates small N-of-1 lifestyle experiments.
- `GoalStore`: stores active health and movement goals such as energy, consistency, cardio, sleep, and recovery-first.
- `WeeklyPlanPlanner` / `RuleBasedWeeklyPlanGenerator`: creates a small adaptive weekly plan from goals, baseline, confidence, memory, and active experiments.
- `AdaptiveRescheduler`: adjusts today's plan when recovery signals or data confidence change.
- `ReminderScheduler`: builds local notification reminders for plans, feedback, experiments, data coverage, and weekly review.
- `WeeklyReviewEngine`: summarizes plan completion, recovery/activity trends, experiment progress, and next-week adjustments.
- SwiftUI screens:
  - Today
  - Plan
  - Metrics
  - Review
  - Experiments
  - Goals
  - Weekly Review
  - Agent Context
  - Settings

## Open The App

1. Generate the Xcode project:

   ```sh
   xcodegen generate
   ```

2. Open:

   ```sh
   open OHeas.xcodeproj
   ```

3. Select the `OHeas` scheme.

4. Run on an iPhone simulator for the mock demo, or on a real iPhone paired with Apple Watch for HealthKit data.

The simulator commonly cannot provide HealthKit wearable data. The app automatically uses mock data if HealthKit is unavailable, permission is denied, or reads fail.

## HealthKit Permissions

The app includes:

- `NSHealthShareUsageDescription` in `OHeasApp/Info.plist`
- HealthKit entitlement in `OHeasApp/OHeas.entitlements`

For real-device testing:

1. Use a paid Apple Developer team or a signing setup that supports HealthKit.
2. Enable HealthKit capability for the app identifier.
3. Run on a real iPhone.
4. Grant read permissions for sleep, HRV, resting heart rate, steps, active energy, exercise minutes, and workouts.

## Mock Demo

Mock data is deterministic and covers:

- Normal days
- Sleep deficit days
- HRV drop days
- Missing sleep / HRV days from not wearing the watch
- Low activity days
- One high activity day

Today is intentionally shaped as a lower-recovery demo day so the Today and Metrics screens show meaningful signals.

Without an OpenAI API key, the app still runs end-to-end with local rule-based recommendations, feedback capture, and verification.

## OpenAI API Key

The app never hardcodes an API key. It reads configuration in this order:

1. Environment variable `OPENAI_API_KEY`
2. `OPENAI_API_KEY` from `Info.plist` / build setting injection

The model can be configured with `OPENAI_MODEL`; default is `gpt-5.4-mini`.

For local Xcode development, you can add a private `.xcconfig` or scheme environment variable:

```sh
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-5.4-mini
```

If the API key is missing, AI is disabled in Settings, networking fails, or the model output cannot be parsed, OHeas falls back to `RuleBasedRecommendationGenerator`.

The OpenAI path uses the Responses API with structured JSON output (`text.format.type = json_schema`) so the response can decode into `CoachRecommendation`.

## Daily Agent Loop

OHeas now stores locally:

- `CoachRecommendation` history
- `DailyFeedback`
- `VerificationReport`
- `UserMemory`
- `PersonalExperiment` history

The Today screen shows the daily recommendation and lets the user record:

- Whether yesterday's recommendation was completed, partial, or skipped
- Energy 1-10
- Soreness 1-10
- Stress 1-10
- Optional note

The Review screen compares yesterday's recommendation and feedback with today's aggregated metrics. It only says a recommendation "may have helped"; it never claims proof.

## Personal Experiments

OHeas can propose small N-of-1 experiments: short, low-risk lifestyle observations designed for one person, not medical treatment.

Examples:

- Wear Apple Watch for 5 nights to rebuild recovery data coverage.
- Move bedtime 30 minutes earlier for 5 days.
- Use low-intensity activity after a high-load training day.
- Take a 15-minute afternoon walk for 5 days.

The Experiments tab shows:

- Active experiment
- Today's check-in
- Proposed next experiment
- Completed experiment history and cautious result summary

Only one experiment can be active at a time. If there are fewer than 3 check-ins, or data quality is low, evaluation returns `unclear`.

## Goals And Weekly Plans

The Goals tab lets you create active goals:

- Improve energy
- Fat loss
- Build consistency
- Improve cardio
- Improve sleep
- Recovery first
- Custom

The mock demo starts with a default goal: "提升精力和稳定运动习惯".

The Plan tab generates the current week from:

- Active goals
- Recent metrics and 14-day baseline
- Current data confidence
- Detected signals
- User memory and successful intervention candidates
- Active N-of-1 experiment
- Recent feedback and recommendation history

Plans are intentionally small and lifestyle-only. For example, a consistency goal creates frequent 10-30 minute low-intensity plans. A recovery-first goal or low recovery signal lowers intensity. Low data confidence inserts data coverage days such as wearing Apple Watch overnight and recording morning energy.

Each `DailyPlan` can be marked completed or skipped. The UI also supports lightweight manual adjustment of plan type and duration.

## Adaptive Rescheduling

OHeas reviews today's data before presenting the daily plan:

- Low confidence lowers intensity and may switch the plan to data coverage.
- HRV low + resting heart rate high + sleep low downgrades medium/high intensity plans.
- Missing recovery data creates conservative low-risk plans instead of strong recovery claims.
- Active experiments are preserved in the plan unless safety or data quality suggests otherwise.
- Consecutive high-intensity days are avoided by default.

Every automatic adjustment records an `adjustmentReason`, which is injected into `AgentContext` and the coach prompt.

## Notifications

`ReminderScheduler` uses `UserNotifications` on iOS. The Settings tab includes a reminders toggle.

Reminder types:

- Morning daily plan reminder
- Evening feedback reminder
- Experiment check-in reminder
- Data coverage reminder when confidence is low
- Sunday weekly review reminder

Notification behavior can only be fully tested on a simulator or device with notification permissions. If reminders are disabled, reminder models can still be inspected in the Agent tab, but no local notifications are scheduled.

## Weekly Review

The Weekly Review tab shows:

- Plan completion rate
- Adherence summary
- Recovery and activity summary
- Experiment summary
- Useful pattern candidates
- Suggested next-week adjustments

Skipped plans are not treated as failed health advice. If sleep or HRV coverage is missing on multiple days, review confidence is lowered.

## Memory And Pattern Mining

Memory is built from local history:

- Daily feedback
- Verification reports
- Recommendation history
- Aggregated daily metrics

The first Pattern Miner is rule-based, not ML. It can produce candidate observations such as:

- Short sleep may be followed by softer recovery signals.
- Higher activity load may require longer recovery.
- Low sleep / HRV coverage may reduce recovery confidence.
- Some completed interventions may be associated with better next-day indicators.

Patterns are candidates only. They are not medical conclusions and should be phrased with "may", "possibly", or "currently observed".

Memory compaction keeps storage bounded:

- 20 known patterns
- 20 successful interventions
- 20 ineffective interventions
- 10 risk notes
- 3 examples per pattern

Use the Agent tab to inspect:

- Current `UserMemory` JSON
- Pattern miner candidates
- Active/proposed experiment JSON
- Experiment evaluation results
- Active goals JSON
- Current weekly plan JSON
- Today plan JSON
- Reminder schedule JSON
- Weekly review JSON

## Privacy

Only aggregated `AgentContext`, recommendation history, weekly plan summaries, experiment summaries, memory summaries, and feedback summaries are prepared for the LLM. Raw HealthKit samples, sleep segments, and workout detail streams are not sent.

First-version storage is local JSON in the app's Application Support directory.

Memory is also stored locally. The LLM receives only memory summaries and bounded lists of candidate patterns/interventions inside `AgentContext`, not raw HealthKit details.

## Phase 5: Evaluation, Safety, Privacy, Effectiveness, Demo

OHeas now includes a fifth-stage trust layer that turns the agent from a feature-complete prototype into a more evaluable demo product.

New core modules:

- `SafetyGuardrail`: checks recommendations, weekly plans, experiments, weekly reviews, and raw LLM text for unsafe health language.
- `PrivacyManager` / `PrivacyStore`: controls which context sections can enter LLM prompts.
- `AgentEvaluationRunner`: runs built-in behavior cases against the recommendation generator and safety layer.
- `PromptRegressionTester`: snapshots prompt payloads and structured outputs, then detects key behavior regressions.
- `EffectivenessAnalyzer`: summarizes adherence, plan completion, experiment completion, likely-helped rate, data coverage, and confidence.
- `DemoScenarioBuilder`: creates complete 30-day demo trajectories without Apple Watch data.

New app tabs:

- Effectiveness
- Privacy
- Demo
- Evaluation

The Agent Context tab also includes debug views for current privacy settings, sanitized LLM payload preview, safety assessments, evaluation results, and prompt regression results.

## Safety Boundaries

The safety layer flags and sanitizes:

- Medical diagnosis language such as "you have" or "diagnosed with".
- Emergency symptom terms such as chest pain, fainting, syncope, or persistent abnormal heart rate.
- Medication, supplement, or extreme dieting advice.
- Overconfident claims such as "guaranteed", "proves this works", or "一定会改善".
- High-intensity recommendations when recovery signals are low or data confidence is low.
- Unsupported causal claims from observational personal data.
- Missing lifestyle-only disclaimer text.

If output is `caution` or `unsafe`, the original structured output is retained for debug, while user-facing Today and Plan views show the sanitized version with a lightweight note:

```text
已根据安全边界调整表达
```

All effectiveness and review language remains observational: "may help", "possibly helped", "observed trend", or "unclear". The app should not claim medical proof.

## Privacy Controls

The Privacy tab controls:

- Share aggregated metrics with LLM
- Share memory summary with LLM
- Share experiment summary with LLM
- Share plan summary with LLM
- Share feedback with LLM
- Allow raw Health samples
- Use LLM

Defaults are conservative:

- Aggregated summaries: on
- Memory / experiment / plan / feedback summaries: on
- Raw HealthKit samples: off
- LLM use: off

When `useLLM = false`, `CoachRecommendationService` uses the rule-based fallback even if an API key exists. When `allowRawHealthSamples = false`, prompts are built only from aggregate `AgentContext`; raw HealthKit samples are not included.

The Privacy tab includes a live "LLM Payload Preview" so reviewers can inspect exactly what would be sent.

## Evaluation Suite

The built-in evaluation suite includes 8 cases:

1. Sleep low + HRV low + resting heart rate high.
2. Low data confidence.
3. Skipped feedback.
4. High activity followed by recovery drop.
5. Stable recovery + low activity.
6. Active experiment exists.
7. Cardio goal with low recovery.
8. Unsafe raw LLM text fixture.

The Evaluation tab runs and displays:

- Pass/fail
- Score
- Failure reasons
- Safety flags

From the command line:

```sh
swift test
```

The test suite covers the built-in evaluation cases and asserts that the low-data case asks a follow-up / mentions low confidence, while the unsafe raw text fixture triggers safety flags.

## Prompt Regression

`PromptRegressionTester` saves `PromptSnapshot` values with:

- Case ID
- Prompt hash
- Model name
- Output hash
- Recommendation
- Safety flags

If no snapshot exists, running regression creates a baseline. Later runs compare structured outputs and safety flags. It detects regressions such as:

- Tomorrow verification removed
- Evidence removed
- New safety flags appeared
- Important confidence changes

Prompt regression results are visible in the Evaluation tab and Agent Context debug tab.

## Effectiveness Dashboard

The Effectiveness tab shows:

- Recommendation adherence rate
- Weekly plan completion rate
- Experiment completion rate
- Likely-helped rate among verifiable cases
- Unclear rate
- Recovery data coverage rate
- Average confidence
- Most promising interventions
- Weakest areas

`EffectivenessAnalyzer` treats skipped or unclear feedback as not verifiable. Missing sleep / HRV coverage lowers confidence and adds cautious summary language. It does not make medical efficacy claims.

## Demo Scenarios

The Demo tab can generate four complete local scenarios:

- Overworked Professional: sleep shortage, HRV decline, higher resting heart rate, recovery-first coaching.
- Overtraining Runner: high activity followed by recovery drop, plan downgrade, recovery day.
- Missing Data User: missing sleep / HRV coverage and a data coverage experiment.
- Habit Builder: stable recovery, low activity, light activity plan, consistency goal.

Each scenario creates:

- 30 days of `DailyHealthMetrics`
- Feedback history
- Recommendation history
- Verification reports
- User memory
- Active or completed experiments
- Weekly plan
- Effectiveness report

Demo data is generated locally and does not write to Apple Health. Use "Reset Demo Data" to clear the generated local stores.

## Suggested Demo Flow

1. Open Demo and load `Overworked Professional`.
2. Open Today and show low-recovery coaching plus the safety-adjusted language boundary.
3. Open Plan and show intensity downgrade / recovery-friendly planning.
4. Open Privacy and show the exact LLM payload preview.
5. Open Effectiveness and explain adherence, likely-helped rate, and confidence.
6. Open Evaluation and show behavior tests plus prompt regression status.
7. Open Agent Context for raw debug JSON, safety flags, and sanitized payload.

## Phase 6: Beta Productization

OHeas now includes the first Beta productization layer:

- Local / cloud-ready auth service abstraction.
- FastAPI-first backend stub in `backend/`.
- PostgreSQL schema and RLS policy drafts.
- Backend API client abstraction.
- Sync engine with pending queue, LocalOnly mode, paused mode, and last-write-wins conflict handling.
- Onboarding flow for goals, HealthKit, privacy, AI consent, baseline, and first recommendation.
- Consent manager for HealthKit, AI advice, cloud sync, beta analytics, and notifications.
- Beta analytics service and dashboard.
- Account, Sync Status, and expanded Settings pages.
- Error reporter visible in Agent debug.
- Local data export manifest that excludes raw HealthKit samples.
- TestFlight readiness checklist in `docs/testflight-readiness.md`.

## LocalOnly Mode

LocalOnly is the default safe mode.

The app remains usable without:

- Backend URL
- Backend token
- Account login
- Cloud sync consent
- AI consent

In LocalOnly:

- HealthKit or mock aggregate data stays on device.
- Recommendations use local rules unless AI consent and LLM configuration are present.
- Sync records can be queued locally but are not uploaded.
- Beta analytics are recorded locally only.

## Cloud Sync Configuration

Cloud sync is opt-in and requires:

1. Backend configuration:

   ```sh
   OHEAS_BACKEND_URL=https://your-backend.example.com
   OHEAS_BACKEND_TOKEN=<development-or-jwt-token>
   ```

2. User consent for cloud sync.
3. A signed-in or restored user.

The first backend implementation is a FastAPI stub:

- `backend/app/main.py`
- `backend/app/models.py`
- `backend/postgres/schema.sql`
- `backend/postgres/rls.sql`

Run locally:

```sh
cd backend
python -m venv .venv
. .venv/bin/activate
pip install fastapi uvicorn pydantic
uvicorn app.main:app --reload
```

The development auth stub accepts `Authorization: Bearer <uuid>`. Replace it with real JWT verification before production.

## Synced Data Boundary

Cloud sync may upload only aggregate summaries and agent state:

- DailyHealthMetrics summary
- DataQualityReport
- CoachRecommendation
- DailyFeedback
- VerificationReport
- UserMemory summary
- PersonalExperiment
- WeeklyPlan
- WeeklyReview
- UserGoal
- PrivacySettings
- EffectivenessReport
- SafetyAssessment
- BetaAnalyticsEvent

It must not upload:

- Raw HealthKit samples
- Sleep segment streams
- HRV sample arrays
- Resting heart rate sample arrays
- Workout routes

## Onboarding Flow

Fresh installs show onboarding before the main tab view.

Steps:

1. Welcome and lifestyle-only disclaimer.
2. Goal setup.
3. HealthKit permission explanation.
4. Privacy settings.
5. AI consent.
6. Baseline setup.
7. First recommendation.

If HealthKit is denied or unavailable, OHeas enters limited/mock mode instead of blocking the user.

## Consent Rules

Consent is stored locally as versioned `ConsentRecord` values.

Rules:

- No AI consent means no LLM call; local rule fallback is used.
- No cloud sync consent means SyncEngine stays LocalOnly.
- No beta analytics consent means analytics are not uploaded.
- Revoked consent takes effect from the latest consent record.

## Beta Analytics

`BetaAnalyticsService` records local product events such as:

- App opened
- Recommendation generated
- Feedback saved
- Experiment started / check-in
- Weekly plan generated / adjusted
- Safety flag triggered
- LLM fallback used
- Sync failed
- Onboarding completed

Properties are limited to non-sensitive summaries such as `confidence=low` or `fallback=true`. Sensitive keys like raw samples are rejected.

The Settings page links to a local Beta Analytics dashboard.

## Settings And Account

Settings now includes:

- Account
- Sync Status
- Privacy Controls
- Notification toggle
- AI / cloud / beta analytics consent
- Demo Mode
- Export Local Data JSON
- Reset Local Data with confirmation
- App version/build

Exported data contains aggregate and agent state only. It does not include raw HealthKit samples.

## TestFlight Preparation

See:

```sh
docs/testflight-readiness.md
```

Before TestFlight:

- Replace backend auth stub with production JWT verification.
- Confirm HealthKit capability and privacy strings.
- Host a privacy policy covering HealthKit, cloud sync, AI, analytics, and deletion/reset.
- Run the manual QA checklist.
- Review safety flags from beta sessions before expanding testers.

Goals, weekly plans, reminders, weekly reviews, memory, feedback, recommendations, and experiments are stored locally in JSON for this MVP.

## Safety

OHeas is lifestyle and fitness coaching software, not a medical diagnostic system.

The prompt and fallback rules enforce:

- No disease diagnosis
- Conservative wording when data confidence is low
- Exactly one small actionable recommendation
- At most one follow-up question when missing data blocks useful advice
- Professional medical care should be recommended for dangerous symptoms

## Language

The app UI defaults to Chinese. Open the Settings tab to switch between 中文 and English.

Agent JSON and prompt payloads intentionally remain structured in English so they can be sent directly to OpenAI / Claude later.

## Tests

Run core tests:

```sh
swift test
```

Covered behavior:

- Baseline calculations ignore missing values.
- Data confidence levels.
- Signal detection.
- Missing data is not treated as zero.
- Low confidence downgrades recovery interpretation.
- LLM JSON parsing.
- LLM parsing failure fallback.
- Low-confidence uncertain recommendation.
- Feedback save and read.
- Skipped feedback does not mark advice ineffective.
- Missing data makes verification unclear.
- Completed feedback plus improved indicators is likely helped.
- Memory pattern merge and compaction.
- Pattern mining low-data-coverage candidate.
- Successful intervention candidate mining.
- One-active-experiment enforcement.
- Low-confidence data coverage experiment priority.
- Experiment evaluation for unclear and likely-helped outcomes.
- AgentContext memory and active experiment injection.
- Goal add / update / deactivate and active-goal filtering.
- Weekly plan generation for consistency, recovery-first, active experiment, and low data confidence.
- Adaptive rescheduling for low recovery, low confidence, active experiments, and consecutive high intensity.
- Reminder model creation and disabled scheduling behavior.
- Weekly review completion rate and low-confidence review behavior.
- AgentContext and prompt injection for active goals, weekly plan, today plan, and adjustment reasons.

## LLM API Integration Next

The app already includes `LLMClientProtocol`, `OpenAIClient`, `MockLLMClient`, `CoachRecommendationService`, and rule-based fallback.

Useful next steps:

- Add a private `.xcconfig` for local OpenAI configuration.
- Add a Claude-compatible client using the same `CoachPromptPayload`.
- Add user-controlled sync or export for local JSON history.
- Move local JSON stores to SwiftData if you want richer querying.

The coaching boundary should remain lifestyle-only: no diagnoses, no disease claims, conservative language when confidence is low, and professional medical care for dangerous symptoms.
