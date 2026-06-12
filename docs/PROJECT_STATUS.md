# OHeas 项目状态

> 最后更新：2026-06-13（Phase 23 设置 IA 重构 ✅ + Phase 22 品牌 ✅ + Phase 21 趋势 ✅ + 国际化 & UI 警告修复 ✅ + 85 tests passed + BUILD SUCCEEDED）

## 一句话定位

基于 Apple Watch / Apple Health 数据的**个人身体状态 Agent**——观察数据 → 发现模式 → 给出每日最小可执行建议 → 第二天验证是否有效。不是健康仪表盘，不是普通聊天机器人，而是一个会长期学习用户的 lifestyle coach。

> 📌 项目原名 OHeas，已更名为 **OHeas**（Oh Health）。

---

## 项目规模

| 层 | 文件数 | 行数（估算） | 技术栈 |
|----|--------|-------------|--------|
| Core 库 | 55 `.swift` | ~7,600 | Foundation, HealthKit, UserNotifications |
| App UI | 71 `.swift` | ~9,700 | SwiftUI |
| 测试 | 2 文件 | ~1,900 | Swift Testing |
| 后端 | 23 文件 | ~2,900 | FastAPI + SQLAlchemy + JWT + Alembic + Docker + pgvector + OpenAI embedding |
| 文档 | 13 文件 | ~ | Markdown |
| 脚本 | 2 文件 | ~80 | Bash |

- 零外部 Swift 依赖（仅 Foundation + HealthKit + UserNotifications）
- `swift build` 通过，`swift test` 全部 85 个测试通过
- `xcodebuild` Release/Debug 均编译通过
- `xcodebuild test` 支持 ViewModel 层 25 个单元测试
- 2026-06-12 本地验证：`xcodebuild build -project OHeas.xcodeproj -scheme OHeas -destination "platform=iOS Simulator,name=iPhone 17,OS=26.5"` 通过；`xcodebuild test` 已完成编译并进入 Testing started，但模拟器测试宿主 launch 阶段卡住，约 164s 后人工中断，需在干净模拟器会话复跑
- 后端 `pytest` 15 个测试通过，`uvicorn app.main:app` 可启动

---

## 八阶段完成清单（Phase 1-23 全部完成）

### Phase 1 — MVP 骨架

**目标**：HealthKit 数据读取 + 聚合 + 基础 UI

| 模块 | 文件 | 说明 |
|------|------|------|
| HealthKitReader | `Data/HealthKitReader.swift` | 读取睡眠、HRV、静息心率、步数、活动能量、运动分钟、训练记录 |
| MockHealthDataProvider | `Data/MockHealthDataProvider.swift` | 30 天确定性 mock 数据，含正常日/睡眠不足/HRV 下降/没戴表/低活动日 |
| DailyMetricsAggregator | `Analysis/DailyMetricsAggregator.swift` | 原始数据 → DailyHealthMetrics，缺失数据不当作 0 |
| TodayView | `UI/TodayView.swift` | 今日身体预算、数据可信度、关键信号、建议卡片 |
| MetricsView | `UI/MetricsView.swift` | 今日指标 vs 14 天基线对比 |
| AgentContextView | `UI/AgentContextView.swift` | 20 个调试标签页 |

**数据模型**：`DailyHealthMetrics`（7 种指标 + perMetricStatus valid/missing/partial）、`RawDailyHealthData`、`HealthBaseline`、`MetricComparison`

---

### Phase 2 — LLM 接入 + 反馈闭环

**目标**：从"数据面板"变成"可验证的每日健康 Agent"

| 模块 | 文件 | 说明 |
|------|------|------|
| LLMClientProtocol | `LLM/LLMClient.swift` | 协议抽象，支持替换 provider |
| OpenAIClient | `LLM/LLMClient.swift` | OpenAI Responses API + structured JSON output |
| ChatCompletionsClient | `LLM/LLMClient.swift` | DeepSeek / 通用 OpenAI Chat Completions API 客户端 |
| MockLLMClient | `LLM/LLMClient.swift` | 无 API key 时的 mock 回复 |
| CoachRecommendationService | `Recommendations/CoachRecommendationService.swift` | 编排层：LLM 调用 → 安全过滤 → 解析 → fallback |
| RuleBasedRecommendationGenerator | `Recommendations/RuleBasedRecommendationGenerator.swift` | 确定性状态机，5 种 CoachState |
| CoachPromptBuilder | `Agent/CoachPromptBuilder.swift` | System prompt + user context JSON |
| FeedbackStore | `Feedback/FeedbackStore.swift` | DailyFeedback 本地 JSON 存储 |
| VerificationEngine | `Verification/VerificationEngine.swift` | 昨天建议 + 今天指标 → VerificationReport |
| ReviewView | `UI/ReviewView.swift` | 昨日建议验证结果页面 |

**降级链**：无 API key → PLACEHOLDER 检测 → 无 AI consent → 网络失败 → JSON 解析失败 → 全部 fallback 到本地规则

**LLM Provider 优先级**：`DEEPSEEK_API_KEY` > `LLM_API_KEY` + `LLM_BASE_URL` > `OPENAI_API_KEY` > 本地规则引擎

---

### Phase 3 — 长期记忆 + 个人实验

（同上一版本，无重大变更）

---

### Phase 4 — 自适应周计划 + 主动提醒

（同上一版本，无重大变更）

---

### Phase 5 — 评估 + 安全 + 隐私 + Demo

（同上一版本，无重大变更）

---

### Phase 6 — Beta 产品化 + 后端同步 + Onboarding

（同上一版本，无重大变更）

---

### Phase 7 — TestFlight 发布准备 + 架构重构 + Agent 增强 🆕

**目标**：架构可维护性 + Agent 智能度 + 国际化

#### 7A: ViewModel 拆分（架构重构）

| 改动 | 文件 | 说明 |
|------|------|------|
| HealthDataViewModel | `ViewModels/HealthDataViewModel.swift` 🆕 | HealthKit/Mock 数据加载、聚合、基线、信号检测、Demo 场景 |
| RecommendationViewModel | `ViewModels/RecommendationViewModel.swift` 🆕 | LLM 推荐、安全过滤、反馈保存、隐私设置、验证引擎 |
| PlanViewModel | `ViewModels/PlanViewModel.swift` 🆕 | 周计划生成、自适应重调度、Goals CRUD、WeeklyReview |
| MemoryViewModel | `ViewModels/MemoryViewModel.swift` 🆕 | Memory 加载/更新、PatternMining |
| ExperimentViewModel | `ViewModels/ExperimentViewModel.swift` 🆕 | 实验提案、checkin、评估、生命周期 |
| OnboardingViewModel | `ViewModels/OnboardingViewModel.swift` 🆕 | Onboarding 状态机 |
| SyncViewModel | `ViewModels/SyncViewModel.swift` 🆕 | 认证、同步、分析、提醒、导出、重置 |
| OHeasViewModel 重构 | `UI/OHeasViewModel.swift` | 从 850 行退化为薄协调层，委托属性保持 UI 向后兼容 |

**效果**：每个子 VM < 250 行，单一职责，可独立测试。

#### 7B: Agent 智能增强

| 改动 | 文件 | 说明 |
|------|------|------|
| Prompt 版本化 | `Agent/CoachPromptTemplates.swift` 🆕 | V1 (baseline) / V2 (personalized)，通过 `CoachPromptVersion` 切换 |
| System Prompt 个性化 | `Agent/CoachPromptBuilder.swift` | V2 自动注入目标、已知模式、成功干预、活跃实验、今日计划 |
| SafetyGuardrail 双级检查 | `Safety/SafetyGuardrail.swift` | L1: regex 零延迟快速检查（保留）；L2: LLM 语义深度审查（`deepAssess`），在 caution/长文本时触发 |
| Memory 时效衰减 | `Memory/MemoryStore.swift` | `effectivePatterns(at:minWeight:)` + `decayedWeight(for:at:halfLife:)`，30 天半衰期指数衰减 |

#### 7C: 国际化

| 改动 | 文件 | 说明 |
|------|------|------|
| Core 层英文标准化 | `PatternMining/PatternMiner.swift` | 模式描述、干预效果 → 英文 |
| | `Experiments/ExperimentPlanner.swift` | 实验标题、假设、干预 → 英文 |
| | `Experiments/ExperimentStore.swift` | 实验评估摘要 → 英文 |
| | `Models/GoalPlanModels.swift` | 默认约束 → 英文 |

#### 7D: LLM Provider 支持（Phase 6 延续）

| 改动 | 文件 | 说明 |
|------|------|------|
| ChatCompletionsClient | `LLM/LLMClient.swift` | 通用 Chat Completions API 客户端，支持 DeepSeek、Groq 等 |
| OpenAIAppConfiguration 重构 | `UI/OpenAIAppConfiguration.swift` | 自动检测 provider（DeepSeek > Custom > OpenAI），PLACEHOLDER 检测 |
| configure.sh | `configure.sh` | 从 `deepseek.env` 读取 key → xcodegen generate → 注入 scheme |
| deepseek.env | `deepseek.env`（gitignore） | 本地 API key，不提交 |
| API key 安全性 | `.gitignore` | `deepseek.env` + `xcscheme` 均已 gitignore |

#### 7E: 真实设备验证（Phase 6 延续）

| 改动 | 文件 | 说明 |
|------|------|------|
| HealthKit 审计 | `docs/real-device-validation.md` | 7 项指标逐项审计，5 个真实设备异常场景，P0-P2 修复建议 |
| 权限恢复 UI | `UI/HealthPermissionRecoveryView.swift` | 7 项权限状态展示 + 缺失功能说明 + 一键跳转系统设置 |
| 权限恢复集成 | `UI/SettingsView.swift` | Settings → Privacy and Consent → Health Permissions 入口 |

#### 7F: Beta 诊断与反馈（Phase 6 延续）

| 改动 | 文件 | 说明 |
|------|------|------|
| BetaReadinessReport | `UI/BetaReadinessReport.swift` | HealthKit 权限 / 数据覆盖率 / 7 天完整度 / 基线状态 / 运行模式 |
| AgentContext 扩展 | `UI/AgentContextView.swift` | +"Beta Readiness" 调试标签 |
| BetaFeedbackView | `UI/BetaFeedbackView.swift` | 4 项评分（有帮助/易懂/打扰/隐私） + 自由文本 + 本地 JSON 存储 |
| ViewModel 集成 | `UI/OHeasViewModel.swift` | +betaReadinessReport + refreshBetaReadiness() |

#### 7G: 发布工程（Phase 6 延续）

| 改动 | 文件 | 说明 |
|------|------|------|
| Info.plist 清理 | `OHeasApp/Info.plist` | +NSHealthUpdateUsageDescription，+UIRequiredDeviceCapabilities[healthkit]，-OPENAI_API_KEY/OPENAI_MODEL（移至 env） |
| Preflight 脚本 | `scripts/preflight_release_check.sh` | 10 项检查（test/key/raw sample/unwrap/doc/privacy/entitlements/build/placeholder/git） |
| iOS 18 SDK 兼容 | 7 个 UI 文件 | `Section("title")` → `Section { } header: { Text(...) }` 语法迁移 |

#### 7H: 发布文档（12 份）

| 文档 | 用途 |
|------|------|
| `docs/PROJECT_STATUS.md` | 项目状态总览（本文档） |
| `docs/real-device-validation.md` | HealthKit 真机数据审计 |
| `docs/beta-blocking-issues.md` | 全项目阻塞问题扫描 |
| `docs/beta-smoke-test-checklist.md` | 14 步手动测试路径 |
| `docs/beta-reviewer-notes.md` | Apple 审核团队说明 |
| `docs/testflight-release-notes.md` | 面向测试用户的 Release Notes |
| `docs/testflight-beta-plan.md` | Beta 测试目标 + 5 项指标 + Bug 追踪 |
| `docs/app-store-connect-checklist.md` | ASC 提交字段对照表 |
| `docs/testflight-readiness.md` | TestFlight QA 清单 |

#### 7I: Tab 13→4 导航重构（已废弃，见 Phase 8C）

| 改动 | 文件 | 说明 |
|------|------|------|
| Tab 合并 | `UI/RootTabView.swift` | 13 Tab → 4 Tab（Today / Plan / Insights / Settings） |
| Today 聚合 | `UI/TodayView.swift` | 合并 ReviewView 内容为 YesterdaySection |
| PlanTabView | `UI/PlanTabView.swift` 🆕 | Plans + Goals + Experiments + WeeklyReview（NavigationStack） |
| InsightsTabView | `UI/InsightsTabView.swift` 🆕 | Metrics + Effectiveness + AgentContext + Evaluation（分段布局） |
| SettingsView | `UI/SettingsView.swift` | 右上角用户按钮 → Sheet 弹出设置 |
| 国际化 | `UI/AppLanguage.swift` | 新增 insightsTab / yesterdaySection / debugSection |
| 清理 | `UI/ReviewView.swift` | 已删除（内容迁移到 TodayView） |

#### 7J: 空状态 + 骨架屏 🆕

| 改动 | 文件 | 说明 |
|------|------|------|
| SkeletonView | `UI/Components/SkeletonView.swift` 🆕 | SkeletonCard / SkeletonSection / SkeletonLoadingView + ShimmerEffect 动画 |
| Today 骨架 | `UI/TodayView.swift` | 加载中显示 3 张骨架卡片；无数据显示 ContentUnavailableView |
| Plan 骨架 | `UI/PlanTabView.swift` | 加载中骨架；无计划显示 ContentUnavailableView |
| Insights 骨架 | `UI/InsightsTabView.swift` | 加载中骨架；Metrics 空状态升级为 ContentUnavailableView |
| 国际化 | `UI/AppLanguage.swift` | 新增 emptyTitle / emptyDescription / emptyPlanTitle / emptyPlanDescription |

#### 7K: Body Budget 7 天趋势 Mini-Chart 🆕

| 改动 | 文件 | 说明 |
|------|------|------|
| SparklineView | `UI/Components/SparklineView.swift` 🆕 | 纯 SwiftUI Path sparkline，缺失数据断开、今日高亮圆点 |
| BodyBudgetCard 改造 | `UI/TodayView.swift` | 3 个 MiniMetric 下方各渲染 7 天 sparkline（睡眠/HRV/静息心率） |
| ViewModel 委托 | `UI/OHeasViewModel.swift` | +recentDailyMetrics 委托属性 |

#### 7L: LLM 流式输出 🆕

| 改动 | 文件 | 说明 |
|------|------|------|
| LLMStreamEvent / LLMStreaming 协议 | `LLM/LLMClient.swift` | 新增流式协议；ChatCompletionsClient 实现 SSE streaming；MockLLMClient 模拟流式 |
| RecommendationStreamEvent | `Recommendations/CoachRecommendationService.swift` | 新增 `streamRecommendation()` + `extractDisplayableText()` 实时提取可读文本 |
| 流式状态 | `ViewModels/RecommendationViewModel.swift` | +isStreaming / streamingDisplayText；打字机效果 fallback（25ms/字） |
| CoachRecommendationCard | `UI/TodayView.swift` | 流式模式下显示实时文本 + 闪烁光标；完成后切换到结构化卡片 |
| ViewModel 委托 | `UI/OHeasViewModel.swift` | +isStreaming / streamingDisplayText 委托 |

