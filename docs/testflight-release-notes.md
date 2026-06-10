# OHeas — Beta 1 TestFlight Release Notes

**Version:** 1.0 (Beta 1)  
**Build:** TBD  
**Release Date:** June 2026  
**Required:** iPhone running iOS 17+ paired with Apple Watch (Series 3+ recommended)

---

## What Is OHeas

OHeas is a personal health coach that lives on your iPhone and learns from your Apple Watch data. Instead of showing you dashboards and charts, it gives you **one small, actionable recommendation every day** — and checks back tomorrow to see if it helped.

Think of it as a friend who notices "hey, your sleep's been rough this week — maybe take it easy today" — except it learns from weeks of your data, not just yesterday.

## What This Beta Tests

We built a lot under the hood. This beta focuses on the core loop:

1. **Read** your Apple Watch data (sleep, recovery, activity)
2. **Detect** when your body is under-recovered or off-baseline
3. **Recommend** one small thing to do today
4. **Learn** from whether you did it and how you felt
5. **Plan** a sustainable week based on your goals

We want to know: **does this loop actually work for you?**

## What's Included

- **Today** — Your body-state summary and daily recommendation
- **Plan** — A 7-day adaptive plan that adjusts when your recovery state changes
- **Metrics** — Today's numbers vs your 14-day personal baseline
- **Experiments** — N-of-1 lifestyle tests (e.g. "try a 10-min walk after lunch for 5 days")
- **Goals** — Set what you're working toward (energy, consistency, sleep, cardio, recovery)
- **Review** — Verification of yesterday's recommendation

## What's NOT in This Beta (Yet)

- Push notifications (coming later)
- Cloud sync between devices (local-only for now)
- Apple Watch companion app (iPhone only)
- Historical trend charts (we focus on daily actions, not dashboards)

## Known Limitations

- **Recovery signals need ~7 days of sleep data** to build a reliable baseline. The first week's recommendations will be conservative.
- **HRV readings vary by person.** Apple Watch takes fewer HRV samples than dedicated recovery wearables. If your watch only records one reading per day, recovery estimates may be noisier.
- **Sleep tracking must be enabled** in Apple Watch settings. Without it, the agent can't assess recovery.
- **AI advice requires an API key** (OpenAI or DeepSeek). Without one, the app uses a built-in rules engine that's simpler but covers the basics.
- **The app is iPhone + Apple Watch only.** iPad and Mac are not supported.

## Privacy

- **Raw HealthKit samples never leave your device.** Period.
- AI prompts contain only aggregate summaries (averages, counts, status flags) — not your sleep-stage stream or individual heart rate readings.
- Cloud sync is **off by default** and requires explicit opt-in.
- You can see exactly what would be sent to the AI in Settings → Privacy Controls → LLM Payload Preview.
- You can export or delete all your data anytime from Settings.

## How to Give Feedback

Three ways, in order of preference:

1. **In-app:** Settings → Beta Tools → Beta Feedback (quick 4-question form)
2. **Direct message:** Reply in TestFlight or message the developer directly
3. **Interview:** If you're up for a 10-minute call, we'd love to hear how you actually use it

The most valuable feedback is: **what did you ignore and why?**

## What We're Watching

Every day, we look at:

- How many people opened the app
- How many followed the day's recommendation
- Whether the safety checks triggered (too many = we're being too aggressive)
- Whether the AI had to fall back to the rules engine (too many = connection issues)

These are non-sensitive product metrics only. You can opt out in Settings → Privacy and Consent.

---

**OHeas does not diagnose disease, prescribe medication, or replace medical advice.** If you experience chest pain, fainting, or persistent abnormal heart rate readings, seek medical help.
