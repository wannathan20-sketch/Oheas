# OHeas — TestFlight Beta Plan

> 版本：Beta 1 | 日期：2026-06-09 | 状态：Pre-TestFlight

---

## 1. Beta 测试目标

### 一句话目标

**验证"每天一条可验证建议"这个核心价值是否被真实用户认可。**

### 分级目标

| 层级 | 目标 | 怎么算成功 |
|------|------|-----------|
| P0 | 用户在模拟器外真实设备上能跑通全部流程 | 3+ 用户在 iPhone + Apple Watch 上完成 onboarding → 收到第一条建议 |
| P0 | Agent 建议不被安全护栏频繁拦截 | 安全 flag 触发率 < 5% |
| P1 | 用户会回来反馈 | 30 天留存 ≥ 40%，反馈提交率 ≥ 30% |
| P1 | 验证引擎能区分有效/无效建议 | verification `likely_helped` vs `unclear` 比值 ≥ 1.0 |
| P2 | 用户愿意付费 | 至少 1 人愿意月付 ¥9.9 |

---

## 2. 五个核心验证指标

| # | 指标 | 定义 | 目标值 | 数据来源 |
|---|------|------|--------|---------|
| 1 | **数据覆盖率** | 7 天内有 ≥4 种指标完整的用户比例 | ≥ 60% | `DataQualityReport` + Beta Analytics |
| 2 | **建议采纳率** | `feedback.adherence` 为 `completed` 或 `partially_completed` 的比例 | ≥ 40% | `FeedbackStore` + 手动统计 |
| 3 | **安全旗标触发率** | `SafetyFlag` 标记的 LLM 响应 / 总 LLM 响应 | < 5% | Beta Analytics `safetyFlagTriggered` |
| 4 | **LLM Fallback 率** | 因网络/解析失败降级到规则引擎的比例 | < 15% | Beta Analytics `llmFallbackUsed` |
| 5 | **第二天验证有效率** | `VerificationReport.verdict` 为 `likely_helped` 的比例 | ≥ 30% | `VerificationReportStore` |

---

## 3. 需要观察的 Bug

### 3.1 数据链路 Bug（高优先级）

| Bug ID | 描述 | 预期发生率 | 影响 |
|--------|------|-----------|------|
| HD-01 | Apple Watch 未同步导致当天全部指标为空 | 20-40%（早晨打开时） | Today 页只显示 confidence low |
| HD-02 | HRV 一天只有 1 个样本 → 信号检测误报 `hrv_low` | 60-80%（大多数用户） | 错误地建议用户减少强度 |
| HD-03 | 用户关闭睡眠追踪 → 永久 missing sleep | 10-20% | Agent 永远无法建立恢复基线 |
| HD-04 | HKStatisticsQuery 在跨设备时返回 0 而非 nil | 未知 | 数据质量误判为 valid |

### 3.2 Agent 行为 Bug

| Bug ID | 描述 | 预期发生率 | 影响 |
|--------|------|-----------|------|
| AG-01 | 基线不足 7 天时给出过于自信的建议 | 新用户 100% | 用户体验差 |
| AG-02 | Demo scenario 切换到真实数据后状态残留 | 调试场景 | 数据混乱 |
| AG-03 | 连续收到相同建议时用户疲劳 | 30-50% | 留存下降 |

### 3.3 UI/UX Bug

| Bug ID | 描述 | 预期发生率 | 影响 |
|--------|------|-----------|------|
| UX-01 | Onboarding 7 步太长，用户中途退出 | 30-50% | 激活率低 |
| UX-02 | Today 页指标单位/符号与用户直觉不符 | 10-20% | 信任度下降 |
| UX-03 | Feedback 滑块 1-10 粒度太粗，用户不想填 | 40-60% | 验证数据不足 |

### 3.4 DeepSeek 特定 Bug

| Bug ID | 描述 | 预期发生率 | 影响 |
|--------|------|-----------|------|
| DS-01 | DeepSeek Chat Completions 返回的 JSON 格式不一致 | 5-10% | JSON 解析失败→fallback |
| DS-02 | `response_format: json_object` 但返回非 JSON（加了解释文本） | 2-5% | 解析失败 |
| DS-03 | API 超时或限流 | 5-15% | LLM 超时→fallback |

---

## 4. 用户反馈收集方式