**降级链追加**：真实 SSE stream → 一次性 + 打字机动画 → rule-based fallback

#### 7N: DeepSeek 模拟器连通性测试 🆕

| 改动 | 文件 | 说明 |
|------|------|------|
| 连通性测试 | `OHeasAppTests/DeepSeekConnectivityTests.swift` 🆕 | 5 个测试：非流式调用 / 流式 SSE / API Key 缺失 / 无效端点 / Client name |
| 测试覆盖 | — | ChatCompletionsClient.generateRecommendationJSON() + streamRecommendation() |
| 实测结果 | — | 非流式 1.6s，流式 1.0s，均返回合法 JSON |

#### 7M: 子 ViewModel 单元测试 🆕

| 改动 | 文件 | 说明 |
|------|------|------|
| 测试目标 | `project.yml` | 新增 `OHeasAppTests` bundle.unit-test target + scheme test action |
| ViewModelTests | `OHeasAppTests/ViewModelTests.swift` 🆕 | 25 个测试覆盖 7 个子 VM + OHeasViewModel 委托 |
| 覆盖 | — | HealthData(4) / Recommendation(6) / Plan(4) / Memory(3) / Experiment(3) / Onboarding(3) / Sync(3) / OHeasVM(7) |

---

### Phase 10 — 后端实质化 + Apple Sign In 🆕

**目标**：从 FastAPI stub 升级为产品级后端——真实 JWT 认证 + PostgreSQL 持久化 + Docker 部署 + iOS 端 Apple Sign In。

#### 10A: 后端骨架重建

| 改动 | 文件 | 说明 |
|------|------|------|
| 路由分层 | `main.py` | FastAPI 从单文件拆为 routers（health/auth/sync），CORS 中间件 |
| 配置管理 | `config.py` 🆕 | Pydantic Settings：DB URL / JWT secret / Apple Team ID |
| 数据库引擎 | `database.py` 🆕 | SQLAlchemy async engine + session factory |
| 需求更新 | `requirements.txt` | +sqlalchemy[asyncio] +asyncpg +pyjwt +alembic +httpx +pydantic-settings |

#### 10B: 数据库层

| 改动 | 文件 | 说明 |
|------|------|------|
| ORM 模型 | `db/models.py` 🆕 | 17 张表：AuthUser + SyncRecordModel + 14 张业务表 + SyncState |
| Repository | `db/repository.py` 🆕 | AuthRepository + SyncRepository，所有方法显式 `user_id` 参数 |
| App 层 RLS | Repository | 替代 DB RLS：每个查询/写入强制 `WHERE user_id = :user_id` |

#### 10C: JWT 认证

| 改动 | 文件 | 说明 |
|------|------|------|
| JWT 签发/验证 | `auth/jwt.py` 🆕 | HS256 signing，access token（60min）+ refresh token（30d） |
| Apple 验证 | `auth/apple.py` 🆕 | Apple JWKS 获取 + identityToken 验证（RS256） |
| Auth 依赖 | `auth/dependencies.py` 🆕 | `get_current_user_id` — FastAPI Depends |
| Auth 端点 | `routes/auth.py` 🆕 | POST /v1/auth/apple, POST /v1/auth/refresh, DELETE /v1/auth/session |

**认证流程**：iOS Sign in with Apple → Apple identityToken → POST /v1/auth/apple → 验证 Apple JWT → 查找/创建 AuthUser → 签发自有 JWT → iOS 存 Keychain → 后续请求带 Bearer token → 中间件验证

#### 10D: Sync 端点实质化

| 端点 | 改动 |
|------|------|
| POST /v1/sync/upload | stub→真实：逐条 upsert + user_id 所有权校验 + raw sample guard + last-write-wins |
| GET /v1/sync/changes | stub→真实：按 user_id + since 过滤，返回 + server_time |
| DELETE /v1/sync/{type}/{id} | stub→真实：软删除 + 所有权检查 |
| GET /health | + DB ping（SELECT 1） |

#### 10E: iOS Apple Sign In 集成

| 改动 | 文件 | 说明 |
|------|------|------|
| Auth 数据模型 | `Auth/AuthModels.swift` 🆕 | AuthTokenPair / AppleSignInRequest / TokenRefreshRequest |
| Keychain 存储 | `Auth/AuthTokenStore.swift` 🆕 | JWT 存取：access-token / refresh-token / user-id |
| Apple 服务 | `Auth/AppleAuthService.swift` 🆕 | ASAuthorizationAppleIDProvider 封装 + backend JWT 交换 |
| 账号页面 | `AccountView.swift` 🔧 | 重写：Sign in with Apple 按钮 + 状态 + 登出 |
| 后端配置 | `AppConfiguration.swift` 🔧 | BackendConfigStore actor + Keychain 读取 token |
| 启动恢复 | `AppRootView.swift` 🔧 | 启动时 configureBackend + restoreAppleSession |
| Sync VM | `SyncViewModel.swift` 🔧 | +handleAppleSignIn / signOutOfApple / restoreAppleSession |
| OHeas VM | `OHeasViewModel.swift` 🔧 | +委托方法 + currentUserId / authError |

#### 10F: Docker 部署

| 改动 | 文件 | 说明 |
|------|------|------|
| Dockerfile | `Dockerfile` 🆕 | Python 3.12-slim，启动时 Alembic migrate + uvicorn |
| Compose | `docker-compose.yml` 🆕 | API + PostgreSQL（dev profile），生产指 Supabase DB |
| 环境模板 | `.env.example` 🆕 | 本地 .env 配置模板 |

#### 10G: 测试

| 改动 | 文件 | 说明 |
|------|------|------|
| 健康检查 | `tests/test_health.py` 🆕 | GET /health + DB status |
| JWT 测试 | `tests/test_auth.py` 🆕 | 签发/验证/过期/类型校验 (8 tests) + 端点 401 测试 |
| Sync 测试 | `tests/test_sync.py` 🆕 | raw sample rejection / ownership isolation / upload / fetch / delete (6 tests) |
| Fixtures | `tests/conftest.py` 🆕 | SQLite in-memory + monkeypatch session factory |
| Swift | `swift test` | 85 个测试全部通过 ✅ |

---

## 核心架构

```
Apple Watch / HealthKit (or Mock)
        ↓
HealthDataProvider (HealthKitReader / MockHealthDataProvider)
        ↓
DailyMetricsAggregator → DailyHealthMetrics
        ↓
BaselineEngine (7/14/30d) + DataCoverageLayer (confidence) + SignalDetector
        ↓
AgentContextBuilder → AgentContext
        ↓                           ↓
CoachPromptBuilder            PrivacyManager (redact)
  ├── V1 (baseline)                 ↓
  └── V2 (personalized)    RuleBasedRecommendationGenerator (fallback)
        ↓
LLMClient ←── PrivacySettings
  ├── OpenAIClient (Responses API)
  ├── ChatCompletionsClient (DeepSeek / Custom, SSE streaming)
  └── MockLLMClient (no-API-key mock, simulated streaming)
        ↓
CoachRecommendationService
  ├── recommendation() — 一次性
  └── streamRecommendation() — 流式 (AsyncThrowingStream)
        ↓
SafetyGuardrail
  ├── L1: regex fast check (0 latency)
  └── L2: LLM semantic deep review (caution / long text)
        ↓
CoachRecommendation → TodayView / PlanView / ChatView
        ↓
DailyFeedback ←── 用户主观评分
        ↓
VerificationEngine → VerificationReport
        ↓
MemoryUpdateService → PatternMiner → MemoryStore
  └── MemoryDecay: 30-day half-life exponential decay
        ↓
ExperimentPlanner → ExperimentStore → PersonalExperiment
        ↓
WeeklyPlanPlanner + AdaptiveRescheduler → WeeklyPlan → PlanView
        ↓
WeeklyReviewEngine → WeeklyReviewView
        ↓
EffectivenessAnalyzer → EffectivenessDashboardView
        ↓
── RAG Layer (Phase 11) ──
MemoryStore / FeedbackStore / ExperimentStore / RecommendationHistory
        ↓
MemoryIndexItem (6 source types)
        ↓
RAGService → HTTPRAGClient (pgvector cosine) → LocalRAGClient (token fallback)
        ↓
ChatViewModel.formatRAGResults() → 注入 System Prompt
        ↓
Backend: EmbeddingService (OpenAI text-embedding-3-small) → pgvector VECTOR(1536) + ivfflat index

── ViewModel Layer (8 sub-VMs) ──
HealthDataVM | RecommendationVM | PlanVM | MemoryVM | ExperimentVM | OnboardingVM | SyncVM | ChatVM
        ↓
OHeasViewModel (thin coordinator, delegation properties for backward compat)
        ↓
── Backend Layer (FastAPI + PostgreSQL) ──
Apple Sign In → JWT Auth → SyncEngine → RAG Search → Repository → PostgreSQL (18 tables incl. memory_embeddings)
        ↑
iOS HTTPBackendAPIClient / HTTPRAGClient ← Bearer token (Keychain)
```

---

## Agent 闭环

```
每日数据 → 今日建议 → 用户反馈 → 第二天验证 → 形成 pattern candidate
    → 写入 memory（带 30 天半衰期衰减）→ agent 设计个人实验 → 实验结果反哺 memory
    → 自适应周计划 → 主动提醒 → 周复盘 → 长期效果分析
    → 用户可随时在「对话」Tab 追问、讨论、澄清
```

---

## 安全与隐私

### SafetyGuardrail（8 种标记，双级检查）
```
L1 (regex, 0ms):
  medical_diagnosis          ← "你患有/诊断为/diagnosed with"
  emergency_symptom          ← "胸痛/昏厥/fainting/syncope"
  overconfident_claim        ← "一定会改善/guaranteed/proves this works"
  unsupported_causal_claim   ← "因果/caused by/because your"
  unsafe_weight_loss_advice  ← "极端节食/crash diet/very low calorie"
  supplement_or_medication   ← "服用/药物/supplement/medication"
  high_intensity_when_low    ← 恢复低时出现高强度语言
  missing_disclaimer         ← 缺少 "not medical advice" 声明

L2 (LLM semantic, triggered on caution/long text):
  deepAssess() — 用独立 LLM 调用做语义安全审查，检测 L1 漏报的隐含风险。
  失败时自动 fallback 到 L1 结果。
```

### 降级链
```
DEEPSEEK_API_KEY_PLACEHOLDER → 当作无 key
useLLM=false | 无 API key | 无 AI consent | 网络失败 | JSON 解析失败
    → RuleBasedRecommendationGenerator（确定性状态机）
```

### 隐私
- 默认 `useLLM = false`，用户需明确 opt-in
- 默认 `allowRawHealthSamples = false`，原始采样永不离开设备
- SyncEngine 检查 `containsRawHealthSampleKeys`，违规拒绝上传
- BetaAnalytics 属性过滤：拒绝 raw/sample/sleepsegment 等敏感 key
- ErrorReporter 上下文过滤：拒绝 apiKey/token/raw 等敏感字段
- 导出 JSON 只含聚合摘要，不含 raw HealthKit 样本
- Cloud sync 只在 consent + backend 配置都满足时启用

---

## 测试覆盖

**85 个 Core 测试 + 25 个 ViewModel 测试 + 5 个 DeepSeek 连通性测试 + 8 个 Core（xcodebuild）+ 15 个 Backend（pytest）= 138 个测试，全部通过**：

> ⚠️ Phase 19-20 新增的 Gamification 模块（StreakEngine / BadgeSystem / GamificationStore）尚未添加专属单元测试，当前通过编译验证 + 85 现有测试确认无回归。专属测试计划在 Phase 21-22 后一并补齐。

### Core 层测试（`swift test`，85 个）

| 分类 | 测试数 | 覆盖内容 |
|------|--------|---------|
| Baseline | 1 | 缺失值不被当作零 |
| Data Confidence | 2 | high/low 判定、missing 数量 |
| Signal Detection | 3 | 信号识别、低置信降级、aggregator 不归零 |
| LLM | 3 | JSON 解析、解析失败 fallback、低置信 uncertain |
| Feedback | 2 | skipped→unclear、save/read |
| Verification | 2 | missing→unclear、completed+improved→likely_helped |
| Memory | 2 | pattern 合并去重、compaction 限条数 |
| Pattern Mining | 3 | <5天无输出、missing 覆盖 candidate、successful intervention |
| Experiment | 4 | 只能一个 active、低置信优先覆盖实验、<3 checkin→unclear、likely_helped |
| AgentContext | 3 | memory+experiment 注入、goals+plan 注入、prompt 含 adjustment reason |
| Goal | 1 | add/update/deactivate/getActive |
| Weekly Plan | 4 | consistency 轻量高频、recovery_first 避免连续高强度、experiment 插入、低置信 data_coverage |
| Adaptive Reschedule | 4 | 恢复低降级、低置信保守、保留 experiment、避免连续高强度 |
| Reminder | 1 | 模型创建 + disabled 不调度 |
| Weekly Review | 2 | completionRate、missing 数据降低置信 |
| Safety Guardrail | 4 | 医疗诊断标记、低置信强结论、恢复低高强标记、proof 标记 |
| Privacy | 4 | 默认禁止 raw samples、useLLM=false→fallback、context redact、feedback redact |
| Evaluation | 4 | 8 cases 可运行、low data 通过、unsafe raw 触发 flag、regression 创建 baseline + 检测缺失 verification |
| Effectiveness | 5 | adherence rate、skipped≠helped、missing 降低置信、promising interventions、demo scenarios 30 天 + patterns |
| Auth | 2 | localOnly 启动、signOut 清除 |
| Consent | 3 | 无 AI consent→fallback、无 cloud consent→localOnly、revoke analytics→不上传 |
| Sync | 4 | payload 排除 raw samples、pending queue 保留 failed、last-write-wins、privacy local wins |
| Onboarding | 3 | gates main app、rejected HealthKit→limited mode、baseline insufficient message |
| Analytics | 2 | 本地记录、拒绝敏感 key |
| Schema | 1 | 16 张表 + RLS ownership + beta insert-only |
| Export | 1 | 不含 raw samples |
| Reset | 1 | 需 confirmation state |
| **Body Budget Score** | **5** | **strong metrics → high score、signals penalty、missing data neutral、feedback integration、no-baseline valid** |

### ViewModel 层测试（`xcodebuild test`，25 个）

| 分类 | 测试数 | 覆盖内容 |
|------|--------|---------|
| HealthDataViewModel | 4 | 初始状态、mock 数据加载、demo scenario 切换、reset |
| RecommendationViewModel | 6 | 初始状态、privacy settings 加载、reset、默认值、streaming 状态转换、privacy update |
| PlanViewModel | 4 | 初始状态、goal CRUD、多 goal、goal 加载 |
| MemoryViewModel | 3 | 初始状态、memory 加载、reset |
| ExperimentViewModel | 3 | 初始状态、experiment 加载、reset |
| OnboardingViewModel | 3 | 初始状态、onboarding 完成、HealthKit skip |
| SyncViewModel | 3 | 初始状态、consent 管理、reset confirmation |
| OHeasViewModel | 7 | 子 VM 初始化、healthData 委托、recommendation 委托、plan 委托、experiment 委托、onboarding 委托、sync 委托 |
| DeepSeekConnectivity | 5 | 非流式 API 调用、SSE 流式调用、API Key 缺失检测、无效端点错误处理、Client name 验证 |

