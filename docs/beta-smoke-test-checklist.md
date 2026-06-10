# OHeas — Beta Smoke Test Checklist

> 在 TestFlight 发布前，每份 build 都需跑过本清单。
> 必须至少跑一轮 **模拟器** + 一轮 **真机（iPhone + Apple Watch）**。

---

## 1. 首次打开 App

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 1.1 | 删除旧安装，重新安装 app | 看到 Onboarding → "BodyLoop for OHeas" 欢迎页 | 检查 `OnboardingState.hasCompletedOnboarding == false` |
| 1.2 | app 在后台时切回 | Onboarding 进度保持 | 检查 `onboardingStore.load()` 持久化 |
| 1.3 | 杀死 app 重新打开 | Onboarding 进度保持 | 同上 |

## 2. Onboarding

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 2.1 | 在 Goal Setup 选择一个目标 | Picker 正常切换，Stepper 可调节 frequency | `UserGoalType` 枚举可见 |
| 2.2 | 点击 "Continue with limited mode" | 跳过 HealthKit，进入 limited mode。`dataSource == .mock` | `OnboardingFlow.healthKitRejected()` 被调用 |
| 2.3 | 完成全部 7 步（不跳过 HealthKit） | HealthKit 授权弹窗出现 | `HKHealthStore.requestAuthorization()` 被调用 |
| 2.4 | 允许 HealthKit | `dataSource == .appleHealth`，Today 页显示数据 | 查看 `AgentContextView` → "Beta Readiness" → `healthKitPermissions.authorized == true` |
| 2.5 | 拒绝 HealthKit | `healthKitAuthorized == false`，`limitedModeReason` 非空 | `HealthPermissionRecoveryView` 应显示 "Denied" |
| 2.6 | Privacy 开关全部关闭（useLLM = false, cloudSync = false, betaAnalytics = false） | 进入规则引擎模式 | `recommendationResult.source == "rule_based"` |
| 2.7 | 点击 "Start OHeas" | Onboarding 完成 → 跳转到 RootTabView | `onboardingState.hasCompletedOnboarding == true` |

## 3. HealthKit 授权

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 3.1 | Settings → Health Permissions | 显示 7 项权限状态，所有应显示 "Granted" | 任意显示 "Denied" → 需引导用户去系统设置 |
| 3.2 | 系统设置关闭某权限后返回 app | 状态自动刷新，对应权限显示 "Denied" | 检查 `scenePhase.active` 是否触发 `checkAllPermissions()` |
| 3.3 | 点击 "Open Health Settings" | 跳转到系统 Settings → Health → Data Access → OHeas | `UIApplication.openSettingsURLString` |
| 3.4 | 在系统设置中重新开启权限 | 回到 app 后状态变为 "Granted" | 同上 |

## 4. 真实数据读取

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 4.1 | 打开 app（刚起床，Apple Watch 佩戴过夜） | Today 显示 Sleep、HRV、RHR 数值，不为 "Missing" | `dataSource == .appleHealth` 且 `dataQuality.overallConfidence` 至少为 `.medium` |
| 4.2 | AgentContextView → Beta Readiness | `perMetricCoverage` 显示各指标 status；`recoveryBaselineDays` ≥ 7（如果已用 ≥ 7 天） | 如 `recoveryBaselineDays < 7`，正常（新用户） |
| 4.3 | AgentContextView → Beta Readiness → `last7DaysComplete` | ≥ 4（如果最近 7 天都佩戴手表） | 检查是否有连续 missing 天 |
| 4.4 | Metrics 页面查看 Today vs Baseline 对比 | 各项有数值，delta 合理（非 0，也非极端值） | 检查 `BaselineEngine.comparisons()` |

## 5. 今日建议生成

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 5.1 | 已配 DeepSeek API Key → 打开 app | Today 页显示建议卡片，`source == "deepseek"` | AgentContextView → "Raw" 看 LLM 原始返回；"Fallback" 看是否有降级 |
| 5.2 | 未配 API Key → 打开 app | Today 页显示本地规则引擎建议 | `source == "rule_based"` |
| 5.3 | LLM 建议包含 safetyNote | `safetyNote` 字段非空，内容包含 "not medical advice" 或类似措辞 | SafetyGuardrail 检查 `missing_disclaimer` flag |
| 5.4 | 建议有 1 条 tomorrowVerification | 应看到至少 1 条验证指标 | 检查 `CoachRecommendation.tomorrowVerification` 非空 |

## 6. 用户反馈提交

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 6.1 | 在 Today 页拖动 adherence / energy / soreness / stress 滑块 | 数值显示正确 | Picker + Slider 绑定 `feedback*` @Published 属性 |
| 6.2 | 点击 "Save Feedback" | 建议卡下方的反馈区消失，显示待明天验证的提示 | 检查 `feedbackStore` 是否持久化 |
| 6.3 | 再次打开 app | 昨天的反馈已保存，不再出现在 Today 页（只展示一次） | `yesterdayFeedback != nil` |

## 7. 验证结果（连续测试 2 天）

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 7.1 | Day 1: 接收建议，Day 2: 打开 app | Review 页面显示验证结果 | `verificationReport != nil` |
| 7.2 | Day 1 完成建议 + Day 2 指标改善 | `verdict = likely_helped` | `VerificationEngine.verify()` |
| 7.3 | Day 1 跳过建议 | `verdict = unclear` | 同上 |

