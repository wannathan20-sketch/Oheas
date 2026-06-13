# OHeas 后端 — Zeabur 部署指南

## 前提

- GitHub 仓库已同步：`wannathan20-sketch/OHeas`
- Zeabur 账号已注册并绑定 GitHub：https://zeabur.com

## 第一步：创建服务

1. 打开 https://dash.zeabur.com → **Import Project**
2. 选择 `wannathan20-sketch/OHeas` 仓库
3. Zeabur 会自动检测到 Dockerfile。点击服务卡片进入设置。

## 第二步：设置 Root Directory

服务设置 → **Root Directory** → 填写 `backend`

## 第三步：添加 PostgreSQL

1. 在服务页面点击 **+ Add Service** → 选择 **PostgreSQL**
2. Zeabur 会自动注入 `DATABASE_URL` 环境变量到主服务

## 第四步：配置环境变量

在服务 → Environment Variables 中添加：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `JWT_SECRET` | `openssl rand -hex 32` 生成一个 | JWT 签名密钥（在终端运行左边命令） |
| `LLM_API_KEY` | `<你的 DeepSeek API Key>` | LLM 代理（不设则 iOS 走本地 fallback） |
| `LLM_BASE_URL` | `https://api.deepseek.com/v1/chat/completions` | LLM 上游地址 |
| `LLM_MODEL` | `deepseek-chat` | 模型名 |
| `DEBUG` | `false` | 生产环境关闭 |
| `LOG_FORMAT` | `json` | JSON 结构化日志 |
| `RATE_LIMIT_AUTH_PER_MINUTE` | `5` | 认证端点限流 |
| `RATE_LIMIT_LLM_PER_MINUTE` | `20` | LLM 端点限流 |

> PostgreSQL 的 `DATABASE_URL` 由 Zeabur 自动注入，无需手动设置。

## 第五步：部署

1. 点击 **Deploy** 按钮
2. 等待构建完成（首次约 2-3 分钟）
3. Zeabur 会分配一个域名，如 `oheas.zeabur.app`

## 第六步：验证

```bash
# 替换为你的 Zeabur 域名
export BASE_URL=https://your-app.zeabur.app

# 健康检查
curl $BASE_URL/health
# → {"status": "ok"}

# 就绪检查
curl $BASE_URL/readyz
# → {"status": "ok", "db": true}

# 设备登录
curl -X POST $BASE_URL/v1/auth/device \
  -H "Content-Type: application/json" \
  -d '{"device_id": "test-uuid-123"}'
# → {"access_token": "...", "user_id": "..."}
```

## 第七步：iOS 客户端配置

在 iOS 设置页面或 UserDefaults 中设置后端 URL：

```
OHEAS_BACKEND_URL = https://your-app.zeabur.app
```

或者通过 Xcode Scheme → Environment Variables 注入。

## 故障排查

| 问题 | 检查 |
|------|------|
| 构建失败 | Zeabur 构建日志 → 确认 Root Directory 是 `backend` |
| 启动失败 | `start.sh` 权限、alembic 迁移报错 |
| DB 连接失败 | PostgreSQL 服务是否已添加、DATABASE_URL 是否正确 |
| 健康检查失败 | `curl BASE_URL/readyz` 查看具体错误 |