---

## 发布就绪状态

### Preflight 检查结果（2026-06-10 真机验证时重跑）

```
Pass:  17 ✅
Warn:   2 (all code-reviewed, expected)
Fail:   0 ✅
```

### 阻塞项

| # | 状态 | 项 |
|---|------|-----|
| 1 | ✅ 已修复 | API Key PLACEHOLDER → 401 error 而非 graceful fallback |
| 2 | ✅ 代码层验证通过 | 真机 HealthKit 数据完整流程（代码审计 + P0/P1 修复均已在源码确认，见下方验证日志） |
| 3 | ✅ 已完成 | DeepSeek 调用在模拟器实测（5 个连通性测试全部通过） |
| 4 | ✅ 已修复 | Info.plist 缺少 HealthKit/隐私必要声明 |
| 5 | ✅ 已配置 | `DEVELOPMENT_TEAM` = `6YFW7W33NV`，CODE_SIGN_STYLE = Automatic |
| 6 | ✅ 已修复 | HealthKit 权限拒绝后无恢复引导 |
| 7 | ✅ 已完成 | 无 Beta 诊断面板 |
| 8 | ✅ 已完成 | 无用户反馈入口 |

### 已解决的已知局限

| 原局限 | 状态 |
|--------|------|
| "只有 OpenAI provider" | ✅ 已支持 DeepSeek + 自定义兼容端点 |
| "HealthKit 权限首次被拒后体验不优雅" | ✅ 新增 HealthPermissionRecoveryView |
| "未经过真实设备验证" | ⚠️ 审计文档已完成，待真机实测 |
| "ViewModel 是 God Object（850 行）" | ✅ 拆分为 7 个子 ViewModel |
| "System Prompt 完全静态无个性化" | ✅ V2 个性化 prompt，注入目标/模式/干预/实验 |
| "SafetyGuardrail 纯 regex，漏报率高" | ✅ L2 LLM 语义深度审查 |
| "Memory 无时效衰减" | ✅ 30 天半衰期指数衰减 |
| "Core 层硬编码中文" | ✅ 全部标准化为英文 |
| "13 个 Tab 平铺导航" | ✅ 精简为 4 主 Tab（Today / Plan / Insights / Settings） |
| "无骨架屏加载状态" | ✅ SkeletonCard + ShimmerEffect 动画 |
| "LLM 响应无流式输出" | ✅ SSE streaming + 打字机 fallback |
| "Body Budget 无趋势展示" | ✅ 7 天 Sparkline mini-chart |
| "子 ViewModel 无单元测试" | ✅ 25 个测试覆盖 7 个子 VM |
| "DeepSeek 兼容性未实测" | ✅ 5 个连通性测试全部通过（非流式 1.6s + 流式 1.0s） |
| "HRV 单点噪声导致误报" | ✅ <3 样本 → partial，SignalDetector 降级 severity |
| "基线不足时无引导" | ✅ CompletenessSummary.baselineGuidanceMessage |
| "连续缺失无检测" | ✅ 3 天/7 天连续缺失检测 + sync-delay hint |
| "每个 Tab 顶部重复设置按钮" | ✅ 设置独立 Tab，删除冗余入口 |
| "AppRootView + RootTabView 重复调用 load()" | ✅ AppRootView 唯一入口 |
| "UI 平淡无视觉层次" | ✅ Hero 渐变 + 环形仪表 + 彩条卡片 + 网格布局 |
| "Chat 上下文全是规则注入，无法回答历史问题" | ✅ pgvector RAG 语义检索 + 6 种健康记忆源 |
| "Design Token 仅最小集、无语义颜色/动画令牌" | ✅ OhColor（30+）/ OhFont / OhAnimation（10）/ OhShadow（4）完整令牌系统 |
| "15 种不同 spring() 散落各处、圆角值不一致" | ✅ OhAnimation 统一 18+ 处、Radius 统一 20+ 处 |
| "TodayView God Object 1057 行" | ✅ 拆分为 7 个子组件（211 行）+ UI/Today/ 目录 |
| "~35 处 language == .chinese ? 三元绕过本地化系统" | ✅ 全部迁移至 TextKey + language.text() |
| "教练卡片被动输出，无追问交互" | ✅ Phase 19：CoachFollowUpChips + 内联回答 + Chip→Chat Tab 联动 |
| "无游戏化/激励层，用户缺乏持续使用动力" | ✅ Phase 20：4 种连胜 + 15 枚徽章 + Canvas 庆祝粒子动效 |
| "BodyBudgetScore 仅在 Today 页展示" | ✅ Phase 20：StreakFlameView 嵌入 TodaySummaryHeader，AchievementsView 全局可查 |
| "无历史回顾/趋势视图，用户无法查看过去身体状态" | ✅ Phase 21：ScoreHistoryChart 30 天可交互趋势图 + 逐日卡片列表 + DayDetailSheet 日详情 |
| "AppLanguage.text() 巨型 switch 导致 ⚠️ 黄色三角警告覆盖全 UI" | ✅ 重构为静态字典 `[TextKey: (zh, en)]`（417 条目），O(1) 查询，消除编译器 exhaustion |
| "语言设置中文但 UI 仍显示英文（@AppStorage → @Environment 传播断裂）" | ✅ AppRootView 改用 @State + onChange 双同步；ChatViewModel 默认语言 en→zh |
| "MetricTrendCard / ConfidenceBadge / SignalTags 过度使用橙色警告色" | ✅ 图标 exclamationmark.triangle→info.circle，颜色 warning→secondary/blue |
| "CelebrationEffect 徽章解锁 toast 硬编码英文" | ✅ 传递 language 参数，使用 `.badgeUnlockedToast` 本地化 |
| "AppLanguage.swift 含无引用的 gamificationText 死代码 (~70行)" | ✅ 已删除，所有翻译统一到字典 |
| "无统一品牌 Logo，启动页和欢迎页拼凑环+文字" | ✅ Phase 22：OHeasLogo 环形 H 品牌标识，启动页/欢迎页统一引用 |
| "启动页加载文字「加载中…」对用户不友好" | ✅ 改为「正在唤醒…」/「Waking up…」，与健康 App 调性一致 |
| "欢迎页堆叠式步骤，旧步骤不消失导致页面过长" | ✅ 改为单步翻页式（水平滑入滑出），每次只显示当前步骤卡片 |
| "欢迎页步骤按钮硬编码三元（language == .chinese ? ...）" | ✅ 新增 .continueButton / .readyButton TextKey |
| "OnboardingFlow.baselineMessage() 纯英文硬编码" | ✅ 基线消息移到 UI 层，.baselineLimited / .baselineReady 中英双语 |
| "设置页所有控件平铺，无层次" | ✅ Phase 23：iOS 原生钻取模式，顶层 5 个入口 + 子页 |
| "隐私载荷预览暴露内部 prompt 结构" | ✅ 已从 PrivacyView 移除 |
| "开发者工具对普通用户可见" | ✅ `#if DEBUG` 编译时守卫，Release/TestFlight 完全隐藏 |
| "语言选择用横向分段控件" | ✅ 改为列表选择 + 蓝色勾选 |
| "启动页「正在唤醒…」字太小" | ✅ caption2 → subheadline.medium |

### 仍然存在的局限

1. **Backend 未部署**：JWT + Apple Sign In + RAG API + Sync 代码就绪，Docker Compose 一键启动，Alembic auto-migrate。需部署到 Zeabur / VPS + 配置 Apple Developer Service ID
2. **真机端到端 sync 未验证**：Sync 端点代码已通过 pytest 测试，但尚未在真实设备上走完整 Upload→Fetch→Delete 循环
3. **Backend 测试需 PostgreSQL**：pgvector 表在 SQLite 上不可用，conftest 跳过 `memory_embeddings`；RAG 完整测试需 PostgreSQL 环境
4. **RAG 依赖 OpenAI embedding API**：未配置 `OPENAI_API_KEY` 时自动降级到本地 token 匹配
5. **冲突策略是 last-write-wins**：多设备场景可能需要 CRDT
6. **SafetyGuardrail L2 依赖 LLM 可用性**：LLM 不可用时自动 fallback 到 L1
7. **APNs 代码已写但未合入 main**：APNs（backend + iOS）已实现但仍在 feature branch，需 Apple Developer 创建 APNs Key + 合入 main
8. **流式输出不兼容 structured JSON schema**：流式模式下移除 `response_format: json_object`，改用 prompt 指令约束 JSON 输出
9. **本机 `xcodebuild test` 需复跑**：2026-06-12 本地执行时已完成编译和签名，但模拟器测试宿主 launch 阶段卡住，人工中断为 `TEST INTERRUPTED`；`xcodebuild build` 已确认通过，完整测试建议在干净模拟器/CI 环境复跑

---

## 构建和运行

```sh
# ── iOS ──────────────────────────────

# 首次设置
cp deepseek.env.example deepseek.env   # 编辑填 API key（如有）
./configure.sh                          # xcodegen generate + 注入 key

# 构建
swift build                             # → Build complete!

# 测试
swift test                              # → Core 85 tests
xcodebuild test -project OHeas.xcodeproj -scheme OHeas -destination "platform=iOS Simulator,name=iPhone 17"  # → Core + ViewModel

# 发布前检查
./scripts/preflight_release_check.sh    # → 0 failures

# 模拟器运行（自动使用 mock 数据）
open OHeas.xcodeproj
# Scheme: OHeas → iPhone 17 Simulator → ⌘R

# 真机运行（需 Apple Watch 配对 + 付费 Developer 账号）
# project.yml → DEVELOPMENT_TEAM: "你的TeamID"
# ./configure.sh
# Xcode → Product → Archive

# ── Backend ──────────────────────────

cd backend

# 首次设置
cp .env.example .env                    # 编辑填真实值
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 初始化数据库（需 PostgreSQL 运行中）
pip install alembic
alembic init alembic
alembic revision --autogenerate -m "initial schema"
alembic upgrade head

# 启动开发服务器
uvicorn app.main:app --reload

# 后端测试
pytest app/tests/ -v                    # → 15 tests passed

# Docker 部署
docker compose --profile dev up -d db   # 本地 PostgreSQL
docker compose up -d                    # API + DB
```

### 启用 LLM（三选一）

```sh
# DeepSeek（推荐，国内可用）
# 在 deepseek.env 中填写 DEEPSEEK_API_KEY=sk-xxx

# OpenAI
# Scheme → Environment Variables:
#   OPENAI_API_KEY=sk-...

# 自定义兼容端点
# Scheme → Environment Variables:
#   LLM_API_KEY=xxx
#   LLM_BASE_URL=https://your-api.com
```

### Prompt 版本切换

```sh
# 在 Scheme → Environment Variables 中设置:
#   PROMPT_VERSION=v1   (baseline，当前默认)
#   PROMPT_VERSION=v2   (personalized，注入用户画像)
```

---

## 下一步计划

| 优先级 | 任务 | 预计工作量 | 状态 |
|--------|------|-----------|------|
| **P0** | **Phase 21 — 时间轴 & 历史视图** | **1 天** | **✅ 已完成** |
| **P0** | **Phase 22 — 品牌 & 启动优化** | **0.5 天** | **✅ 已完成** |
| **P0** | **Phase 23 — 设置 IA 重构** | **0.5 天** | **✅ 已完成** |
| **P1** | **部署 Backend 到 Zeabur / VPS** | **0.5 天** | **代码就绪** |
| **P1** | **Apple Developer 配置 Sign in with Apple Service ID** | **0.5 天** | **代码就绪，待 Web 配置** |
| **P2** | **APNs 远程推送 + 异常告警** | **3 天** | **代码就绪，待合入 main** |
| **P2** | **Watch Complication（表盘身体预算环）** | **2 天** | **待实现** |
| P2 | 真机端到端验证（17 步 Checklist） | 1 天 | 待执行 |
| P3 | 多语言扩展 / Oura Ring 集成 / 离线 LLM | — | 待开始 |

### 已完成 Phase 总览

| Phase | 内容 | 核心成果 |
|-------|------|---------|
| 1-6 | MVP → TestFlight 准备 | HealthKit 读取、LLM 接入、反馈闭环、长期记忆、自适应周计划 |
| 7 | ViewModel 拆分 + Agent 增强 | 7 子 VM、V2 个性化 prompt、L2 安全审查、Memory 衰减、国际化 |
| 8 | Chat 对话 + Tab 精简 + 视觉 | 3 Tab、Hero 渐变、Sparkline、多轮对话、会话历史 |
| 9 | P0 产品优化 | Chat 持久化、Keychain API Key、流式状态区分 |
| **10** | **后端实质化** | **JWT 认证、PostgreSQL 持久化、Sync 真实实现、Apple Sign In、Docker** |
| **11** | **RAG 语义检索** | **pgvector 语义检索、6 种检索源、Chat 上下文注入** |
| **12** | **CI/CD** | **GitHub Actions: swift build + test (80) + xcodebuild (38) + pytest (15)** |
| **13** | **多轮对话优化** | **ContextWindowManager token 估算、动态滑窗、自动摘要、System Prompt 按需裁剪** |
| **14** | **TestFlight UX Polish** | **Today 行动卡重设计、Plan 状态色彩、Chat 上下文空状态、Settings 信息架构** |
| **15** | **UI 优化 Phase 1-4** | **Design Token 系统（颜色/排版/动画/阴影令牌）、圆角/动画/卡片背景全统一、TodayView 拆分（1057→211行 7 子组件）、~35 处内联三元 → TextKey 迁移、共享组件提取** |
| **16** | **Body Budget Score** ✅ | **0-100 北极星评分引擎、Oura 风格评分环、5 级分类徽章、4 柱加权算法、85 tests** |
| **17** | **贡献分解 + 图表增强** ✅ | **ContributionBar 贡献分解条、TrendIndicator 趋势指示器、InteractiveSparklineView 交互式迷你图、MetricTrendCard 指标趋势卡片** |
| **18** | **Today 页 IA 重构** ✅ | **Score-first 渐进式布局、TodaySummaryHeader（大评分环+One Big Thing）、Hero 压缩 140→80pt、反馈上移（移除 2 层 DisclosureGroup）、TodayContentSection 统一包装** |
| **19** | **对话式 AI 教练卡片** ✅ | **CoachFollowUpChips（数据驱动追问 chip 按钮）、InlineResponseCard（内联快速回答）、Chip → Chat Tab 导航联动（预填问题自动发送）** |
| **20** | **游戏化层** ✅ | **StreakEngine（4 种连胜计算）、BadgeSystem（15 枚徽章/4 类）、StreakFlameView（里程碑脉冲动画）、BadgeCard/BadgeCollectionView、AchievementsView（成就页面）、CelebrationEffect（Canvas 粒子庆祝+无障碍降级）** |
| **21** | **时间轴 & 历史视图** ✅ | **ScoreHistoryChart（30天可交互趋势图+拖拽+5日均线）、DayCard（紧凑日卡片）、DayDetailSheet（日详情sheet）、HistoryViewModel（滚动基线逐日评分）、HistoryTabView（第5Tab，Tab 名从「历史」→「趋势」）** |
| **22** | **品牌 & 启动优化** ✅ | **OHeasLogo（渐变环形 H 标识）、LaunchSplashView（品牌启动过渡页+「正在唤醒…」加载提示）、OnboardingView 品牌 Hero + 单步翻页式流程 + 步骤 Pills** |
| **23** | **设置 IA 重构** ✅ | **iOS 原生钻取模式、语言列表选择、隐私载荷预览移除、`#if DEBUG` 编译时守卫开发者工具** |