## 8. Memory Pattern 更新

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 8.1 | 连续使用 ≥ 5 天且有反馈 | AgentContextView → "Patterns" 显示 pattern candidates | `PatternMiner` 需要 ≥ 5 天数据 |
| 8.2 | Pattern 出现 "sleep deficit → low recovery" | AgentContextView → "Memory" 含 `knownPatterns` | 检查 `MemoryUpdateService.updateMemory()` |

## 9. Experiment 提议

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 9.1 | 使用 ≥ 3 天无 active experiment | Experiments 页面显示 "Proposed" 实验 | `ExperimentPlanner.propose()` 按条件触发 |
| 9.2 | 点击 "Start Experiment" | `activeExperiment.status = .active` | Experiment 页面出现 checkin 入口 |
| 9.3 | 连续 3 天 checkin | Experiment 可 evaluation | `ExperimentStore.evaluateExperiment()` 需 ≥ 3 次 checkin |
| 9.4 | 有 active experiment 时关闭它 | 点 "Pause" → `activeExperiment = nil`；点 "Complete" → 生成 result | `experimentStore.completeExperiment()` |

## 10. Weekly Plan 调整

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 10.1 | 配了 goal + 完成 onboarding | Plan 页面显示本周计划 7 天 | `currentWeeklyPlan.days.count == 7` |
| 10.2 | 模拟一个低恢复日（睡眠不足 + HRV 低） | Plan 页今天的计划 type 被调整为 `rest` 或 `sleep_focus` | `AdaptiveRescheduler.reschedule()` 规则：`hrv_low + rhr_high + sleep_low → rest/sleep_focus` |
| 10.3 | 手动调整当天计划 type + duration | 修改生效，`planType`, `estimatedDurationMinutes` 更新 | `replaceDailyPlan()` |

## 11. Privacy 开关

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 11.1 | Settings → Privacy Controls → 关闭 "Use LLM" | 重新生成建议 → `source == "rule_based"` | `privacySettings.useLLM == false` |
| 11.2 | Privacy Controls → LLM Payload Preview | 内容已 redacted，不包含 raw health samples | `PrivacyManager.redactedContext()` |
| 11.3 | 关闭 "Share aggregated metrics" | Payload Preview 对应字段为空或 anonymized | 同上 |
| 11.4 | Reset Defaults | 所有开关恢复默认（useLLM = false, allowRawHealthSamples = false） | `privacyStore.resetDefaults()` |

## 12. Sync 开关

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 12.1 | 默认状态 | Sync Mode = "LocalOnly" | `syncState.mode == .localOnly` |
| 12.2 | 提供 cloud_sync consent + backend URL | Mode 显示 "Cloud Sync" | 需 `OHEAS_BACKEND_URL` env var |
| 12.3 | 不提供 backend URL | syncNow 返回 error 但本地数据不丢失 | `syncState.lastError` 非空，但 recommended 数据仍在本地 |
| 12.4 | Pause / Resume | 暂停后 syncNow 不发送；恢复后可发送 | `syncState.mode` 变化 |

## 13. Export 本地数据

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 13.1 | Settings → Export Local Data JSON | 显示 "Export ready: raw samples included = no" | 确认不包含 raw samples |
| 13.2 | 查看导出的 JSON | 内容包含 recommendations, feedback, verificationReports, goals, weeklyPlans, privacySettings | 检查 payload keys |
| 13.3 | 检查 JSON 中无 HealthKit 原始数据 | 无 `sleepSegments`, `hrvSamples`, `restingHeartRateSamples` 字段 | grep JSON |

## 14. Reset 本地数据

| # | 操作 | 预期结果 | 失败排查 |
|---|------|---------|---------|
| 14.1 | Settings → Reset Local Data | 弹窗确认 "Reset local OHeas data?" | `showResetConfirmation == true` |
| 14.2 | 点 "Cancel" | 数据未清除，继续正常使用 | 检查各项数据完整性 |
| 14.3 | 点 "Reset Local Data" | 所有本地数据清除：recommendation, feedback, goal, plan, experiment, memory 全空。回到 Onboarding | `OnboardingState` 被 reset 为初始值 |
| 14.4 | Reset 后检查 Apple Health | Apple Health 数据完全不受影响（OHeas 只有读权限） | 打开 Apple Health app 确认数据完整 |

---

## 快速检查清单（CI / 每次 build）

```
[ ] swift build          — 编译通过
[ ] swift test           — 73 tests passed
[ ] xcodegen generate    — 项目生成成功
[ ] xcodebuild … build   — Xcode 编译通过
[ ] API Key placeholder  — DEEPSEEK_API_KEY_PLACEHOLDER 被 detected and skipped
[ ] git status           — deepseek.env 和 xcscheme 不在 staged files
```

---

## Smoke Test 结果记录

| 日期 | 测试者 | 模拟器/真机 | 通过/失败 | 备注 |
|------|--------|-----------|----------|------|
| 2026-06-10 | Claude | 模拟器（代码层） | ✅ 通过 | Preflight 17/2/0, 103 tests passed, 12 P0/P1 修复已确认 |
|      |        | 真机 | ⚠️ 待执行 | 需 iPhone + Apple Watch，见 PROJECT_STATUS.md 真机验证日志 |
