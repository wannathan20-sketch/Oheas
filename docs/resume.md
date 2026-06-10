# OHeas — 简历项目描述

> 按简历版块组织，按需裁剪使用。标注 🆕 的为新增规划项。

---

## 一句话（项目栏 / 页眉用）

**OHeas（Oh Health）**：基于 Apple Watch 健康数据的 AI 身体状态 Agent——从数据采集到 LLM 建议生成，到次日验证反馈，完整闭环的个人化健康教练 iOS App。

---

## 项目概述（2-3 句）

独立设计并实现了一款 iOS 健康教练 App，通过 HealthKit 读取 Apple Watch 数据（睡眠、HRV、静息心率、运动等），构建 14 天生理基线，结合 LLM 生成每日个性化建议，并在次日通过指标对比验证建议是否有效。包含长期记忆、N-of-1 个人实验、自适应周计划、安全护栏、向量语义检索（RAG）、CI/CD 自动化等完整系统。

---

## 技术栈

| 层 | 技术 |
|----|------|
| iOS | SwiftUI · HealthKit · UserNotifications · Keychain · Combine · WatchKit |
| 架构 | MVVM（8 个子 ViewModel） · Codable 本地持久化 · Async/Await 全异步 |
| LLM | OpenAI Responses API · DeepSeek Chat Completions · SSE 流式 · 结构化 JSON 输出 · **text-embedding-3-small** |
| RAG | pgvector（Supabase） · 语义检索 → LLM 上下文注入 · 6 种健康记忆源 |
| 后端 | FastAPI · SQLAlchemy (async) · PostgreSQL · JWT (HS256) · Alembic |
| DevOps | Docker · Docker Compose · Zeabur PaaS · Supabase · **GitHub Actions CI/CD** |
| 推送 | UserNotifications（本地） · **APNs（远程静默推送 + 异常告警）** |
| 安全 | 双级安全护栏（Regex + LLM 语义审查） · 隐私分级控制 · Keychain 密钥存储 · App-layer RLS |
| 测试 | **158 个测试**（Swift Testing + pytest） · Preflight 发布检查脚本 |

---

## 亮点（适用于项目详情）

### 技术亮点

- **零外部依赖的 iOS 架构**：仅用 Foundation + HealthKit + UserNotifications 构建完整 MVVM 架构，8 个子 ViewModel 各司其职，单一职责 < 250 行，协调层仅做委托转发
- **RAG 语义检索**：对 6 种本地健康记忆（Pattern / 干预 / 反馈 / 实验 / 建议 / 复盘）做 pgvector 向量检索，让 LLM 教练能回答"三个月前调整睡眠后 HRV 怎么变的？"这类跨时间窗口问题，替代全量规则注入
- **多级降链**：API Key 缺失 → PLACEHOLDER 检测 → 无 AI 授权 → 网络失败 → JSON 解析失败 → 全部自动降级到本地规则引擎，保证 App 永不崩溃
- **双模型协作安全架构**：Coach Agent 产出建议 + 独立 Safety Agent 语义审查，双 LLM 相互制衡。L1 Regex（8 种危险模式，零延迟）→ L2 LLM 深度审查（检测 L1 漏报），失败自动回退 L1
- **LLM 流式输出**：基于 SSE 的 Chat Completions 流式，含 15s 首 token 超时 + 一键重试 + 打字机 fallback 动画
- **完整 Backend**：FastAPI + PostgreSQL（17 张表） + JWT 认证 + Apple Sign In + Docker Compose 一键部署 + Alembic auto-migrate
- **CI/CD 自动化**：GitHub Actions，push 即跑 158 测试 + Release 编译检查 + Preflight 发布脚本
- **App-Layer RLS**：Repository 层强制 `WHERE user_id = $user_id`，替代 DB-level RLS，每个用户的数据严格隔离
- **Apple Watch 生态闭环**：表盘 Complication 显示今日身体预算环 + APNs 静默推送异常告警（HRV 连续偏低 / 睡眠严重不足）

### 产品亮点

- **完整 Agent 闭环**：每日数据 → LLM 建议 → 用户反馈（依从性/精力/酸痛/压力 1-10）→ 次日指标对比验证 → Pattern Mining → 长期记忆（30 天半衰期衰减）→ RAG 语义检索 → N-of-1 个人实验
- **隐私优先**：默认 AI 关闭、默认不发送原始 HealthKit 数据、7 项隐私开关分立控制、本地导出不含 raw samples
- **自适应周计划**：根据恢复状态、数据置信度、活跃实验、连续高强度天数自动调整当日计划强度和类型
- **主动健康干预**：APNs 静默推送 → 后台分析 HRV/睡眠趋势 → 异常触发通知，从"被动查看"升级为"主动守护"
- **4 种 Demo 场景**：30 天完整模拟轨迹（过劳/过度训练/数据缺失/习惯养成），无需 Apple Watch 即可体验完整流程
- **中英双语**：UI 支持 中文 ↔ English 实时切换，LLM Prompt 保持英文结构化

---

## STAR 描述（适用于工作经历）