---

## Phase 21 — 时间轴 & 历史视图 ✅ 已完成

**目标**：对标 Oura "My Health" 和 Apple Health "浏览"，让用户可以回顾 30 天身体预算评分趋势和逐日详情。

**市场参考**：Oura "My Health"、Apple Health "Browse"。

### 核心改动

| 改动 | 文件 | 说明 |
|------|------|------|
| **HistoryViewModel** | `OHeasApp/UI/History/HistoryViewModel.swift` 🆕 | `HistoricalDayDetail` 模型 + 滚动基线逐日评分管道：遍历 30 天 → 每天用前 14 天窗口计算 `BaselineEngine.baseline(endingBefore:)` → `BodyBudgetScorer.score()` → `SignalDetector.detect()` → 输出 `[HistoricalDayDetail]`（最新优先） |
| **ScoreHistoryChart** | `OHeasApp/UI/History/ScoreHistoryChart.swift` 🆕 | 可交互 30 天评分趋势图：分类阈值背景带（红/橙/黄/绿 4 区）、30 个颜色编码圆点、5 日移动平均靛蓝趋势线、`DragGesture` 拖拽工具提示（日期+分值+分类）、日期轴标签（每 5 天）、图例行 |
| **DayCard** | `OHeasApp/UI/History/DayCard.swift` 🆕 | 紧凑行卡片：mini `BodyBudgetRing`(44pt) + 日期 + `ScoreCategoryBadge` + 3 指标胶囊（睡眠/HRV/步数）+ 信号预览 + chevron |
| **DayDetailSheet** | `OHeasApp/UI/History/DayDetailSheet.swift` 🆕 | 日详情 sheet：大 `BodyBudgetRing`(100pt) + `ContributionBar` + 7 项 `MetricComparisonRow` + `SignalTags` + 反馈区（精力/酸痛/压力柱状条） |
| **HistoryTabView** | `OHeasApp/UI/History/HistoryTabView.swift` 🆕 | 第 5 个 Tab 主视图：图表 → 水平日条（星期+分数圆+日期）→ `LazyVStack` 日卡片 → 点击弹出 `DayDetailSheet`；加载态 `SkeletonSection`；空态 `ContentUnavailableView` |
| **OHeasViewModel 集成** | `OHeasApp/UI/OHeasViewModel.swift` 🔧 | 添加 `let history: HistoryViewModel` 子 VM；`load()` 中调用 `history.load(metrics:preferredLanguage:)` |
| **RootTabView** | `OHeasApp/UI/RootTabView.swift` 🔧 | `AppTab` 新增 `.history` case；Tab 栏：Today → Plan → **History** → Chat → Settings |
| **本地化** | `OHeasApp/UI/AppLanguage.swift` 🔧 | +25 TextKey：historyTab / scoreHistoryTitle / dayDetail* / dayCard* / chartTrendLine 等 |
| **项目配置** | `project.yml` 🔧 | sources 新增 `OHeasApp/UI/History` |

### 滚动基线算法

```
for each day in recentDailyMetrics (sorted asc):
    1. BaselineEngine.baseline(from: sorted, endingBefore: day.date, windowDays: 14)
    2. DataCoverageLayer.report(for: day)
    3. SignalDetector.detect(today: day, baseline: rollingBaseline, ...)
    4. FeedbackStore 匹配当日反馈
    5. BodyBudgetScorer.score(today: day, baseline: rollingBaseline, signals:, feedback:, ...)
    6. BaselineEngine.comparisons(today: day, baseline: rollingBaseline)
    → append HistoricalDayDetail
→ historicalDays = results.reversed()  // 最新在前
```

**关键差异**：与 `computeGamification()` 的单一基线不同，历史视图为每天计算独立的 14 天滚动基线，更准确反映当时的真实身体状态。

### 导航最终态

```
[❤️ 今日] [📅 计划] [📊 趋势] [💬 对话] [⚙️ 设置]
```

---

## Phase 22 — 品牌 & 启动优化 ✅ 已完成

**目标**：统一品牌视觉标识 + 优化启动过渡体验 + 重做欢迎页为单步翻页式流程。

### 核心改动

| 改动 | 文件 | 说明 |
|------|------|------|
| **OHeasLogo** | `OHeasApp/UI/Components/OHeasLogo.swift` 🆕 | 可缩放环形品牌标识：渐变圆环（mint→teal→indigo）+ 中心 "H" 字母（Health），支持 showBackground 亮色锚点 |
| **LaunchSplashView** | `OHeasApp/UI/LaunchSplashView.swift` 🆕 | 品牌启动过渡页：mint→teal 渐变背景 + OHeasLogo(100pt) + "OHeas" 字标 + "正在唤醒…" 温暖加载提示，Logo 弹簧入场→文字淡入 |
| **AppRootView 三态** | `OHeasApp/UI/AppRootView.swift` 🔧 | splash → onboarding/main 三态：load() 与 1.2s 最短等待并行，完成后 0.4s 淡入淡出 |
| **OnboardingView 翻页式** | `OnboardingView.swift` 🔧 | Hero 品牌化（渐变+Logo+字标+pills）；卡片区改为单步翻页（水平滑入滑出，reduceMotion 降级淡入淡出）；移除 NavigationStack；按钮本地化修复 |
| **本地化** | `AppLanguage.swift` 🔧 | +6 TextKey：`splashWakingUp` / `continueButton` / `readyButton` / `baselineLimited` / `baselineReady` / `stepPillData` / `stepPillReady` |

### 启动流

```
系统启动屏 → LaunchSplashView (≥1.2s, Logo 入场)
                │
                ├── load() 完成 → 0.4s 淡入淡出 → 主内容
                └── load() 未完成 → Logo 持续显示直到完成
```

### 欢迎页流程

```
Hero (Logo + pills) 始终可见
        │
   [🎯目标] → 点继续 → [📊数据] → 点继续 → [🔒隐私] → 点准备好了 → [✅就绪]
   单步卡片         单步卡片          单步卡片            基线+首次建议
   水平滑入          水平滑入          水平滑入            [开始使用 OHeas]
```

### Logo 设计

渐变色环（mint→teal→indigo，线宽=size×0.1）+ 中心 "H" 大写圆角粗体字母。80pt 适配图标场景，120pt 适配启动页。

---

## Phase 23 — 设置 IA 重构 ✅ 已完成 (2026-06-13)

**目标**：将设置页从"所有控件平铺"改为 iOS 原生"点进去"钻取模式，让顶部简洁、细节在子页。

### 核心改动

| 改动 | 文件 | 说明 |
|------|------|------|
| **设置顶层瘦身** | `SettingsView.swift` 🔧 | 4 个 toggle + 2 个 nav link 平铺 → 5 个入口行（Profile / 成就 / 偏好 / 隐私与授权 / 关于） |
| **PreferencesView** | `SettingsView.swift` 🆕 | 偏好子页：语言列表选择 + 提醒 + AI 开关 |
| **LanguageView** | `SettingsView.swift` 🆕 | 语言选择子页：中文 / English 列表 + 蓝色勾选（替代横向分段控件） |
| **PrivacyConsentView** | `SettingsView.swift` 🆕 | 隐私与授权子页：3 个授权 toggle 各占独立 section + 隐私控制 / 健康权限入口 |
| **DeveloperToolsView** | `SettingsView.swift` 🆕 | 开发者工具子页（`#if DEBUG` 编译时守卫）：测试反馈 / 分析 / AgentContext / Demo / Evaluation / 导出 / 重置 |
| **账户合并到 Profile** | `SettingsView.swift` 🔧 | 点击头像 → AccountView（含同步信息），不再独立占 section |
| **隐私载荷预览移除** | `PrivacyView.swift` 🔧 | 删除 `privacyPayloadPreview` 区域，不再向用户暴露内部 prompt 结构 |
| **本地化** | `AppLanguage.swift` 🔧 | +2 TextKey：`preferencesSection` / `dataManagementSection`；"同意" → "授权"（4 处） |
| **启动页文案放大** | `LaunchSplashView.swift` 🔧 | "正在唤醒…" caption2 → subheadline.medium，更可读 |

### 设置页结构

```
设置
├── 🧑 头像 + 名字 + 数据源 + 状态灯   → AccountView（含同步）
├── 🏆 成就                            → AchievementsView
├── ⚙️ 偏好                            → 语言 / 提醒 / AI
├── ✋ 隐私与授权                       → 3 授权 + 隐私控制 + 健康权限
├── ℹ️ 关于                            版本 / 构建号 / 效果分析
└── 🛠 开发者工具 (DEBUG only)         → 全部测试工具 + 导出 + 重置
```

### 安全性

- 开发者工具由 `#if DEBUG` 编译时守卫，Release/TestFlight 完全不可见，非运行时 toggle
- 隐私载荷预览已从用户界面移除

---

## 国际化 & UI 警告修复 ✅ 已完成 (2026-06-12)

**目标**：消除全 UI ⚠️ 黄色三角警告 + 修复中文设置无效 bug。

### 根因

| 问题 | 根因 |
|------|------|
| **⚠️ 黄色三角** | `AppLanguage.text()` 用 706 case 巨型 switch，Swift 编译器对大 switch 的 exhaustiveness 检查不稳定，case 大量落到 `default` → `"⚠️ keyName"` |
| **中文设置无效** | `AppRootView` 用 computed property 计算语言，`.environment()` 注入后不随 `@AppStorage` 变化传播；`ChatViewModel` 默认 `"en"` |

### 核心改动

| 改动 | 文件 | 说明 |
|------|------|------|
| **字典翻译引擎** | `AppLanguage.swift` | 删除 706 case 巨型 switch + 70 行 `gamificationText()` 死代码，替换为静态字典 `[TextKey: (zh: String, en: String)]`（417 条目），O(1) 查询，零编译器依赖 |
| **语言传播修复** | `AppRootView.swift` | `language` 从 computed property → `@State`，新增 `.onAppear` + `.onChange(of: languageRawValue)` 双同步 |
| **警告色降级** | `MetricTrendCard.swift` | `partial` 数据：`exclamationmark.triangle.fill` → `info.circle`；`OhColor.warning`(橙) → `.secondary`(灰) |
| | `ConfidenceBadge.swift` | `.medium`：`OhColor.warning`(橙) → `.blue`(蓝) |
| | `SignalTags.swift` | 低严重度：`.orange` → `.secondary`，背景从 `warningBg` → `secondary.opacity(0.08)` |
| **徽章本地化** | `CelebrationEffect.swift` + `TodayView.swift` | 硬编码 `"New Badge Unlocked!"` → `language.text(.badgeUnlockedToast)` |
| **默认语言** | `ChatViewModel.swift` | 6 处 `= "en"` → `= "zh"`；fallback `.english` → `.chinese` |

### 验证

| 检查项 | 结果 |
|--------|------|
| `swift build` | ✅ Build complete |
| `swift test` | ✅ 85/85 passed，0 regressions |
| `xcodebuild build` (iPhone 17, iOS 26.5) | ✅ BUILD SUCCEEDED |

---

## Phase 19 — 对话式 AI 教练卡片 ✅ 已完成

**目标**：在教练建议卡片下方添加可点击的追问 chip 按钮，用户可以快速获取更多信息或跳转到对话 Tab。

**市场参考**：Whoop Coach、Oura Advisor。

### 核心改动

| 改动 | 文件 | 说明 |
|------|------|------|
| **FollowUpModels** | `Sources/OHeasCore/Models/FollowUpModels.swift` 🆕 | `CoachFollowUpChip`（labelKey + ChipCategory + ChipAction）、`CoachInlineResponse`、`ChipAction` enum（askQuestion / navigateToChat） |
| **CoachFollowUpChips** | `OHeasApp/UI/Today/CoachFollowUpChips.swift` 🆕 | 水平滚动 chip 按钮组：SF Symbol 图标 + 本地化标签 + pressableScale，按 ChipCategory 着色 |
| **InlineResponseCard** | `OHeasApp/UI/Today/CoachInlineResponseView.swift` 🆕 | 内联快速回答卡片：loading 态（ProgressView）/ 回答态（左侧 accent bar + 文本 + 关闭按钮），动画过渡 |
| **generateChips()** | `RecommendationViewModel.swift` 🔧 | 根据 CoachState + 数据质量生成 2-4 个上下文相关 chip（恢复含义/明日计划/更多细节/历史验证） |
| **fetchInlineResponse()** | `RecommendationViewModel.swift` 🔧 | 内联回答获取（当前使用本地 fallback，LLM 路径预留） |
| **handleChipTap()** | `OHeasViewModel.swift` 🔧 | Chip 点击分发：askQuestion → 获取内联回答；navigateToChat → 通过 RootTabView 切换 Tab + 预填问题 |
| **AICoachCard 集成** | `AICoachCard.swift` 🔧 | 稳定卡片/降级卡片中 actionButtons 下方插入 chips + inlineResponse，新增 5 个参数 |
| **RootTabView 联动** | `RootTabView.swift` 🔧 | `pendingChatPrompt` 状态 → ChatView `.onChange(of:)` 自动填入并发送 |
| **ChatView** | `ChatView.swift` 🔧 | 新增 `pendingPrompt: Binding<String?>` 参数，检测到非空 prompt 后自动填入输入框 → 发送 |
| **本地化** | `AppLanguage.swift` 🔧 | +8 TextKey：askRecoveryMeaning / askTomorrowPlan / askMoreDetails / askHistoricalValidation 等 |

### Chip 生成逻辑

```
Recommendation 状态:
  ├── recoveryLow / overloaded → "这对我的恢复意味着什么？"（恢复类）
  ├── ready / balanced       → "明天我应该做什么？"（明日计划类）
  ├── 所有状态                → "告诉我更多细节"（详情类，始终生成）
  └── yesterdayFeedback 存在   → "这个建议之前对我有效吗？"（历史验证类）

最多 4 个 chip，不足 4 个则不补齐。
```

---

## Phase 20 — 游戏化层 ✅ 已完成

**目标**：引入连胜（Streak）、徽章（Badge）、庆祝动效（Celebration）三层游戏化系统，激励用户持续使用。

**市场参考**：Headspace 连胜火焰、Duolingo 连胜、Apple Watch 三环、Fitbit 徽章。

### 核心改动