### 方式一：App 内 Feedback 数据（现有功能）

用户每天在 Today 页提交：
- Adherence（是否完成建议）
- Energy（精力 1-10）
- Soreness（酸痛 1-10）
- Stress（压力 1-10）
- Note（自由文本）

→ 这些数据自动存入 `FeedbackStore`，用于验证引擎。

### 方式二：手动用户访谈（推荐）

每周一次 10 分钟 1:1 访谈，问 5 个问题：

1. 这周的建议有哪条你照做了？为什么？
2. 有没有觉得哪条建议不靠谱？为什么？
3. 你希望 app 多做什么？少做什么？
4. 你会因为这个 app 改变你的日常吗？
5. 你愿意为它付钱吗？（多少钱？）

### 方式三：Beta Analytics（现有功能）

自动收集的非敏感事件：
- App 打开次数
- 建议生成次数
- 反馈提交率
- 安全旗标触发次数
- Fallback 次数
- 同步失败次数

---

## 5. 上线前阻塞项

### 🔴 阻塞

| # | 阻塞项 | 谁负责 | 预计解决时间 |
|---|--------|--------|------------|
| 1 | 真机 HealthKit 数据流程未验证 | Developer | 1-2 天（需 Apple Watch） |
| 2 | DeepSeek API 真实调用未验证 | Developer | 即刻（模拟器 + API key） |
| 3 | 无 Apple Developer 付费账号 | 个人/团队 | 取决于付费决策 |

### 🟡 建议在 TestFlight 前完成

| # | 建议项 | 谁负责 | 预期时间 |
|---|--------|--------|---------|
| 4 | HealthKit 权限恢复引导（HealthPermissionRecoveryView） | Developer | ✅ 已完成 |
| 5 | BetaReadinessReport debug 面板 | Developer | ✅ 已完成 |
| 6 | 7 天基线不足时的 onboarding 引导 | Developer | 0.5 天 |
| 7 | HRV 单样本 partial 标记 | Developer | 0.5 天 |

### 🟢 TestFlight 后迭代

| # | 迭代项 | 依赖 |
|---|--------|------|
| 8 | 后端 auth 从 stub 升级到真实 JWT | 需要后端开发者 |
| 9 | 用户在设置中随时重新授权 HealthKit | HealthPermissionRecoveryView 已就绪 |
| 10 | 通知文案优化 | 用户反馈驱动 |

---

## 6. TestFlight 发布检查清单

- [ ] 真机验证通过（iPhone + Apple Watch 完整跑通一次）
- [ ] DeepSeek API 返回建议可解析
- [ ] 所有安全护栏正常工作
- [ ] Fallback 到规则引擎的降级链路正常
- [ ] HealthPermissionRecoveryView 可跳转系统设置
- [ ] BetaReadinessReport 各项指标显示正确
- [ ] App 图标和启动屏已配置
- [ ] 隐私政策链接可用
- [ ] TestFlight 导出合规声明已填写
- [ ] 3-5 名测试人员已邀请

---

## 7. Beta 时间线

| 周次 | 活动 | 产出 |
|------|------|------|
| Week 0（本周） | 真机验证 + DeepSeek 调通 | 阻塞项清零 |
| Week 1 | 上传 TestFlight build + 邀请 3-5 人 | Build 在 TestFlight 可用 |
| Week 2-3 | 收集反馈 + 每日查看 Analytics | 初步数据 |
| Week 4 | 汇总数据 → 决定是否继续 | Go/No-Go 决策 |

---

## 附录 A：降级链验证

```
Apple Health 无数据 → MockProvider (simulator/unauthorized)
DeepSeek API 无 key → MockLLMClient
DeepSeek 网络失败 → RuleBasedRecommendationGenerator
JSON 解析失败 → RuleBasedRecommendationGenerator
Safety flag → sanitize 后显示
```

所有降级路径需在 TestFlight 前逐条验证。

## 附录 B：关键文件引用

- 数据审计：`docs/real-device-validation.md`
- 权限恢复 UI：`OHeasApp/UI/HealthPermissionRecoveryView.swift`
- Beta 诊断面板：`OHeasApp/UI/BetaReadinessReport.swift` + `AgentContextView.swift` 扩展
- 项目状态：`docs/PROJECT_STATUS.md`
- TestFlight 准备：`docs/testflight-readiness.md`
