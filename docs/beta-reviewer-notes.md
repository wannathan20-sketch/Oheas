# OHeas — Beta Reviewer Notes

> Paste into App Store Connect → App Review → Beta App Review → Reviewer Notes.

---

## What OHeas Does

OHeas is a personal lifestyle coaching app that reads aggregate health data from Apple Health (via Apple Watch) and provides one small, actionable recommendation per day — then verifies the next day whether that recommendation helped.

It is **not a medical device**. OHeas does not diagnose disease, prescribe medication, recommend supplements, or replace qualified medical care.

## Why HealthKit Access Is Required

OHeas requests **read-only** HealthKit access to:

- Sleep (category: sleep analysis)
- Heart Rate Variability (HRV — SDNN)
- Resting Heart Rate
- Steps
- Active Energy Burned
- Exercise Minutes
- Workouts

These seven metrics are aggregated into daily summaries. Raw HealthKit samples (individual sleep stage streams, HRV sample arrays, etc.) are **never uploaded** — they stay on-device and are never included in AI prompts, cloud sync payloads, or data exports.

## No Medical Diagnosis

Every recommendation includes a disclaimer. The app's safety guardrail blocks:
- Medical diagnostic language
- Medication or supplement suggestions
- Extreme diet or exercise advice
- Causal claims ("this proves that...")

If the AI model (LLM) produces potentially unsafe output, it is sanitized before the user sees it.

## AI Use Is Default-Off

LLM (OpenAI or DeepSeek API) is **opt-in**. The default behavior uses a local deterministic rules engine. The user must explicitly enable "Use LLM" in Settings → Privacy Controls. There is no hardcoded API key in the app.

## Demo Mode

For testing without Apple Watch data:

1. Open the app → complete onboarding → go to Settings → Beta Tools → Demo Mode
2. Select any of the 4 demo scenarios (30-day user trajectories)
3. Tap "Load Demo Scenario"
4. Visit Today tab → see recommendation generated from mock data
5. Visit Agent Context tab → see the full JSON context and LLM prompt

Demo Mode writes data only to the app's local store. It does not modify Apple Health.

## Core Test Path (for review)

1. **Fresh install → Onboarding** (7 steps, can skip HealthKit)
2. **Today** → body budget card + local rule recommendation
3. **Feedback** → submit adherence + energy/soreness/stress scores
4. **Plan** → auto-generated 7-day weekly plan
5. **Metrics** → today vs 14-day baseline comparison
6. **Settings → Demo Mode** → load "Overworked Professional" scenario
7. **Settings → Beta Readiness** (in Agent Context debug tab) → verify data pipeline
8. **Settings → Export** → verify no raw HealthKit samples in JSON

## Known Limitations in This Beta

- No real user data yet (this is the first TestFlight build)
- Backend cloud sync is local-only by default (no server configured)
- AI advice requires user-provided API key
- No Apple Watch companion app
- No push notifications
- iPad layout is functional but not optimized

## Contact

[Developer email — fill in before submitting]