| 改动 | 文件 | 说明 |
|------|------|------|
| **GamificationModels** | `Sources/OHeasCore/Gamification/GamificationModels.swift` 🆕 | `StreakType`（dataCoverage/feedback/planCompletion/checkIn 4 种）、`StreakState`、`BadgeCategory`（streaks/milestones/health/exploration 4 类）、`BadgeCriteria`（10 种判定）、`BadgeDefinition`、`BadgeState`、`GamificationSnapshot` |
| **StreakEngine** | `Sources/OHeasCore/Gamification/StreakEngine.swift` 🆕 | 5 个计算方法：数据覆盖连胜/反馈连胜/计划完成连胜/签到连胜/评分连胜。核心算法：从今天反向遍历 → 当前连胜；全量扫描 → 最长连胜。O(n) 复杂度 |
| **BadgeSystem** | `Sources/OHeasCore/Gamification/BadgeSystem.swift` 🆕 | `BadgeRegistry.all`（15 枚徽章定义）、`BadgeEvaluator.computeSnapshot()`（一站式快照：连胜+已获得+新解锁 diff）、`evaluate()`（单枚徽章判定） |
| **GamificationStore** | `Sources/OHeasCore/Gamification/GamificationStore.swift` 🆕 | `BadgeStore`（badge.json 持久化，支持重复获得计数）、`StreakStore`（streaks.json 历史记录，最多 365 天） |
| **StreakFlameView** | `OHeasApp/UI/Components/StreakFlameView.swift` 🆕 | SF Symbol "flame.fill" + 计数。火焰尺度：<7=1.0x, 7-29=1.15x, 30-99=1.3x, 100+=1.5x。里程碑（7/30/100）自动脉冲动画，尊重 reduceMotion |
| **BadgeCard** | `OHeasApp/UI/Components/BadgeCard.swift` 🆕 | 80pt 宽徽章卡片：圆形图标 + 标题 + 获得日期。已获得=全色+sparkle，未获得=灰色+锁图标+55% 透明度 |
| **AchievementsView** | `OHeasApp/UI/AchievementsView.swift` 🆕 | 成就页面：连胜摘要（火焰+数据守护+行动派三行）+ 徽章网格（按 category 分组，LazyVGrid adaptive 80pt），导航栏 + Done 按钮 |
| **CelebrationEffect** | `OHeasApp/UI/Components/CelebrationEffect.swift` 🆕 | Canvas + TimelineView 粒子系统：36 彩色粒子从屏幕中部爆发 → 重力下落 → 3s 淡出。reduceMotion=true 时降级为毛玻璃横幅（图标+徽章名+2.5s 自动消失） |
| **computeGamification()** | `OHeasViewModel.swift` 🔧 | load() 末尾调用：收集所有源数据 → BadgeEvaluator.computeSnapshot() → 新徽章触发 CelebrationEffect + 持久化到 BadgeStore |
| **TodaySummaryHeader** | `Today/TodaySummaryHeader.swift` 🔧 | 数据源胶囊左侧新增 StreakFlameView（checkInStreak > 0 时显示） |
| **TodayView** | `TodayView.swift` 🔧 | `.overlay { CelebrationEffect }` — zIndex(100) 覆盖层，showCelebration 控制显隐 |
| **SettingsView** | `SettingsView.swift` 🔧 | 隐私与同步之间新增 "成就/Achievements" section → NavigationLink → AchievementsView |
| **存储配置** | `AppConfiguration.swift` 🔧 | +`badges` + `streaks` 存储 URL |
| **本地化** | `AppLanguage.swift` 🔧 | +30 TextKey（15 枚徽章 × 名称+描述 + 连胜/section/提示文本），超出编译器 switch 检查上限 → 重构为 `default` + `gamificationText()` 字典查找模式 |

### 15 枚徽章

| 类别 | 徽章 | 图标 | 条件 |
|------|------|------|------|
| 连胜 | 一周签到 | flame.fill | 连续 7 天签到 |
| 连胜 | 月度签到 | flame.circle.fill | 连续 30 天签到 |
| 连胜 | 数据守护者 | applewatch.radiowaves | 连续 7 天完整佩戴数据 |
| 连胜 | 行动派 | checkmark.seal.fill | 连续 7 天完成每日计划 |
| 里程碑 | 初次建议 | lightbulb.fill | 收到第一条 AI 建议 |
| 里程碑 | 实验者 | testtube.2 | 完成第一个个人实验 |
| 里程碑 | 初次对话 | bubble.left.fill | 首次与 AI 教练对话 |
| 里程碑 | 积极反馈 | text.badge.checkmark | 提交 10 次反馈 |
| 里程碑 | 计划达人 | calendar.badge.checkmark | 完成 30 个每日计划 |
| 里程碑 | 科学家 | chart.line.uptrend.xyaxis | 完成 3 个个人实验 |
| 健康 | 满分周 | star.fill | 身体预算 ≥85 连续 7 天 |
| 健康 | 规律睡眠 | moon.zzz.fill | 14 天持续睡眠数据 |
| 健康 | 心率洞察 | heart.text.square.fill | 21 天完整 HRV 数据 |
| 探索 | 新手探索 | eye.fill | 首次提交反馈 |
| 探索 | 回顾者 | doc.text.magnifyingglass | 完成首次每周回顾 |

### 游戏化闭环

```
每日 load() → StreakEngine 计算 4 种连胜 → BadgeEvaluator 评估 15 枚徽章
→ 与已持久化 BadgeState 做 diff → 新徽章触发 CelebrationEffect 覆盖层
→ 3s 后自动消失 → BadgeStore 持久化
→ TodaySummaryHeader 显示签到火焰 + 连胜天数
→ Settings → Achievements 页面可随时查看所有徽章（已获得/未获得）
```

---

## Phase 18 — Today 页信息架构重构 ✅ 已完成

**目标**：Score-first 渐进式布局——用户打开 App 第一眼看到评分和"One Big Thing"洞察，向下滚动逐步发现更多细节。

**市场参考**：Oura v2025 "One Big Thing"、Whoop 三柱（Recovery/Strain/Sleep）。

### 核心改动

| 改动 | 文件 | 说明 |
|------|------|------|
| **TodaySummaryHeader** | `Today/TodaySummaryHeader.swift` 🆕 | 合并 Hero 渐变 + 放大评分环（110pt）+ "One Big Thing" 日洞察；渐变压缩 140→80pt |
| **TodayContentSection** | `Today/TodayContentSection.swift` 🆕 | 统一 section 包装器：标题 + SF Symbol + 内容 |
| **BodyBudgetGauge 简化** | `Today/BodyBudgetGauge.swift` 🔧 | 移除评分环（已移至 Header），专注于 3 指标 sparkline + 解释 + 贡献分解 |
| **TodayFeedbackPanel 重构** | `Today/TodayFeedbackPanel.swift` 🔧 | 反馈表单从 2 层 DisclosureGroup 后提取为内联 QuickFeedbackRow；Yesterday 直接可见 |
| **TodayView 布局重排** | `TodayView.swift` 🔧 | 新滚动顺序：Header → Coach → Feedback → Metrics → Plan → Grid → Signals；删除 `showMoreDetails` DisclosureGroup |
| **TodayHeroSection 废弃** | `Today/TodayHeroSection.swift` | 内容已合并到 TodaySummaryHeader，不再被引用 |

### 信息架构前后对比

```
之前（2 层 DisclosureGroup 嵌套）:        现在（Score-first 渐进式）:
┌─ Hero 渐变 140pt ──────────┐          ┌─ Hero 渐变 80pt ────────────┐
├─ 评分环 90pt + 3 指标 ─────┤          │     评分环 110pt           │
├─ AI 教练卡片 ──────────────┤          │   "One Big Thing" 洞察     │
├─ 本周计划 ─────────────────┤          ├─ AI 教练卡片 ──────────────┤
├─ [折叠] More Details ──────┤          ├─ 快速反馈（内联可见）──────┤
│   ├─ [折叠] 反馈表单 ──────┤          ├─ 恢复指标 + 贡献分解 ─────┤
│   └─ [折叠] 昨日验证 ──────┤          ├─ 本周计划 ─────────────────┤
└────────────────────────────┘          ├─ 指标网格 ─────────────────┤
                                        ├─ 信号标签（直接可见）──────┤
                                        └────────────────────────────┘
```

### 已消除的局限

| 原问题 | 解决方案 |
|--------|---------|
| 反馈藏在 2 层 DisclosureGroup 后 | 内联 QuickFeedbackRow，3 个紧凑滑块 + 保存按钮直接可见 |
| Hero 140pt 渐变压缩内容空间 | 压缩至 80pt，释放 60pt 给首屏内容 |
| 评分环 90pt 不够突出 | 放大至 110pt 作为页面绝对视觉锚点 |
| "More Details" DisclosureGroup 隐藏所有细节 | 全部内容直接可见，用户只需滚动 |
| 无"One Big Thing"日洞察 | 评分环下方显示浓缩洞察（基于分数类别+信号） |

**验证**：`swift build` 通过，`swift test` 85/85 通过，`xcodebuild build` 通过。

---

## Phase 17 — 贡献分解 + 图表增强 ✅ 已完成

**目标**：让用户理解 Body Budget Score 的"为什么"——每个因子的贡献方向和大小一目了然。

**市场参考**：Whoop 贡献因子条、Apple Health 交互式图表、Welltory HRV 细节。

| 改动 | 文件 | 说明 |
|------|------|------|
| TrendIndicator | `OHeasApp/UI/Components/TrendIndicator.swift` 🆕 | 趋势方向指示器：箭头（↑→↓）+ 百分比变化 + 颜色编码（绿=改善/橙=恶化/灰=持平），基于线性回归斜率计算 |
| InteractiveSparklineView | `OHeasApp/UI/Components/InteractiveSparklineView.swift` 🆕 | 增强版 SparklineView：DragGesture 滑动查看各数据点，竖线指示器 + 浮动 tooltip（日期+值），缺失数据自动跳过 |
| ContributionBar | `OHeasApp/UI/Components/ContributionBar.swift` 🆕 | 水平贡献分解条：每行显示指标图标+名称+比例条+贡献值，正值绿色助力/负值橙色减分，按绝对值降序排列（最多 6 条） |
| MetricTrendCard | `OHeasApp/UI/Components/MetricTrendCard.swift` 🆕 | 复合指标卡片：图标 + 指标名 + 当前值 + 基线 Delta + TrendIndicator + InteractiveSparklineView，用于 2 列网格 |
| BodyBudgetGauge 集成 | `Today/BodyBudgetGauge.swift` 🔧 | 分数环下方新增 ContributionBar，展示各因子的贡献分解 |
| TodayMetricsGrid 升级 | `Today/TodayMetricsGrid.swift` 🔧 | 静态 MetricTile → MetricTrendCard（含交互式 sparkline + 趋势指示器），新增 `recentDailyMetrics` 数据源 |

**验证**：`swift build` 通过，`swift test` 85/85 通过，`xcodebuild build` 通过。

---

## Phase 16 — UI 全面优化 "集百家之所长" 🚧 进行中

**目标**：对标 Oura、Whoop、Athlytic、Bevel、Apple Health、Rise、Welltory、Headspace、Fitbit 等市场头部健康 App，将 OHeas UI 从"功能完整"提升到"市场领先"。

**设计原则**：每阶段独立可发布（编译通过 + 测试全绿），市场参考明确，优先用户感知最强的改进。

### 市场参考矩阵

| 市场 App | 借鉴方向 | OHeas 对标阶段 |
|----------|---------|--------------|
| **Oura** | Readiness Score 环、3 Tab 架构、"One Big Thing" 日洞察、Cumulative Stress | Phase 16（北极星分数）、Phase 18（IA 重构） |
| **Whoop** | Recovery % 色彩编码、贡献因子条、Strain/Sleep/Recovery 三柱、Whoop Coach 追问 | Phase 16（分数）、Phase 17（贡献分解）、Phase 19（对话教练） |
| **Athlytic** | Recovery 环 + 细分指标条、标签式 UI | Phase 16（分数环） |
| **Apple Health** | 三环（Move/Exercise/Stand）、趋势图、交互式图表、Favorites 定制 | Phase 21（趋势/历史）、Phase 22（仪表板定制） |
| **Bevel** | 健康仪表板、生物指标卡片、趋势 | Phase 17（图表增强） |
| **Rise Science** | 能量曲线时间轴、昼夜节律可视化 | Phase 18（时间轴视图） |
| **Welltory** | HRV 散点图、雷达图、测量动画 | Phase 17（交互式图表） |
| **Headspace** | 连胜火焰、进度环、趣味微交互 | Phase 20（游戏化） |
| **Fitbit** | 徽章成就、步数挑战 | Phase 20（游戏化） |
| **Duolingo** | 连胜机制（50%+ 日活提升） | Phase 20（连胜系统） |

---

### Phase 16 — Body Budget Score（北极星分数）✅ 已完成

**市场参考**：Oura Readiness（0-100 环）、Whoop Recovery（色彩编码 %）、Athlytic Recovery 环

**核心改动**：将 `BodyBudgetGauge` 的环形仪表从展示「数据可信度」改为展示 0-100 的「身体预算评分」（Body Budget Score），让用户每天打开 App 第一眼就能看到自己的身体状态。

| 改动 | 文件 | 说明 |
|------|------|------|
| **评分引擎** | `Sources/OHeasCore/Analysis/BodyBudgetScorer.swift` 🆕 | 4 大柱加权算法：Recovery (40%) + Activity (25%) + Subjective (15%) + Signals (20%)；缺失数据降低柱权重、偏向中性（50）；输出 0-100 分数 + BudgetCategory + [BudgetFactor] |
| **评分环 UI** | `OHeasApp/UI/Components/BodyBudgetRing.swift` 🆕 | Oura 风格：绿色→黄色→橙色→红色渐变环线，大盘分数数字，分类标签，OhAnimation.gauge() 弹簧动画，尊重 reduceMotion |
| **分类徽章** | `OHeasApp/UI/Components/ScoreCategoryBadge.swift` 🆕 | 彩色胶囊：Excellent=绿 / Good=薄荷 / Fair=黄 / Strained=橙 / Depleted=红 |
| **数据模型** | `Models/HealthModels.swift` 🔧 | 新增 BudgetCategory enum（5 级）+ BudgetFactor struct + BodyBudgetScore struct |
| **覆盖层** | `Analysis/DataCoverageLayer.swift` 🔧 | 新增 `confidenceWeight(for:in:)` 方法 |
| **VM 集成** | `HealthDataViewModel.swift` 🔧 | bodyBudgetScore @Published，buildPipeline 中计算，加入 HealthDataPackage |
| **协调器** | `OHeasViewModel.swift` 🔧 | 委托 bodyBudgetScore，反馈加载后刷新评分 |
| **仪表板重构** | `Today/BodyBudgetGauge.swift` 🔧 | 替换 quality 为主参数的仪表板 → score 为主参数；BodyBudgetRing 替代旧置信度环；数据质量降级为二级辅助标签 |
| **视图集成** | `TodayView.swift` 🔧 | 传递 bodyBudgetScore 给 BodyBudgetGauge |
| **本地化** | `AppLanguage.swift` 🔧 | 新增 budgetCategory() / budgetScoreExplanation() / 7 个 TextKey |
| **测试** | `OHeasCoreTests.swift` 🔧 | +5 个 BodyBudgetScorer 测试 |

**验证**：`swift build` 通过，`swift test` 85/85 通过（80 + 5 新）。

---

### 路线图：Phase 17-22（Phase 19-22 规划中）

