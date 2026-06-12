# OHeas TestFlight Readiness

## HealthKit Capability Checklist

- HealthKit capability enabled for the App ID.
- `com.apple.developer.healthkit` entitlement present.
- Real-device test with paired Apple Watch.
- Read-only access requested for aggregate sleep, HRV, resting heart rate, steps, active energy, exercise minutes, and workouts.
- App remains usable in LocalOnly mock / limited mode when HealthKit permission is denied.

## Info.plist Privacy Strings

- `NSHealthShareUsageDescription`: explain read-only aggregate HealthKit use.
- Notification usage text, if local notification permission is requested.
- No copy should imply medical diagnosis or treatment.

## Notification Checklist

- Local notification authorization requested only after user intent.
- Reminders can be disabled.
- Reminder schedule visible in debug UI.

## AI Advice Disclaimer

OHeas provides lifestyle coaching only. It does not diagnose disease, prescribe medication, recommend supplements, or replace qualified medical care. For emergency symptoms such as chest pain, fainting, or persistent abnormal heart rate, users should seek medical help.

## Privacy Policy Draft Points

- Raw HealthKit samples are not uploaded.
- Cloud sync, if enabled, uploads aggregate summaries and agent state only.
- AI use is optional and requires consent.
- Beta analytics are optional and contain only non-sensitive product events.
- Users can revoke consent and reset local data.
- LocalOnly mode works without account or backend configuration.

## Beta Testing Plan

- Recruit 10-25 testers with Apple Watch.
- Ask testers to complete onboarding, use Today recommendations, submit feedback, and review weekly plans.
- Track retention, feedback rate, data coverage, safety flag count, sync failures, and LLM fallback rate.
- Review safety flags weekly before expanding beta size.

## Known Limitations

- Backend JWT + Apple Sign In code is implemented, but production deployment and real-device end-to-end sync are not yet verified.
- Sync conflict strategy is last-write-wins, with local latest privacy settings preferred.
- Effectiveness reports are observational and not medical evidence.
- Simulator HealthKit data is limited; demo scenarios are provided.
- Latest local `xcodebuild build` passes on iPhone 17 simulator (iOS 26.5); `xcodebuild test` compiled and entered Testing started, but the simulator test host launch hung and was manually interrupted. Re-run full simulator tests in a clean simulator or CI before Archive.

## Safety Boundaries

- No medical diagnosis.
- No medication or supplement recommendations.
- No extreme dieting advice.
- No guaranteed outcomes.
- No high-intensity plan when recovery is low or data confidence is low.
- Unsafe LLM output is sanitized before user display.

## Data Sync Model

Synced entities:

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

Never synced:

- Raw HealthKit samples
- Sleep segment streams
- HRV sample arrays
- Resting heart rate sample arrays
- Workout routes

## Demo Mode Instructions

1. Open Settings > Demo Mode, or the Demo tab.
2. Load one of the four built-in scenarios.
3. Visit Today, Plan, Effectiveness, Evaluation, and Agent Context.
4. Use Reset Demo Data before returning to real or mock mode.

## Manual QA Checklist

- Fresh install shows onboarding.
- Onboarding can complete without HealthKit permission.
- No AI consent forces rule-based fallback.
- No cloud sync consent keeps SyncEngine in LocalOnly.
- Privacy tab payload preview excludes raw samples.
- Demo scenarios generate 30 days of metrics.
- Safety guardrail sanitizes unsafe raw text fixture.
- Evaluation suite runs 8 cases.
- Prompt regression creates baseline when snapshots are missing.
- Effectiveness dashboard displays coverage and confidence.
- Settings export excludes raw samples.
- Reset local data requires confirmation.
- App builds for iOS simulator and real device signing configuration is documented.
