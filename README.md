# OHeas（Oh Health）

> 基于 Apple Watch / Apple Health 数据的个人 AI 身体状态教练——观察数据 → 发现模式 → 给出每日最小可执行建议 → 第二天验证是否有效。

[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![Python](https://img.shields.io/badge/Python-3.12-blue)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-teal)](https://fastapi.tiangolo.com)
[![Tests](https://img.shields.io/badge/Tests-133%20passed-brightgreen)]()
[![License](https://img.shields.io/badge/License-MIT-lightgrey)]()

一个会长期学习用户的 lifestyle coach——不是健康仪表盘，不是普通聊天机器人。

---

## 是什么

OHeas 读取 Apple Watch 健康数据（睡眠、HRV、静息心率、运动等），构建你的 14 天生理基线，用 LLM 生成**一条可执行的小建议**，第二天通过指标对比**验证建议是否真的帮到了你**。一个月后，它知道什么对你有用、什么没用。

## 一句话解释

```
每日数据 → 今日建议 → 你打分反馈 → 明天验证 → 形成 Pattern → 记忆衰减 → 个人实验 → 自适应周计划
```

## 包含什么

### iOS App（SwiftUI · 零外部依赖）

| 模块 | 说明 |
|------|------|
| HealthKit 数据管线 | 读取 + Mock 双源、聚合器（缺失≠0）、基线引擎（7/14/30d）、信号检测、置信度 |
| LLM 接入 | DeepSeek / OpenAI 双 Provider、SSE 流式输出、结构化 JSON、多级降链 |
| 安全护栏 | 双模型架构（Coach + Safety Agent）、8 种危险模式、L1 Regex + L2 语义审查 |
| 长期记忆 | Pattern Mining、30 天半衰期衰减、N-of-1 个人实验引擎 |
| 自适应周计划 | 根据恢复/置信度/实验/历史自动调整每日计划 |
| Chat 对话 | 多轮对话、会话历史、流式打字效果、ChatGPT 式会话列表 |
| 隐私 | 默认 AI 关闭、7 项隐私开关、原始数据不离开设备 |

### Backend（FastAPI + PostgreSQL）

| 模块 | 说明 |
|------|------|
| 认证 | Apple Sign In + JWT（access/refresh token） |
| Sync API | Upload / Fetch / Delete、统一信封表、last-write-wins |
| 数据安全 | App-layer RLS、Raw sample 上传拦截 |
| 部署 | Docker Compose 一键启动、Alembic auto-migrate、Zeabur PaaS |

---

## 快速开始

### 模拟器（无需真机、无需 API Key）

```sh
git clone https://github.com/wannathan20-sketch/Oheas.git
cd Oheas

# 可选：配置 DeepSeek API Key
cp deepseek.env.example deepseek.env
# 编辑 deepseek.env 填入 key，然后：
./configure.sh

# 或跳过 LLM，直接用本地规则引擎：
xcodegen generate
open OHeas.xcodeproj
# ⌘R 运行，自动使用 30 天 Mock 数据
```

没有 API Key 也能跑——App 自动降级到规则引擎，反馈闭环和验证功能完整可用。

### 启用 LLM（三选一）

```sh
# DeepSeek（推荐，国内可用）
cp deepseek.env.example deepseek.env     # 填入 DEEPSEEK_API_KEY=sk-xxx
./configure.sh

# OpenAI
# Xcode → Scheme → Environment Variables → OPENAI_API_KEY=sk-...

# 自定义兼容端点
# Xcode → Scheme → Environment Variables → LLM_API_KEY=xxx + LLM_BASE_URL=https://...
```

### Backend

```sh
cd backend
cp .env.example .env
docker compose up -d
# API → http://localhost:8000
# Alembic 自动 migrate
```

---

## 项目结构

```
OHeas/
├── Sources/OHeasCore/          # 核心库（54 文件，~6,500 行）
│   ├── Data/                   # HealthKitReader + MockHealthDataProvider
│   ├── Analysis/               # 聚合器、基线引擎、信号检测、置信度
│   ├── LLM/                    # 双 Provider + SSE 流式客户端
│   ├── Recommendations/        # LLM 编排 + 规则引擎 fallback
│   ├── Safety/                 # 双级安全护栏
│   ├── Memory/                 # 记忆存储 + 30 天衰减
│   ├── Experiments/            # N-of-1 实验
│   ├── Planning/               # 自适应周计划
│   ├── Agent/                  # Context 构建 + Prompt 模板
│   ├── Privacy/                # 隐私管理器
│   ├── Evaluation/             # 评估执行器 + Prompt 回归
│   ├── Effectiveness/          # 效果分析器
│   ├── Sync/                   # 同步引擎
│   ├── Onboarding/             # 引导流程
│   └── Models/                 # 数据模型
├── OHeasApp/                   # SwiftUI App（39 文件，~5,500 行）
│   └── UI/
│       ├── TodayView.swift     # 今日：身体预算环 + 建议 + 信号
│       ├── ChatView.swift      # 对话：AI 健康教练
│       ├── SettingsView.swift  # 设置：账户/隐私/数据
│       └── ViewModels/         # 8 个子 ViewModel
├── OHeasAppTests/              # 测试（80 + 25 个）
├── backend/                    # FastAPI Backend（18 文件）
│   └── app/
│       ├── auth/               # JWT + Apple Sign In
│       ├── db/                 # ORM 模型 + Repository
│       └── routes/             # health / auth / sync
├── docs/                       # 文档（13 份）
├── scripts/                    # 构建脚本
└── project.yml                 # XcodeGen 项目配置
```

---

## 技术栈

| 层 | 技术 |
|----|------|
| iOS | SwiftUI · HealthKit · UserNotifications · Keychain |
| 架构 | MVVM（8 ViewModel） · Async/Await · Codable |
| LLM | OpenAI Responses · DeepSeek Chat Completions · SSE Streaming |
| 后端 | FastAPI · SQLAlchemy async · PostgreSQL · JWT |
| 运维 | Docker · Docker Compose · Zeabur · Supabase |
| 测试 | Swift Testing · pytest · 133 测试 · Preflight 脚本 |

---

## 安全与隐私

- **默认 AI 关闭**：用户需明确 opt-in
- **双模型安全护栏**：Coach Agent 产出 → Safety Agent 审查 → 通过才展示
- **8 种危险模式检测**：医疗诊断、紧急症状、过度训练、极端节食等
- **Raw 数据不上传**：原始 HealthKit 采样永不离开设备
- **App-Layer RLS**：Repository 层强制 `WHERE user_id = $user_id`
- **数据导出不含敏感信息**：只导出聚合摘要

**OHeas 是生活方式教练，不是医疗诊断系统。**

---

## 文档索引

| 文档 | 内容 |
|------|------|
| [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md) | 项目状态总览（各 Phase 完成情况、测试覆盖、下一步计划） |
| [`docs/resume.md`](docs/resume.md) | 简历项目描述（含技术亮点、STAR、面试预答） |
| [`docs/zeabur-deploy.md`](docs/zeabur-deploy.md) | Zeabur 部署指南 |
| [`docs/apple-sign-in-setup.md`](docs/apple-sign-in-setup.md) | Apple Sign In 配置指南 |
| [`docs/beta-smoke-test-checklist.md`](docs/beta-smoke-test-checklist.md) | Beta 冒烟测试清单 |
| [`docs/testflight-readiness.md`](docs/testflight-readiness.md) | TestFlight 就绪清单 |
| [`backend/README.md`](backend/README.md) | Backend 开发文档 |

---

## 测试

```sh
swift test                          # Core 80 个测试
xcodebuild test -scheme OHeas      # Core + ViewModel
cd backend && pytest app/tests/ -v # Backend 15 个测试
./scripts/preflight_release_check.sh  # 发布前 17 项检查
```

---

## 许可

MIT License
