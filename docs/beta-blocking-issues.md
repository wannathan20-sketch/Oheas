# OHeas — Beta Blocking Issues Scan

> Scan date: 2026-06-09 | Scope: full-project grep for TODOs, FIXMEs, !, try!, data leaks

---

## 扫描范围

- `Sources/OHeasCore/` — 48 `.swift` files
- `OHeasApp/UI/` — 26 `.swift` files
- `backend/` — 4 files
- Config files: `project.yml`, `.gitignore`, `configure.sh`

---

## 扫描结果

### TODOs / FIXMEs

**0 found.** No code-level TODO or FIXME markers remain.

### fatalError

**0 found.**

### try!

**0 found.**

### Force unwraps `!`

**18 found. 0 are blockers.** All are either:
- `HKObjectType` system type identifiers (always available, 14 occurrences)
- Known UUID literal (1 occurrence in `AuthService.swift`)
- `calendar.date(byAdding:...)` edge near-end-of-range (1 in `AgentEvaluationRunner.swift`)
- URL construction from known-valid strings (1 in `OpenAIAppConfiguration.swift`)

None will crash under normal operation. If `calendar.date(byAdding:)` ever returned nil it would indicate a system clock / calendar bug, which isn't a fixable code issue.

---

## 发现的真实问题

### 🔴 BLOCKER — API Key Placeholder 可被直接构建

| 属性 | 值 |
|------|-----|
| Severity | **BLOCKER** |
| File | `project.yml:35` |
| Issue | `DEEPSEEK_API_KEY_PLACEHOLDER` 字面量存在 scheme 模板中。如果用户直接跑 `xcodegen generate` 而不是 `./configure.sh`，scheme 里的 `DEEPSEEK_API_KEY` 值就是这个占位字符串，DeepSeek API 会返回 401 而不是 fallback 到规则引擎 |
| Why it matters | 用户首次打开 app 看到的是 API error，不是 fallback 规则引擎建议。体验很差，且排错指向不明 |
| Suggested fix | `OpenAIAppConfiguration.load()` 增加一行：`if apiKey == "DEEPSEEK_API_KEY_PLACEHOLDER" { return nil }`，让占位符当 key 时自动 fallback |

### 🔴 BLOCKER — 未做过真机 HealthKit 数据验证

| 属性 | 值 |
|------|-----|
| Severity | **BLOCKER** |
| File | `Sources/OHeasCore/Data/HealthKitReader.swift` |
| Issue | 整个 HealthKit 数据链路（`HealthKitReader` → `DailyMetricsAggregator` → `SignalDetector` → `AgentContextBuilder` → `CoachPromptBuilder` → LLM → `CoachRecommendationParser`）只在 mock 数据和单元测试中验证过，从未在真实 iPhone + Apple Watch 上运行 |
| Why it matters | 已审计出 3 个高风险场景（HRV 单点噪声、睡眠追踪关闭、基线不足）——这些都是代码逻辑没问题但真实数据会触发边界行为的场景，必须在 TestFlight 前验证 |
| Suggested fix | 真机完整跑一次 smoke test（见 `docs/beta-smoke-test-checklist.md`） |

### 🟡 HIGH — DeepSeek Chat Completions 调用未经测试

| 属性 | 值 |
|------|-----|
| Severity | **HIGH** |
| File | `Sources/OHeasCore/LLM/LLMClient.swift` (ChatCompletionsClient) |
| Issue | `ChatCompletionsClient` 是新加的，虽然使用标准的 OpenAI Chat Completions API 格式，但 DeepSeek 的 `response_format: { type: "json_object" }` 实际行为未经测试。可能返回非 JSON（比如解释 + JSON）、或者 JSON 格式不符合 `CoachRecommendation` schema |
| Why it matters | LLM 调用是整个核心链路的关键环节。如果 JSON 解析失败，会 fallback 到规则引擎，用户看不到 AI 建议 |
| Suggested fix | 用 `DEEPSEEK_API_KEY` 在模拟器上跑一次完整建议生成，检查 `recommendationResult.source == "deepseek"` 且 `fallbackReason == nil`。如失败率 > 10%，考虑：1) 加 JSON 提取 fallback（从 non-JSON 响应中提取 {} 块）；2) 或者加 retry 逻辑 |

### 🟡 HIGH — Backend Auth Stub

| 属性 | 值 |
|------|-----|
| Severity | **HIGH** (对 cloud sync 正式用户) / **LOW** (对 TestFlight) |
| File | `Sources/OHeasCore/Backend/BackendAPIClient.swift:137`, `backend/app/main.py:32-34` |
| Issue | Backend 的 `current_user_id` 直接接受 `Bearer <uuid>` 作为身份认证——这不是真实 JWT，任何人知道你的 UUID 就能访问你的数据 |
| Why it matters | 如果 TestFlight 期间有人开启了 cloud sync 且部署了后端，数据没有真正的访问控制 |
| Suggested fix | 短期：TestFlight 期间建议用户保持 `LocalOnly` 模式（默认），不开启 cloud sync。长期：替换为 Supabase Auth / Clerk / Firebase Auth |