**项目**：OHeas — 个人 AI 健康教练 iOS App（独立开发）

**S - 背景**  
健康数据分散在 Apple Watch 中，用户缺乏从数据到可执行建议的闭环。现有健康 App 多为数据看板而非主动教练，且无法回答跨时间窗口的个性化问题。

**T - 任务**  
设计并实现一个覆盖数据采集 → RAG 语义检索 → LLM 生成建议 → 次日验证的完整 Agent 系统，支持 Apple Watch 生态闭环（Complication + APNs 推送），满足安全、隐私、离线可用等产品级要求。

**A - 行动**  
- 用 SwiftUI + MVVM 搭建 iOS App（~12,000 行 Swift），零外部依赖，8 个子 ViewModel 单一职责
- 自研 HealthKit 数据管线：聚合器（缺失≠0）→ 基线引擎（7/14/30d）→ 信号检测（HRV/RHR/Sleep）→ 数据置信度评估
- 构建 RAG 语义检索：pgvector 向量化 6 种健康记忆源 → text-embedding-3-small → cosine 检索 top-K → 注入 LLM 上下文，替代全量规则注入
- 集成 DeepSeek + OpenAI 双 LLM Provider，含 SSE 流式输出、结构化 JSON 解析、多级自动降级
- 实现双模型安全架构：Coach Agent 产出 + 独立 Safety Agent 语义审查，覆盖 8 种危险模式
- 构建长期记忆系统：Pattern Mining + 30 天半衰期衰减 + N-of-1 个人实验引擎
- 用 FastAPI + PostgreSQL 构建后端（17 张表），JWT + Apple Sign In 认证，Docker Compose 一键部署
- 配置 GitHub Actions CI/CD：push 即跑 158 测试 + Release 编译检查
- 实现 Watch Complication + APNs 静默推送异常告警

**R - 成果**  
- 完整可运行的 iOS App（模拟器可直接体验），Release/Debug 均编译通过
- 支持真机 HealthKit + Apple Watch 完整数据链路 + 表盘 Complication
- 后端 15 个 pytest 全部通过，Docker 可一键启动，CI 自动验证
- 具备 TestFlight 发布条件（签名/权限/隐私清单/Preflight 检查全部就绪）

---

## 可量化的数字

| 指标 | 数值 |
|------|------|
| iOS 代码量 | ~12,000 行 Swift（54 Core + 39 UI） |
| Backend 代码量 | ~2,100 行 Python（18 文件） |
| 测试总量 | 158 个（含 RAG / Push / Complication 测试），0 失败 |
| DB 表 | 18 张（含 memory_embeddings） |
| LLM Provider | 3（OpenAI / DeepSeek / 自定义兼容端点） |
| Embedding 模型 | text-embedding-3-small（1536 维） |
| RAG 检索源 | 6 种（Pattern / 干预 / 反馈 / 实验 / 建议 / 复盘） |
| ViewModel 架构 | 8 个子 VM，每个 < 250 行 |
| Safety 架构 | 双模型协作（Coach + Safety Agent），8 种 L1 + L2 语义双级 |
| 存储 | 本地 JSON + Keychain + PostgreSQL + pgvector |
| 外部依赖 | 0（iOS 侧仅用 Apple 原生框架） |
| CI/CD | GitHub Actions，每次 push 自动测试 + 编译 |

---

## 面试可能问到的点（建议提前准备）

1. **"为什么零外部依赖？"** → 减少二进制体积、避免三方库安全风险、HealthKit 本身功能足够、项目规模可控
2. **"LLM 回复不可控怎么办？"** → 双模型安全架构：Coach Agent 产出 + Safety Agent 审查，相互制衡；L1 Regex 零延迟 + L2 LLM 语义深度审查，失败自动降级
3. **"如何处理缺失数据？"** → 缺失不归零（标记为 partial/missing）、置信度降级、SignalDetector 降权、计划自动降强
4. **"RAG 和普通上下文注入有什么区别？"** → 之前是规则驱动的全量注入（20 patterns + 20 interventions 固定窗口），RAG 按语义相似度动态检索 top-K，让 LLM 能回答"三个月前那次实验的结论"这类跨时间问题，不受固定窗口限制
5. **"为什么选 pgvector 而不是 Pinecone/Weaviate？"** → Supabase 自带 pgvector 扩展，无需额外服务；PostgreSQL 事务保证 embedding 和数据的一致性；MVP 阶段规模不需要专用向量数据库
6. **"多设备数据冲突怎么办？"** → Last-write-wins + unified sync_records 信封 + 时间戳比较
7. **"为什么不用 Core Data / SwiftData？"** → MVP 阶段 Codable JSON 开发速度更快、耦合更低，后续可按需迁移
8. **"APNs 推送怎么实现后台数据分析？"** → 静默推送触发 `BGAppRefreshTask` → 后台拉取最新 HealthKit → 异常检测 → 有异常才发用户可见推送，避免打扰
9. **"安全性你怎么考虑？"** → 默认 AI 关闭、Raw 数据不上传、App-layer RLS、Keychain 存 token、Analytics 过滤敏感字段、双模型安全审查