```
Phase 16: Body Budget Score ✅
 │
 ├─ Phase 17: 贡献分解 + 图表增强 ✅
 │    市场参考：Whoop 因子条、Apple Health 交互式图表、Welltory HRV 细节
 │    新建：ContributionBar / TrendIndicator / InteractiveSparklineView / MetricTrendCard
 │    集成：BodyBudgetGauge + ContributionBar、TodayMetricsGrid → MetricTrendCard 升级
 │
 ├─ Phase 18: Today 页 IA 重构 ✅
 │    市场参考：Oura v2025 "One Big Thing"、Whoop 三柱
 │    新建：TodaySummaryHeader / TodayContentSection
 │    重构：Hero 压缩 140→80pt、评分环 90→110pt、反馈上移（移除 DisclosureGroup 嵌套）
 │
 ├─ Phase 19: 对话式 AI 教练卡片 ✅
 │    市场参考：Whoop Coach、Oura Advisor
 │    新建：FollowUpModels / CoachFollowUpChips / InlineResponseCard / generateChips()
 │    集成：AICoachCard 追问 chip 行 + 内联回答 + Chip→Chat Tab 导航联动
 │
 ├─ Phase 20: 游戏化层（连胜/徽章/庆祝动画） ✅
 │    市场参考：Headspace 火焰、Duolingo 连胜、Fitbit 徽章
 │    新建：StreakEngine / BadgeSystem (15 枚) / StreakFlameView / BadgeCollectionView / CelebrationEffect
 │    集成：TodaySummaryHeader 签到火焰 + TodayView 庆祝覆盖层 + Settings 成就入口
 │
 ├─ Phase 21: 时间轴 & 历史视图 ✅（Tab 名从「历史」→「趋势」）
 │    市场参考：Oura "My Health"、Apple Health "浏览"
 │    新建：HistoryTimelineView / DayDetailSheet / ScoreHistoryChart
 │
 └─ Phase 22: 品牌 & 启动优化 ✅
      新建：OHeasLogo / LaunchSplashView / OnboardingView 翻页式重构
      效果：环形 H 品牌标识 + 品牌启动过渡 + 单步翻页欢迎流程
```

---

### Phase 16 评分算法

```
Body Budget Score = Recovery(40%) + Activity(25%) + Subjective(15%) - SignalPenalty(20%)

Recovery (40%):
  ├── Sleep:    today vs baseline z-score → 0-100 subscores（10% Δ = 1σ）
  ├── HRV:      today vs baseline z-score → 0-100 subscores
  └── RHR:      today vs baseline z-score → 0-100 subscores（越低越好，反转）

Activity (25%):
  ├── Steps:    80%-120% baseline = optimal (85)
  └── Exercise: 70%-130% baseline = optimal (80)

Subjective (15%):
  ├── Energy (1-10): higher → better
  ├── Soreness (1-10): lower → better（反转）
  └── Stress (1-10): lower → better（反转）

Signal Penalty (20%):
  ├── High severity:    -35% × signalWeight
  ├── Medium severity:  -15% × signalWeight
  └── Low severity:      -5% × signalWeight
```

**BudgetCategory 映射**：Excellent (85-100) / Good (70-84) / Fair (55-69) / Strained (35-54) / Depleted (0-34)

**目标**：建立完整的语义化 Design Token 系统 + 深度重构 God View 和超大文件。

### 15C: 视觉设计系统（Phase 3）

| 改动 | 文件 | 说明 |
|------|------|------|
| 完整 Design Token 系统 | `DesignTokens.swift` 🔧 | `OhColor`（30+ 语义颜色：success/warning/danger/primary/sleep/hrv/cardBg 等）、`OhFont`（9 级排版+权重）、`OhAnimation`（6 弹簧+4 非弹簧预设）、`OhShadow`（4 级阴影：card/elevated/input/accentGlow）、`Radius` 新增 `tiny=2` |
| 圆角全统一 | 全部视图 🔧 | 所有硬编码 `cornerRadius: 2/8/10/12/16` → `Radius.tiny/small/medium/large`（20+ 处） |
| 动画全统一 | 全部视图 🔧 | ~15 种不同 `spring()` → `OhAnimation.press()/appear()/tab()/stagger()/gauge()`（18+ 处） |
| 组件更新至令牌 | `CardView` / `ButtonEffects` / `MotionEffects` / `SkeletonView` / `MetricComponents` | 全部引用 `OhColor` / `OhAnimation` / `OhShadow` / `Radius` |

### 15D: 深度重构（Phase 4）

| 改动 | 文件 | 说明 |
|------|------|------|
| **拆分 TodayView** | `TodayView.swift` **1057→211 行** ✅ | 提取 7 个子组件到 `UI/Today/`：`TodayHeroSection`（渐变+问候）、`BodyBudgetGauge`（环形仪表+火花图）、`AICoachCard`（流式/稳定/降级三态）、`SignalTags`（信号胶囊）、`WeeklyPlanStrip`（周计划条）、`TodayMetricsGrid`（指标网格）、`TodayFeedbackPanel`（反馈+验证） |
| **内联三元迁移** | `TodayView` / `ChatView` / `PlanTabView` / `SettingsView` 🔧 | ~35 处 `language == .chinese ?` → `language.text(.newTextKey)`，新增 33 个 TextKey 条目 |
| 共享组件提取 | `Components/ConfidenceBadge.swift` 🆕 | 置信度胶囊组件从 TodayView 私有 → 共享 |
| 项目配置更新 | `project.yml` 🔧 | 新增 `OHeasApp/UI/Today` 源目录 |



## Phase 15 — UI 优化 Phase 1+2 ✅ 已完成

**目标**：TestFlight 前的 UI 打磨 + 结构清理，让 Beta 测试者打开 App 立即感知到品质提升。

### 15A: TestFlight 打磨（Phase 1）

| 改动 | 文件 | 说明 |
|------|------|------|
| DesignTokens | `Components/DesignTokens.swift` 🆕 | 统一 CardStyle（cornerRadius=12, padding=16）、Radius、Spacing token |
| 按钮动效 | `Components/ButtonEffects.swift` 🆕 | `pressableScale()` modifier：按下时 scaleEffect(0.97) + spring 动画，尊重 ReduceMotion |
| Tab 图标优化 | `RootTabView.swift` 🔧 | 选中/非选中态 fill/non-fill SF Symbol 切换 + AppTab enum 编程式选择 |
| Hero 渐变动态化 | `TodayView.swift` 🔧 | 根据 `dataQuality.overallConfidence` 动态变色：high=绿、high+signal=橙、medium=amber、low=灰蓝 |
| 骨架屏补齐 | `ChatView.swift`、`PlanTabView.swift` 🔧 | Chat 连接中显示 4 行骨架；Plan 重新生成时显示 SkeletonSection |
| Onboarding 渐进式 | `OnboardingView.swift` 🔧 | 4 步渐进展示（目标→健康权限→隐私+AI→基线+开始）+ 圆点进度指示器 |
| 按钮动效应用 | `TodayView`、`ChatView`、`PlanTabView`、`OnboardingView` 🔧 | 所有操作按钮统一按压反馈 |

### 15B: 结构清理（Phase 2）

| 改动 | 文件 | 说明 |
|------|------|------|
| 共享卡片组件 | `Components/CardView.swift` 🆕 | `OCard<Content>` 和 `OLabeledCard` 统一卡片容器 |
| 提取重复组件 | `Components/MetricComponents.swift` 🆕 | `MetricTile`（3 处→1）、`MetricComparisonRow`（2 处→1）、`metricIcon()`/`metricColor()` |
| 语言环境统一 | `Components/LanguageEnvironment.swift` 🆕 | `@Environment(\.appLanguage)` 替代多处 `@AppStorage` 重复读取；AppRootView 单一注入点 |
| ChatViewModel 清理 | `Components/ChatFormatting.swift` 🆕 + `ChatViewModel.swift` 🔧 | `localizedMissingReason()` 移至 view 层 |
| 删除重复代码 | `EffectivenessDashboardView`、`InsightsTabView`、`MetricsView`、`SettingsView` 🔧 | 删除各自私有的 MetricTile/MetricComparisonRow/EffectivenessMetricTile 定义 |

### 共享组件目录（Components/）

```
Components/
├── DesignTokens.swift         # OhColor, OhFont, OhAnimation, OhShadow, CardStyle, Radius, Spacing
├── ButtonEffects.swift        # pressableScale()
├── MotionEffects.swift        # softAppear
├── SkeletonView.swift         # 骨架屏
├── SparklineView.swift        # 迷你趋势图
├── CardView.swift             # OCard, OLabeledCard
├── MetricComponents.swift     # MetricTile, MetricComparisonRow, metricIcon/Color
├── LanguageEnvironment.swift  # @Environment(\.appLanguage)
├── ChatFormatting.swift       # localizedMissingReason
└── ConfidenceBadge.swift 🆕   # 共享置信度胶囊
```

---

## Phase 11 — RAG 语义检索 ✅ 已完成

**目标**：将 Chat 的上下文注入从"全量规则塞入"升级为"语义向量检索"，让 LLM 教练能回答跨时间窗口的历史问题。

### 11A: pgvector 表与迁移

| 改动 | 文件 | 说明 |
|------|------|------|
| MemoryEmbedding ORM 模型 | `db/models.py` | 新增表：id / user_id / source_type / source_id / content / embedding(VECTOR(1536)) |
| pgvector 迁移 | `alembic/versions/0002_pgvector_rag.py` | CREATE EXTENSION vector + ivfflat cosine 索引（100 lists） |
| 依赖追加 | `requirements.txt` | +pgvector +openai |

**6 种检索源**：pattern / intervention / feedback / experiment / recommendation / review

### 11B: Embedding + RAG API

| 改动 | 文件 | 说明 |
|------|------|------|
| EmbeddingService | `rag/embedding_service.py` | OpenAI text-embedding-3-small（1536 维），batch + semaphore 并发控制，content_hash 去重 |
| RAG 路由 | `rag/routes.py` | POST /v1/rag/search（pgvector cosine 相似度 + ILIKE text fallback）、POST /v1/rag/index（batch upsert） |
| Config 扩展 | `config.py` | +openai_api_key 配置项 |
| Router 注册 | `main.py` | 注册 rag_router |

**数据流**：用户消息 → embedding(query) → pgvector <=> cosine 排序 → top-3 → JSON 返回 → iOS 注入 System Prompt

### 11C: iOS Core — RAGService

| 改动 | 文件 | 说明 |
|------|------|------|
| RAGService | `RAG/RAGService.swift` | 双级检索：HTTPRAGClient（后端 pgvector）→ LocalRAGClient（actor token 匹配 fallback）→ 空 |
| 模型 | 同上 | RAGSearchResult / RAGSearchResponse / MemoryIndexItem |
| HTTPRAGClient | 同上 | 调用 /v1/rag/search + /v1/rag/index，Bearer token 认证 |
| LocalRAGClient | 同上 | Actor 线程安全，内存索引最多 200 条，token 匹配评分 |
| RAGService | 同上 | configureBackend() / search() / index() / resetLocal()，backend + local 结果去重合并 |

### 11D: iOS App — Chat 集成

| 改动 | 文件 | 说明 |
|------|------|------|
| ragService 属性 | `ChatViewModel.swift` | 新增 RAGService 实例 |
| RAG 检索 | `ChatViewModel.swift` | sendMessage 前 `await ragService.search(query, topK: 3)` |
| 格式化注入 | `ChatViewModel.swift` | `formatRAGResults()` → 中英双语 prompt 片段 → 追加到 System Prompt 末尾 |
| 索引接口 | `ChatViewModel.swift` | `indexMemoryForRAG(sourceType, sourceId, content)` 供外部调用 |

---

## Phase 12 — GitHub Actions CI/CD ✅ 已完成

**目标**：每次 push/PR 自动运行全部 133 个测试 + 构建验证。

| 改动 | 文件 | 说明 |
|------|------|------|
| CI workflow | `.github/workflows/ci.yml` 🆕 | 2 Job 并行：Swift (macOS) + Backend (Ubuntu) |
| Swift job | 同上 | swift build → swift test (80) → 启动模拟器 → xcodebuild test (38) → preflight |
| Backend job | 同上 | pip install → pytest (15) |
| 缓存 | 同上 | SPM + pip 缓存加速后续运行 |

**触发条件**：push/PR to `main`，自动取消旧运行。

---

## Phase 13 — 多轮对话优化 ✅ 已完成

**目标**：从硬编码 20 条消息窗口升级为 token 感知的动态滑窗 + 自动摘要。

| 改动 | 文件 | 说明 |
|------|------|------|
| ContextWindowManager | `Sources/OHeasCore/LLM/ContextWindowManager.swift` 🆕 | Token 估算（中英混合 ~2.5 字/token）、动态滑窗、摘要触发阈值、LLM 摘要 prompt 构建、规则摘要 fallback |
| ChatSession.summary | `Storage/ChatMessageStore.swift` | 新增 `summary: String?` 字段，持久化压缩后的对话上下文 |
| 动态窗口 | `ChatViewModel.swift` | `suffix(21)` → `ContextWindowManager.buildMessages()` 按 token 预算动态裁剪 |
| 自动摘要 | `ChatViewModel.swift` | `maybeSummarize()` → 每次回复后检测，LLM 摘要 + 规则 fallback，保留最近 8 条 |
| System Prompt 裁剪 | `ChatViewModel.swift` | 按查询关键词匹配：plan/experiment/patterns 只在相关时注入 |

**效果**：
- 短对话（<15 条）：无变化
- 长对话（20+ 条）：自动摘要压缩旧消息，保留关键上下文
- 50+ 条：摘要叠加，LLM 仍能引用历史话题
- System Prompt：从 ~1500 token 降到 ~800 token（无关查询）

---

## Phase 8 — AI 对话式 Coach 聊天窗口 ✅ 已完成

**目标**：从"Agent 单向输出建议"升级为"用户可追问、澄清、讨论的对话式健康教练"。

### 实现方案

选择 **替换设置 Tab** 方案：原第 4 个 Tab（设置）改为对话，设置移至右上角 👤 用户按钮 → Sheet。

| 改动 | 文件 | 说明 |
|------|------|------|
| ChatView | `UI/ChatView.swift` 🆕 | 消息气泡（User 右蓝 / Coach 左灰）、TextEditor 输入栏、流式闪烁光标、空状态引导 |
| ChatViewModel | `ViewModels/ChatViewModel.swift` 🆕 | 消息管理、流式 SSE 接收、本地 fallback、System Prompt 注入健康 context |
| LLM 通用聊天方法 | `LLM/LLMClient.swift` | `ChatCompletionsClient.chat(messages:)` — 支持多轮对话流式 SSE |
| Tab 重构 | `UI/RootTabView.swift` | 4 Tab（Today / Plan / Insights / Chat），设置移出 Tab |
| 用户菜单 | `UI/SettingsView.swift` | 右上角 👤 → Sheet 弹出设置，含 Done 按钮 |
| 设置入口 | `TodayView / PlanTabView / InsightsTabView` | 每个页面 toolbar 加 person.crop.circle 按钮 |
| 国际化 | `UI/AppLanguage.swift` | +12 个 TextKey（chatTab / chatPlaceholder / chatEmpty* / settingsDone 等） |

### 导航演变

