# OHeas — App Store Connect Submission Checklist

> 在 App Store Connect 创建 App 时逐项填写。
> 每一行都是在 ASC 表单中对应的字段。留空 = 还没定。

---

## App Information

| Field | Value | Notes |
|-------|-------|-------|
| **App Name** | OHeas | 30 chars max |
| **Subtitle** | Personal Health Coach for Apple Watch | 30 chars max. Focus on what it does, not what it is |
| **Primary Language** | Chinese (Simplified) or English | Depending on initial target market |
| **Bundle ID** | `com.oheas.mvp` | Must match Xcode project |
| **SKU** | `oheas-beta-1` | Internal ID, not user-visible |
| **Category (Primary)** | Health & Fitness | |
| **Category (Secondary)** | Lifestyle | |
| **License Agreement** | Standard Apple EULA | |

---

## Age Rating

| Question | Answer |
|----------|--------|
| Unrestricted Web Access | No |
| Medical / Treatment Information | Yes — lifestyle coaching only, NOT medical diagnosis |
| Health / Fitness Data | Yes — HealthKit read access for Apple Watch metrics |
| User Generated Content | No |
| In-App Purchases | No |
| Gambling | No |

Expected rating: **12+** (health data, no medical claims).

---

## Privacy Nutrition Label

Data types collected / linked to user identity:

| Data Type | Purpose | Linked to Identity? |
|-----------|---------|---------------------|
| Health & Fitness (aggregate only) | App Functionality | Yes |
| User ID (local UUID) | App Functionality | Yes |
| Crash Data | Analytics | No |
| Product Interaction (beta analytics) | Analytics | No (opt-in) |

**Not collected:** precise location, contact info, financial info, browsing history, search history, identifiers (beyond local UUID), purchases, sensitive info, diagnostics.

### Privacy Policy URL

Required. Draft a simple page (GitHub Pages, Notion, or similar) covering:

- What data OHeas reads from HealthKit (aggregate only)
- That raw HealthKit samples never leave the device
- That AI use is opt-in
- That cloud sync is opt-in and off by default
- That beta analytics are opt-in and contain only non-sensitive product events
- Contact information

---

## App Store Connect — App Review Section

### TestFlight — Test Information

| Field | Value |
|-------|-------|
| **What to Test** | Core daily loop: receive recommendation → give feedback → see next day's verification. Also: experiment proposal, weekly plan, Demo Mode scenarios. |
| **Account Required?** | No — local-only mode works without account |
| **Special Hardware?** | Apple Watch recommended (Mock / Demo Mode works without) |
| **Sign-in Info** | N/A (no account required) |
| **Contact Info** | Developer email |

### Beta App Review — Reviewer Notes

See `docs/beta-reviewer-notes.md` for full text to paste into ASC.

---

## Export Compliance

| Question | Answer |
|----------|--------|
| Uses encryption? | Yes — standard HTTPS for LLM API calls and cloud sync |
| Exempt? | Yes — qualifies for exemption under category (a): "standard encryption within operating system or application framework" |

No CCATS required. Just check the exemption box in ASC.

---

## Build Upload

After Archive in Xcode → Distribute App:

| Step | Action |
|------|--------|
| 1 | Xcode → Product → Archive |
| 2 | Window → Organizer → Select archive → Distribute App |
| 3 | App Store Connect → Upload |
| 4 | Wait for processing (usually 10-30 minutes) |
| 5 | ASC → TestFlight → Select build → Add testers |

If build is rejected by App Store Connect processing:
- Check email for reason
- Common: missing encryption compliance, missing privacy strings

---

## Pre-submission Verification

Run before uploading:

```sh
./scripts/preflight_release_check.sh
```

All items must pass (green) or have acknowledged warnings (yellow). Red items block release.

---

## Notes

- **App version 1.0, build 1** is appropriate for first TestFlight beta
- Bundle ID `com.oheas.mvp` uses `.mvp` suffix — this is fine for beta. Consider `com.oheas.app` or `com.oheas.ios` for production
- The `DEVELOPMENT_TEAM` field in `project.yml` **must be populated** before archiving. Either edit `project.yml` or set in Xcode → Signing & Capabilities
- If using automatic signing, the Team ID must match the Apple Developer account that owns the App ID in App Store Connect