### 🟡 HIGH — DailyHealthMetrics sync 包含聚合数据但无白名单验证

| 属性 | 值 |
|------|-----|
| Severity | **HIGH** |
| File | `Sources/OHeasCore/Sync/SyncEngine.swift:92-94` |
| Issue | `containsRawHealthSampleKeys` 用关键词匹配（小写包含检查）来防止原始采样数据上传。这是一个黑名单机制，如果未来新增了包含敏感信息的字段名不在这 4 个关键词中，可能会被上传 |
| Why it matters | 安全防护依赖于持续维护关键词列表，而非白名单（可同步类型允许列表） |
| Suggested fix | 不紧急但需记录：未来建议改用 `SyncEntityType` 白名单 + 检查 `DailyHealthMetrics` 结构是否只包含聚合值（不含 raw samples），双重保护 |

### 🟡 MEDIUM — 模拟数据在真机上不会错误进入

| 属性 | 值 |
|------|-----|
| Severity | **LOW** |
| File | `Sources/OHeasCore/Data/MockHealthDataProvider.swift` |
| Issue | Mock 数据只在 HealthKit 读取失败或未授权时才使用（`OHeasViewModel.swift:117-125` 的 catch 路径）。这个降级逻辑是正确的。但是 `dataSource` 在 HealthKit 抛出异常但实际上是真实设备上短暂同步延迟时会被错误设为 `.mock` |
| Why it matters | 用户早晨打开 app 如果 Watch 数据尚未同步，HealthKit 可能不抛异常但返回空数组——这会让 `dataSource` 保持 `.appleHealth` 但指标全为 missing，不会错误进入 mock 模式。**当前代码逻辑是正确的。** 但如果 HealthKit 查询抛异常（如 `queryFailed`），会直接降级到 mock，导致用户看到 demo 数据而非真实数据 |
| Suggested fix | `HealthKitReader.fetchRawDailyData` 捕获 `queryFailed` 异常时在 ViewModel 层加判断：如果已授权但查询失败（可能是同步延迟），显示 "等待同步" 而非直接切 mock |

### 🟡 MEDIUM — 拒绝 HealthKit 后的 limited mode 无重新授权路径（文档问题）

| 属性 | 值 |
|------|-----|
| Severity | **LOW → 现在已修复** |
| File | `OHeasApp/UI/HealthPermissionRecoveryView.swift` |
| Issue | 上一阶段已新增了 `HealthPermissionRecoveryView`，用户可以从 Settings → Health Permissions 查看状态并跳转系统设置重新授权。此问题已解决 |
| Why it matters | N/A — 已修复 ✅ |

### 🟢 LOW — Sync 失败不会造成数据丢失

| 属性 | 值 |
|------|-----|
| Severity | **LOW** |
| File | `Sources/OHeasCore/Sync/SyncEngine.swift` |
| Issue | `syncNow` 遍历 pending 队列逐个上传。每个失败的 record 标记为 `.failed` 并增加 `retryCount`，保留在队列中不会丢失。`privacySettings` 在 conflict 时本地优先 |
| Why it matters | 数据安全 ✅。唯一改进点：retryCount 无上限，失败记录会堆积 |
| Suggested fix | 低优先级：建议 `retryCount >= 10` 自动 drop（加 `deletedAt` 时间戳），不影响用户体验 |

### 🟢 LOW — API Key 安全性已防护

| 属性 | 值 |
|------|-----|
| Severity | **LOW** |
| File | `.gitignore`, `configure.sh`, `deepseek.env` |
| Issue | ✅ `deepseek.env` 和 scheme 文件在 `.gitignore` 中。`configure.sh` 读取本地 `deepseek.env` 并注入 xcscheme。API key 不会进入 git |
| Why it matters | 验证通过 ✅。唯一建议：在 README 中说明首次设置需要 `cp deepseek.env.example deepseek.env` 然后填 key |

---

## 汇总

| # | Severity | Issue | Can ship TestFlight? |
|---|----------|-------|---------------------|
| 1 | 🔴 BLOCKER | API Key PLACEHOLDER → 401 error instead of graceful fallback | ❌ 先修 |
| 2 | 🔴 BLOCKER | 真机 HealthKit 数据未验证 | ⚠️ P0/P1 修复已完成（HRV partial、Signal 降级、连续缺失检测、基线引导），待真机 smoke test |
| 3 | 🟡 HIGH | DeepSeek 调用未实测 | ⚠️ 至少模拟器跑一次 |
| 4 | 🟡 HIGH | Backend auth 是 stub | ✅ 建议默认 LocalOnly |
| 5 | 🟡 HIGH | Raw sample 防护用黑名单 | ✅ 当前 4 个关键词覆盖 |
| 6 | 🟡 MEDIUM | Mock fallback 对真实设备友好 | ✅ 逻辑正确 |
| 7 | 🟢 LOW | 其他 | ✅ 不影响发布 |

---

## TestFlight 前必须解决

1. **Fix PLACEHOLDER key detection** — 1 行改动
2. **Run smoke test checklist** — 模拟器 + 真机各一次
3. **Verify DeepSeek call works** — 模拟器跑一遍

修完这 3 项即可打包。