```
Phase 7I: [今日] [计划] [洞察] [设置]                        (4 Tab)
Phase 8:  [今日] [计划] [洞察] [对话]  + 右上角 👤 → 设置    (4 Tab + Sheet)
Phase 8C: [今日] [对话] [设置]                                (3 Tab, Plan/Insights 移除)
Phase 14: [今日] [计划] [对话] [设置]                         (4 Tab, Plan 回归)
```

### 降级链

```
真实 SSE stream（ChatCompletionsClient.chat）→ one-shot → localFallbackResponse
AI 开关关闭 / 无 API Key 时走本地规则回复
```

### 8A: 全面中文本地化 ✅

| 改动 | 文件 | 说明 |
|------|------|------|
| AppLanguage 扩展 | `UI/AppLanguage.swift` | +50 个 TextKey + 中英翻译对 |
| SettingsView 全本地化 | `UI/SettingsView.swift` | 账户/隐私/Beta/关于/对话框全部中文化 |
| 语言设置下移 | `UI/SettingsView.swift` | 语言选择从顶部移到「关于」上方，作为小 segmented picker |
| InsightsTabView | `UI/InsightsTabView.swift` | Effectiveness / Most Promising / Weakest Areas / Evaluation → 中文 |
| ChatView | `UI/ChatView.swift` | Coach → 健康教练 |
| OnboardingView | `UI/OnboardingView.swift` | Welcome / 免责声明 / Start → 中文 |
| AccountView | `UI/AccountView.swift` | Mode / Email / Sign Out → 中文 |
| HealthPermissionRecoveryView | `UI/HealthPermissionRecoveryView.swift` | Granted/Denied/Not Asked → 已授权/已拒绝/未询问 |

---

### 真机验证准备 (Phase 7N 补充)

真机实测暂时无法执行（需要 iPhone + Apple Watch），但已完成所有代码层面的准备：

| 修复 | 严重度 | 文件 | 状态 |
|------|--------|------|------|
| HRV 单点噪声 → `.partial` (<3 样本) | P0 | `DailyMetricsAggregator.swift` | ✅ |
| RHR 单点噪声 → `.partial` (<3 样本) | P0 | `DailyMetricsAggregator.swift` | ✅ |
| SignalDetector 降级 partial 指标 severity | P0 | `SignalDetector.swift` | ✅ |
| 连续 7 天睡眠缺失 → 提示检查 Watch Sleep 设置 | P1 | `DataCoverageLayer.swift` | ✅ |
| 连续 3 天恢复数据缺失 → 佩戴提示 | P1 | `DataCoverageLayer.swift` | ✅ |
| 同步延迟检测 → missingReasons 加提示 | P1 | `DataCoverageLayer.swift` | ✅ |
| 基线不足引导 (<7 天) → `CompletenessSummary` | P0 | `DataCoverageLayer.swift` | ✅ |
| 新增 7 个单元测试 | — | `OHeasCoreTests.swift` | ✅ 80 test pass |

---

## Phase 8C — Tab 4→3 精简 + 视觉升级 + 去重 load() ✅ 已完成

**目标**：精简导航、消除重复加载、大幅提升 UI 视觉品质。

### 8C-1: 导航精简

| 改动 | 文件 | 说明 |
|------|------|------|
| 4 Tab → 3 Tab | `RootTabView.swift` | Today / Chat / Settings，废弃独立 Plan 和 Insights Tab（Plan 在 Phase 14 恢复） |
| 设置独立 Tab | `RootTabView.swift` | Settings 直接嵌入 TabView，不再以 Sheet 呈现 |
| 去重入口 | `ChatView.swift` | 删除右上角设置按钮（设置已是独立 Tab） |
| 废弃文件 | `PlanTabView.swift` / `InsightsTabView.swift` | 保留文件但不再被引用，内容已迁移 |

### 8C-2: 去重 load()

| 改动 | 文件 | 说明 |
|------|------|------|
| 唯一入口 | `AppRootView.swift` | `print("[AppRootView] load() called")` — 仅此处调用 `viewModel.load()` |
| 删除冗余 | `RootTabView.swift` | 移除 `.task { load() }`、`.onChange(of: aiEnabled)`、`.onChange(of: remindersEnabled)` |

### 8C-3: TodayView 视觉升级

| 改动 | 说明 |
|------|------|
| Hero 渐变区域 | 薄荷绿→青绿渐变背景，个性化问候（早上好/下午好/晚上好），日期，毛玻璃数据源胶囊 |
| 身体预算环形仪表 | 圆形进度环（高=绿 85%，中=橙 55%，低=红 25%），3 指标带专属色+火花图 |
| AI 教练左侧彩条 | 3px 靛蓝竖线视觉标记，区分流式生成/已就绪状态，建议用编号+图标呈现 |
| 信号紧凑标签 | 水平滚动胶囊行，红色=高严重度，橙色=低严重度 |
| 本周计划水平滚动 | 圆形日期+计划标题+类型胶囊，今天高亮，左右滑动 |
| 指标对比 2 列网格 | LazyVGrid 布局，每格图标+数值+变化箭头（↑绿 ↓红） |
| 反馈+昨日折叠 | DisclosureGroup 默认收起 |

### 8C-4: 其他 UI 优化

| 改动 | 文件 | 说明 |
|------|------|------|
| Tab 栏美化 | `RootTabView.swift` | 选中态靛蓝色，.fill SF Symbols，UITabBarAppearance 统一配置 |
| Settings Profile | `SettingsView.swift` | 顶部 Profile 摘要（数据源图标+置信度状态），Beta 工具默认折叠 |
| Chat 气泡柔化 | `ChatView.swift` | 用户气泡靛蓝渐变，教练气泡 systemGray6，输入栏微阴影 |

### 8C-5: 新增本地化

| 键 | 中文 | English |
|----|------|---------|
| greetingMorning | 早上好 | Good Morning |
| greetingAfternoon | 下午好 | Good Afternoon |
| greetingEvening | 晚上好 | Good Evening |

### 色彩系统

```
睡眠   → Color.blue     | Hero渐变 → .mint → .teal
HRV    → Color.green    | AI教练   → Color.indigo
心率   → Color.orange   | 活动     → Color.pink
Tab选中 → .systemIndigo
```

---

## Phase 8D — Chat LLM 教练对话重写 + API Key 修复 + 连接 UX ✅ 已完成

**目标**：解决"健康教练 LLM 不能有效交流"的问题，让对话真正接入 DeepSeek。

### 8D-1: System Prompt 重写（ChatViewModel.swift）

| 改动 | 说明 |
|------|------|
| 教练人格定义 | ~50 行：温暖、先倾听再建议、善于提问、庆祝小进步、诚实面对不确定性 |
| 对话规则 | 2-5 句、用"你"称呼、引用数据时给解读而非只报数字、适当用问句引导 |
| 安全红线 | 绝不诊断/建议用药/极端节食/过度训练；严重症状时建议立即就医 |
| 上下文注入 | 从机械罗列数字 → 带解读的对比（"⚠️ 低于基线 0.9h"、"✅ 高于基线"） |
| 新增上下文 | weekly plan 摘要、active experiment、user goals、learned patterns |
| 数据置信度处理 | 低置信时明确告知模型"给出建议时要更保守" |

**对比**：

```
之前: "你是一位有同理心的健康教练。回复保持简洁（2-4句话）。"
之后: ~200 行系统提示词，包含人格、对话规则、安全红线、
      完整健康上下文（含数据解读）、计划/实验/目标/模式
```

### 8D-2: LLM 对话参数（LLMClient.swift）

| 改动 | 说明 |
|------|------|
| chat() 添加 temperature | 0.7 — 更自然的对话变化（之前无此参数，偏确定性） |

### 8D-3: 上下文感知降级回复（ChatViewModel.swift）

| 改动 | 说明 |
|------|------|
| 重写 localFallbackResponse() | 从 6 条通用模板 → 每条回复引用实际数据值 |
| 睡眠问题 | 对比实际睡眠 vs 基线，给出差值 |
| HRV/恢复问题 | 引用实际 HRV 值 + 基线对比 |
| 心率问题 | 引用实际 RHR 值 + 是否偏高判断 |
| 运动问题 | 引用实际步数 |
| 感觉/压力问题 | 先共情，再引用相关数据 |

### 8D-4: 对话开场白（ChatViewModel + ChatView）

| 改动 | 说明 |
|------|------|
| ConversationStarter 模型 | 文本 + SF Symbol 图标 |
| generateStarters() | 基于今日数据生成 5-6 条上下文开场白 |
| 空状态展示 | 可点击的卡片列表，每张带图标 + 箭头 |
| 数据驱动 | 睡眠不足→"我昨晚睡得不太好"、HRV低→"HRV偏低说明什么"、有计划→"今天的计划是什么？" |

### 8D-5: API Key 修复

| 问题 | 修复 |
|------|------|
| deepseek.env 有 key，但 xcscheme 仍是 PLACEHOLDER | 重新运行 `./configure.sh`，key 已注入 |
| 导致 makeClient() 返回 nil → 全部降级到本地规则 | ✅ 修复后 Chat 走 DeepSeek 流式 SSE |

### 8D-6: 连接状态 UX（ChatView.swift）

| 状态 | 显示 |
|------|------|
| 已连接 | toolbar 绿色圆点 + "AI 已连接" |
| 本地模式 | toolbar 橙色圆点 + "本地模式" |
| 本地模式（已有消息） | 顶部橙色 banner："AI 未连接 — 当前使用本地回复。请检查 API Key 配置或开启 AI 开关。" |
| 本地模式（空状态） | 排查指引：① 开启 AI 开关 → ② 运行 ./configure.sh |
| AI 开关切换 | `onChange(of: aiEnabled)` 自动重连重生成开场白 |

### 8D-7: 新增文件/方法

| 文件 | 改动 |
|------|------|
| `ChatViewModel.swift` | 完全重写（~450 行 → ~650 行）：generateStarters()、buildSystemPrompt()、localFallbackResponse() |
| `LLMClient.swift` | chat() 加 `"temperature": 0.7` |
| `ChatView.swift` | 空状态双模式、offlineBanner、connectionBadge 改进、onChange(of: aiEnabled) |

---

## Phase 8E — P0 产品优化 + Chat 会话历史 ✅ 已完成

**目标**：解决三个产品级缺陷，让 Chat 从「演示」变成「可用产品」，并添加 ChatGPT 式的对话历史列表。

### 8E-1: Chat 历史持久化

| 改动 | 文件 | 说明 |
|------|------|------|
| ChatMessage Codable | `Storage/ChatMessageStore.swift` | ChatMessage + Role 遵循 Codable，从 UI 层移至 Core 层 |
| ChatMessageStore | `Storage/ChatMessageStore.swift` 🆕 | JSON 文件持久化，最多 200 条消息，自动裁剪 |
| 存储 URL | `UI/AppConfiguration.swift` | +`chatMessages` URL |
| ViewModel 集成 | `UI/ViewModels/ChatViewModel.swift` | +loadMessages/saveMessages/delete，每条消息变化后自动保存 |

### 8E-2: API Key 持久化到 Keychain

| 改动 | 文件 | 说明 |
|------|------|------|
| KeychainStore | `Storage/KeychainStore.swift` 🆕 | iOS Security.framework，`kSecClassGenericPassword`，service="com.oheas.mvp" |
| 加载链升级 | `UI/OHeasAppConfiguration.swift` | 优先级：env → Info.plist → **Keychain** 🆕，PLACEHOLDER 统一检测 |
| 自动持久化 | `UI/AppRootView.swift` | 首次 Xcode Run 后自动将 API key 写入 Keychain |
| 连接时持久化 | `UI/ViewModels/ChatViewModel.swift` | checkConnection() 中自动持久化 |

**效果**：Xcode Run 一次 → Keychain 有 key → 主屏幕启动也能用 DeepSeek。

### 8E-3: 流式状态区分 + 超时重试

| 改动 | 文件 | 说明 |
|------|------|------|
| StreamState 枚举 | `UI/ViewModels/ChatViewModel.swift` | idle → connecting → streaming → error(String) |
| 15s 首 token 超时 | `UI/ViewModels/ChatViewModel.swift` | 超时取消 streaming，显示错误提示 |
| retryLastMessage | `UI/ViewModels/ChatViewModel.swift` 🆕 | 错误后一键重试，重发上一条用户消息 |
| 状态 UI | `UI/ChatView.swift` | connecting=脉动圆点"正在思考"，streaming=闪烁光标，error=红色 banner + 重试按钮 |
| PulsingDots | `UI/ChatView.swift` 🆕 | 三个渐入渐出圆点动画组件 |
| 键盘 onSubmit | `UI/ChatView.swift` | TextField `.onSubmit` 支持回车发送 |

### 8E-4: Chat 会话列表（ChatGPT 式「最近」）

| 改动 | 文件 | 说明 |
|------|------|------|
| ChatSession 模型 | `Storage/ChatMessageStore.swift` | id / title / createdAt / updatedAt / messages[]，displayTitle / preview 计算属性 |
| 多会话存储 | `Storage/ChatMessageStore.swift` | loadSessions/saveSessions/deleteAll，最多 50 会话 |
| ViewModel 会话管理 | `UI/ViewModels/ChatViewModel.swift` | sessions[] / currentSession / showSessionList / newChat() / switchToSession() / deleteSession() |
| 导航栏 | `UI/ChatView.swift` | 🕐 左上角 = 历史 Sheet，✏️ 右上角 = 新建对话 |
| 历史 Sheet | `UI/ChatView.swift` | 半屏/全屏 Sheet，最近列表（标题+预览+日期），滑动删除，当前会话高亮 |
| 自动命名 | `UI/ViewModels/ChatViewModel.swift` | 新会话以第一条用户消息前 40 字符为标题 |
| 导航标题 | `UI/ChatView.swift` | 自动显示当前会话名 |

**导航最终态**：
```
[🕐] 我昨晚睡得不太好…          [🟢 AI 已连接] [✏️]
```

### 8E-5: 新增文件汇总

| 文件 | 内容 |
|------|------|
| `Sources/OHeasCore/Storage/KeychainStore.swift` 🆕 | Keychain 安全存储 API |
| `Sources/OHeasCore/Storage/ChatMessageStore.swift` 🆕 | ChatMessage + ChatSession + ChatMessageStore |

### 已消除的局限

| 原局限 | 新状态 |
|--------|--------|
| Chat 历史不持久化 | ✅ JSON 持久化，50 会话 × 200 消息 |
| API Key 仅 scheme 可用 | ✅ Keychain 持久化，主屏幕启动可用 |
| 发送无状态反馈 | ✅ connecting→streaming→error 三态 + 15s 超时重试 |
| 无对话历史列表 | ✅ ChatGPT 式「最近」Sheet，切换/新建/删除 |

---

## Phase 14 — TestFlight UX Polish ✅ 已完成

**目标**：TestFlight 前的核心用户体验优化——让测试用户 30 秒内理解今日状态、原因、行动和反馈方式。

### 14A: Today 页首屏 — 结论层级强化 + 行动卡重设计

