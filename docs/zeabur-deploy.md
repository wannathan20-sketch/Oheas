# Zeabur 部署指南

> OHeas Backend 部署到 Zeabur（PaaS），数据库用 Supabase。

## 架构

```
GitHub Repo → Zeabur（自动构建 Dockerfile → 部署）
                ├── 自动 HTTPS + 域名
                └── 环境变量管理

Supabase（托管 PostgreSQL，外部连接）
```

## 第 1 步：Supabase 创建数据库

1. 打开 https://supabase.com → Sign In
2. 新建项目 → 记住数据库密码
3. 进入 **Project Settings → Database → Connection string**
4. 选择 **URI** 标签 → 复制连接字符串
5. 把 `[YOUR-PASSWORD]` 替换为你的密码

最终格式：
```
postgresql+asyncpg://postgres.[project-ref]:[password]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?sslmode=require
```

> ⚠️ 用 Supabase Session Pooler（port 6543），不用 Transaction Pooler（port 5432）

## 第 2 步：生成 JWT Secret

```sh
openssl rand -hex 32
# 输出类似：a1b2c3d4e5f6...（64 字符）
```

记下这个值。

## 第 3 步：推代码到 GitHub

```sh
cd /Users/wanna/watch_health
git init
git add -A
git commit -m "Ready for Zeabur deployment"
git remote add origin https://github.com/你的用户名/oheas.git
git push -u origin main
```

## 第 4 步：Zeabur 部署

1. 打开 https://dash.zeabur.com
2. **New Project** → 命名 `oheas`
3. **Add Service** → **Deploy from GitHub**
4. 授权并选择 `oheas` 仓库
5. Zeabur 自动检测到 `backend/Dockerfile` → 选择 **Docker** 部署方式
6. **Root Directory** 设为 `backend`
7. 点击 **Deploy**

## 第 5 步：配置环境变量

在 Zeabur Service → **Environment Variables** 中添加：

| Key | Value | 说明 |
|-----|-------|------|
| `DATABASE_URL` | `postgresql+asyncpg://...` | 第 1 步的 Supabase 连接串 |
| `JWT_SECRET` | `openssl rand -hex 32 的输出` | 第 2 步生成的值 |
| `APPLE_TEAM_ID` | `6YFW7W33NV` | Apple Developer Team ID |
| `APPLE_CLIENT_ID` | `com.oheas.mvp` | Service ID |
| `DEBUG` | `false` | 生产环境关闭 debug |

## 第 6 步：配置域名

1. Zeabur → Service → **Domain**
2. 添加自定义域名，如 `api.oheas.你的域名.com`
3. 去你的域名 DNS 后台添加 CNAME 记录，指向 Zeabur 提供的域名
4. 等待 HTTPS 证书自动签发（1-2 分钟）

## 第 7 步：验证

```sh
# Health check
curl https://api.oheas.你的域名.com/health

# 预期返回
# {"status":"ok","database":"connected","version":"0.2.0"}

# 测试 auth 端点
curl -X POST https://api.oheas.你的域名.com/v1/auth/apple \
  -H "Content-Type: application/json" \
  -d '{"identity_token":"test"}'
# 预期返回 401（token 无效 = 端点正常）
```

## 后续

部署完成后，在 iOS App 中配置：

```
OHEAS_BACKEND_URL = https://api.oheas.你的域名.com
```

然后 iOS 端到端 Sync 链路就可以开始验证。