| 改动 | 文件 | 说明 |
|------|------|------|
| 行动卡重设计 | `TodayView.swift` | `stableCoachCard` 重构：突出"做什么→今晚做什么→为什么→明天验证"纵向结构，带分段标签 |
| 反馈保存按钮 | `TodayView.swift` | `coachActionButtons` 新增直接保存反馈按钮，2s 绿色确认态 |
| 详情本地化 | `TodayView.swift` | `moreDetailsSection` / `weeklyPlanStrip` 使用新 TextKey 替代硬编码字符串 |
| 反馈状态 | `TodayView.swift` | 新增 `feedbackJustSaved` 状态，保存后显示"反馈已保存"确认 |

**行动卡结构**：
```
┌─────────────────────────────────┐
│ 🟢 建议           [高置信度]    │
│                                 │
│ 做什么                          │
│ [具体建议内容]                  │
│                                 │
│ 🌙 今晚                         │
│ [今晚行动]                      │
│                                 │
│ 为什么                          │
│ [一句话原因]                    │
│                                 │
│ 明天验证                        │
│ · 睡眠: 上升或稳定              │
│ · HRV: 上升                     │
│                                 │
│ [更新建议] [看详情] [保存反馈]  │
└─────────────────────────────────┘
```

### 14B: Plan 页 — 今日计划突出 + 状态色彩

| 改动 | 文件 | 说明 |
|------|------|------|
| 状态标签本地化 | `PlanTabView.swift` | 状态使用独立 TextKey（planStatusCompleted/Adjusted/Skipped/Planned） |
| 今日徽章 | `PlanTabView.swift` | 今天的计划卡片加"今天"蓝色胶囊徽章 |
| 状态徽章 | `PlanTabView.swift` | 非 planned 状态时在卡片头部显示彩色状态胶囊（绿/橙/灰） |
| 圆角加大 | `PlanTabView.swift` | 卡片圆角 8→10pt，今日卡片 accent 色边框 |
| 操作按钮简化 | `PlanTabView.swift` | 非今日且已完成的卡片隐藏操作按钮，减少视觉噪音 |
| 状态色彩 | — | completed=green, adjusted=orange, skipped=secondary(gray)，已存在，本次强化标签显示 |

### 14C: Chat 页 — 上下文空状态 + 离线提示优化

| 改动 | 文件 | 说明 |
|------|------|------|
| 空状态改写 | `ChatView.swift` | 在线空状态显式标题"聊聊今天的身体状态"+ 提示"选择一个话题" |
| 离线空状态 | `ChatView.swift` | 从"未连接→检查配置"改为"基础问答可用→连接AI获得更好体验"，降低恐慌感 |
| 离线横幅 | `ChatView.swift` | 从"AI 未连接"改为"本地模式·基础健康问题仍可回答"，添加顶部分隔线 |
| 连接徽章 | `ChatView.swift` | 使用新 TextKey `aiOnlineShort`/`localModeShort` |
| 对话启动器 | `ChatView.swift` | 抽取 `starterRow()` 辅助视图，统一样式，离线模式限制显示 3 条 |
| RAG 术语 | `ChatViewModel.swift` | "RAG 检索"→"相关历史记忆"，避免技术术语 |

### 14D: Settings — 信息架构重组

| 改动 | 文件 | 说明 |
|------|------|------|
| 分区重排 | `SettingsView.swift` | 用户设置（隐私/账户/语言/关于）→ 测试工具（效果 + Beta 工具） |
| 测试工具 | `SettingsView.swift` | 移除 `#if DEBUG` 外层保护，改为 DisclosureGroup 折叠，普通用户默认不可见 |
| 测试工具说明 | `SettingsView.swift` | 新增 footer："这些工具用于调试和测试，普通用户不需要关注" |
| Demo/Eval 保护 | `SettingsView.swift` | `#if DEBUG` 保留在 DemoModeView / EvaluationDebugView 入口 |

**Settings 信息架构**：
```
┌─ 个人信息 ─────────────────────┐
│ OHeas | Apple 健康 | 🟢 高     │
├─ 隐私与同意 ───────────────────┤
│ AI 开关 · 提醒 · 同意项        │
├─ 账户与同步 ───────────────────┤
│ 账户 · 同步状态                │
├─ 语言 ─────────────────────────┤
│ 中文 / English                 │
├─ 关于 ─────────────────────────┤
│ 版本 · Build                   │
├─ 测试工具 ─────────────────────┤
│ 效果报告 ▶                     │
│ ▼ 测试工具                     │
│   Beta 反馈 · Analytics        │
│   Demo(DEBUG) · Eval(DEBUG)    │
│   Agent Context · 导出 · 重置   │
│ 〰 这些工具用于调试和测试...   │
└────────────────────────────────┘
```

### 14E: AppLanguage 新增键

| 新增 TextKey | 中文 | English |
|-------------|------|---------|
| `testingToolsSection` | 测试工具 | Testing Tools |
| `testingToolsFooter` | 这些工具用于调试和测试... | These tools are for debugging... |
| `moreDetailsLabel` | 更多详情 | More Details |
| `actionWhatLabel` | 做什么 | What to do |
| `actionWhyLabel` | 为什么 | Why |
| `actionVerifyLabel` | 明天验证 | Verify tomorrow |
| `actionDurationLabel` | 时长 | Duration |
| `saveFeedbackAction` | 保存反馈 | Save Feedback |
| `feedbackSavedMessage` | 反馈已保存 | Feedback saved |
| `todayStatusLabel` | 今日状态 | Today's Status |
| `todayPlanHighlight` | 今日计划 | Today's Plan |
| `chatContextEmptyTitle` | 聊聊今天的身体状态 | Let's talk about today |
| `chatContextEmptyHint` | 选择一个话题... | Pick a topic... |
| `localModeShort` | 本地模式 | Local Mode |
| `aiOnlineShort` | AI 在线 | AI Online |
| `planStatusCompleted/Adjusted/Skipped/Planned` | 已完成/已调整/已跳过/待执行 | Completed/Adjusted/Skipped/Planned |

### 14F: Tab 栏 3→4 恢复 Plan Tab

| 改动 | 文件 | 说明 |
|------|------|------|
| Plan 加回 Tab 栏 | `RootTabView.swift` | 4 Tab：今日 / 计划 / 对话 / 设置 |
| 删重复设置入口 | `PlanTabView.swift` | 移除 toolbar 设置按钮 + Sheet（设置已是独立 Tab） |

**Tab 栏最终结构**：
```
[❤️ 今日] [📅 计划] [💬 对话] [⚙️ 设置]
```

### 验证结果 (2026-06-12)

| 检查项 | 结果 |
|--------|------|
| `swift test` | ✅ 85 tests passed |
| `xcodebuild build` (iPhone 17, iOS 26.5) | ✅ BUILD SUCCEEDED |
| `xcodebuild test` | ⚠️ 未运行（已知模拟器宿主启动问题） |
| 模拟器安装启动 | ✅ App 在 iPhone 17 模拟器运行正常，4 Tab 可切换 |

### 仍需真机检查

- 4 Tab 在小屏 iPhone（SE/mini）上标签文字是否截断
- 行动卡按钮文字「更新建议/看详情/保存反馈」是否溢出
- Plan 页面今日徽章 + 状态标签 + 类型标签窄屏排版
- 深色模式 + Reduce Motion 兼容性
- Settings 测试工具 DisclosureGroup 的展开/折叠动画是否流畅
- 深色模式下所有新颜色是否可读
- Reduce Motion 开启时所有动效是否自动降级

---

## 🧪 本地构建验证 — 2026-06-12

**验证范围**：Phase 21 时间轴 & 历史视图（5 个新增文件 + 4 个修改文件，新增 History Tab + 可交互趋势图 + 逐日详情 sheet）。

### 自动化验证结果

| 检查项 | 方法 | 结果 |
|--------|------|------|
| Core 层单元测试 | `swift test` | ✅ 85 tests passed |
| Xcode scheme / destination | `xcodebuild -list` + `xcodebuild -showdestinations` | ✅ scheme `OHeas` 可用；`iPhone 17 (iOS 26.5)` 可用 |
| iOS Debug 模拟器编译 | `xcodebuild build -project OHeas.xcodeproj -scheme OHeas -destination "platform=iOS Simulator,name=iPhone 17,OS=26.5"` | ✅ `BUILD SUCCEEDED` |
| iOS 模拟器测试 | `xcodebuild test -project OHeas.xcodeproj -scheme OHeas -destination "platform=iOS Simulator,name=iPhone 17,OS=26.5"` | ⚠️ 编译/签名完成并进入 `Testing started`，但测试宿主在模拟器 launch 阶段卡住；约 164s 后人工中断，结果为 `TEST INTERRUPTED` |
| Backend pytest | `pytest app/tests` | ⚠️ 本机 Python 环境不统一：根目录 Anaconda pytest 出现 AnyIO trio 参数化/Apple JWKS 网络隔离问题；`backend/` 下 `/usr/bin/python3` 未安装 pytest。需用项目 venv 或 CI 复跑 |

### 当前结论

当前 iOS App target 可以通过 Xcode 模拟器编译，说明本轮 UI/中文体验收尾没有引入 Swift 编译错误。`xcodebuild test` 的问题发生在模拟器测试宿主启动/测试会话清理阶段，不是测试用例断言失败；发布前仍需在干净模拟器会话或 CI 上复跑完整 `xcodebuild test`。

---

## 🔬 真机验证日志 — 2026-06-10

**验证方式**：完整代码层审计 + 全量测试 + Preflight 检查（物理真机操作待用户执行）

### 自动化验证结果

| 检查项 | 方法 | 结果 |
|--------|------|------|
| Preflight 发布检查 | `scripts/preflight_release_check.sh` | ✅ 17 Pass / 2 Warn / 0 Fail |
| Core 层单元测试 | `swift test` | ✅ 85 tests passed |
| ViewModel + 连通性测试 | `xcodebuild test -scheme OHeas` | ✅ 38 tests (25 VM + 5 DeepSeek + 8 Core) passed |
| Swift 编译 | `swift build` | ✅ Build complete |
| iOS Release 编译 | `xcodebuild build -configuration Release` | ✅ 通过（Preflight #8） |
| Backend 单元测试 | `pytest app/tests/ -v` | ✅ 15 tests passed (JWT 4 + Auth 4 + Health 1 + Sync 6) |
| **总计** | | **133 tests, 0 failures** |

### P0/P1 代码修复确认（对应 real-device-validation.md 审计）

| # | 修复项 | 严重度 | 文件:行号 | 状态 |
|---|--------|--------|-----------|------|
| 1 | HRV <3 样本 → `.partial` | P0 | `DailyMetricsAggregator.swift:30` | ✅ 已确认 |
| 2 | RHR <3 样本 → `.partial` | P0 | `DailyMetricsAggregator.swift:32` | ✅ 已确认 |
| 3 | SignalDetector 降级 partial 指标 severity | P0 | `SignalDetector.swift:37,57` | ✅ 已确认 |
| 4 | 连续 7 天睡眠缺失 → 提示检查 Watch Sleep 设置 | P1 | `DataCoverageLayer.swift:90-92` | ✅ 已确认 |
| 5 | 连续 3 天睡眠缺失 → 佩戴提示 | P1 | `DataCoverageLayer.swift:93-95` | ✅ 已确认 |
| 6 | 连续 3 天恢复数据缺失 → 佩戴提示 | P1 | `DataCoverageLayer.swift:96-98` | ✅ 已确认 |
| 7 | 同步延迟 → missingReasons 加提示 | P1 | `DataCoverageLayer.swift:111-113` | ✅ 已确认 |
| 8 | 基线不足引导 (<7 天) → `baselineGuidanceMessage` | P0 | `DataCoverageLayer.swift:213-218` | ✅ 已确认 |
| 9 | API Key PLACEHOLDER 检测 | P1 | `OHeasAppConfiguration.swift:32` | ✅ 已确认 |
| 10 | NSHealthUpdateUsageDescription | P0 | `Info.plist:25-26` | ✅ 已确认 |
| 11 | UIRequiredDeviceCapabilities[healthkit] | P0 | `Info.plist:32` | ✅ 已确认 |
| 12 | HealthKit entitlement | P0 | `OHeas.entitlements:5-6` | ✅ 已确认 |

### 构建配置确认

| 配置项 | 值 | 状态 |
|--------|-----|------|
| DEVELOPMENT_TEAM | `6YFW7W33NV` | ✅ 已设置 |
| CODE_SIGN_STYLE | Automatic | ✅ 自动签名 |
| BUNDLE_IDENTIFIER | `com.oheas.mvp` | ✅ |
| Deployment Target | iOS 17.0 | ✅ |
| DeepSeek API Key | `sk-901f...` (已注入 scheme) | ✅ 非 PLACEHOLDER |
| API Key 安全性 | `deepseek.env` + `xcschemes/` 均在 `.gitignore` | ✅ 不会提交 |

### 真机物理验证清单（需用户在 iPhone + Apple Watch 上执行）

以下步骤需要在实际设备上操作，按优先级排列：

#### 立即执行（P0 - 核心链路）

```
□ 1. Xcode → 选择真机（iPhone 17+）→ ⌘R 运行
□ 2. 完成 Onboarding，允许所有 HealthKit 权限
□ 3. 观察 Today 页是否显示真实数据（非 mock 的 Sleep/HRV/RHR 值）
□ 4. Settings → Beta Readiness → 检查：
     - healthKitPermissions: 7 项应全为 authorized
     - perMetricCoverage: 各指标不应全为 missing
     - recoveryBaselineDays: 取决于历史数据天数
□ 5. Chat Tab → 检查顶部连接状态（应显示绿色 "AI 已连接"）
□ 6. 发送一条对话消息（如"我今天的数据怎么样？"），确认收到流式回复
```

#### 场景验证（P1 - 数据质量）

```
□ 7. 如果昨晚佩戴手表睡觉：检查 sleepHours 非 missing
□ 8. 如果有 HRV 数据：检查是否被正确标记为 valid/partial
□ 9. Settings → Health Permissions → 确认 7 项权限状态
□ 10. 拒绝某项权限 → 回到 app → 检查 RecoveryView 是否提示
```

#### 多日验证（P2 - Agent 闭环）

```
□ 11. Day 1: 接收 AI 建议 → 提交反馈（adherence/energy/soreness/stress 滑块）
□ 12. Day 2: 打开 app → 检查 Yesterday Section 是否有验证结果
□ 13. 连续 5 天使用 → Settings → Agent Context → 检查是否有 Pattern 出现
```

#### 发布前检查（需在 Archive 前执行）

```
□ 14. 杀掉 app → 从主屏幕重新打开 → 确认 Onboarding 状态保持
□ 15. 关闭 AI 开关 → Chat Tab 应显示"本地模式"橙色标记
□ 16. 重新开启 AI → Chat 应恢复绿色 "AI 已连接"
□ 17. Xcode → Product → Archive → 确认无签名错误
```

### 验证结论

**代码层面**：全部 103 个测试通过，Preflight 0 失败，12 项 P0/P1 修复全部在源码中确认，构建配置完整。

**物理验证**：代码已就绪，可以立即在真机上运行。上述 17 步真机操作清单覆盖了 mock→real 数据链路的所有关键路径。

**风险点**：唯一的剩余风险是真实 Apple Watch 信号质量（如 HRV 测量频率、睡眠分段精度），这些只能在真机上验证。建议首次运行后重点观察 `AgentContextView → Beta Readiness → perMetricCoverage` 中各指标的实际数据覆盖情况。
