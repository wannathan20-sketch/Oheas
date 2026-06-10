# Apple Sign In — Service ID 配置指南

> 完成这些步骤后，iOS 端到端 Apple Sign In → Backend JWT 交换 链路即可打通。

## 前提

- 付费 Apple Developer 账号（$99/年）
- Xcode 中已配置 Team（当前：`6YFW7W33NV`）

## 第 1 步：获取 Team ID

1. 打开 https://developer.apple.com/account
2. 右上角查看 **Team ID**（如 `6YFW7W33NV`）
3. 记下这个值 → 填入 backend `.env` 的 `APPLE_TEAM_ID`

## 第 2 步：创建 Service ID

1. 进入 **Certificates, Identifiers & Profiles**
2. 左侧栏 → **Identifiers** → 点击 **+** 按钮
3. 选择 **Services IDs** → Continue
4. 填写：
   - **Description**: `OHeas Sign In`
   - **Identifier**: `com.oheas.mvp`（与 backend 的 `APPLE_CLIENT_ID` 一致）
5. 点击 **Continue** → **Register**

## 第 3 步：配置 Sign in with Apple

1. 在 Identifiers 列表中找到刚创建的 Service ID，点击进入
2. 勾选 **Sign In with Apple** → 点击 **Configure**
3. 在 **Web Authentication Configuration** 部分：
   - **Primary App ID**: 选择你的 App ID（`com.oheas.mvp`）
4. 在 **Domains and Subdomains** 部分：
   - 添加你的后端域名（如 `api.oheas.example.com`）
   - 不需要 `https://` 前缀
5. 在 **Return URLs** 部分：
   - 添加 `https://api.oheas.example.com/v1/auth/apple/callback`
   - （如暂未部署可不填，后续可补）
6. 点击 **Save**

## 第 4 步：iOS App 端配置（Xcode）

1. Xcode → 项目 → **Signing & Capabilities**
2. 点击 **+ Capability** → 添加 **Sign in with Apple**
3. 确认 App ID 的 Sign in with Apple 能力已启用

## 第 5 步：Backend .env 配置

```sh
# backend/.env
APPLE_TEAM_ID=6YFW7W33NV            # 第1步的 Team ID
APPLE_CLIENT_ID=com.oheas.mvp       # 第2步的 Service ID
```

## 第 6 步：验证

```sh
cd backend
docker compose up -d

# 测试 health
curl http://localhost:8000/health

# 测试 auth 端点存在（无需真实 token）
curl -X POST http://localhost:8000/v1/auth/apple \
  -H "Content-Type: application/json" \
  -d '{"identity_token":"invalid","full_name":"Test User"}'
# 预期返回 401（token 无效，说明端点通了）
```

## 端到端流程

```
iOS App:
  1. 用户点击 "Sign in with Apple"
  2. ASAuthorizationAppleIDProvider 弹出系统授权
  3. 获得 ASAuthorizationAppleIDCredential
     → identityToken (Data) → 转 String
     → fullName (首次)
  4. AppleAuthService 调用 POST /v1/auth/apple
     → 发送 identity_token + full_name

Backend:
  5. verify_apple_identity_token(identity_token)
     → 从 appleid.apple.com 获取 JWKS
     → 用 RS256 验证 JWT 签名 + audience + issuer
     → 提取 sub (Apple user identifier)
  6. AuthRepository.find_or_create_user(apple_sub)
  7. 签发自有 JWT (access_token + refresh_token)
  8. 返回 TokenResponse

iOS App:
  9. AuthTokenStore 存储到 Keychain
  10. 后续请求带 Authorization: Bearer <access_token>
```

## 注意事项

- Apple 只在**首次**登录时返回 `fullName` 和 `email`。后续登录只返回 `user` identifier
- 如果用户撤销 Apple ID 授权，需要在 iOS 端监听 `ASAuthorizationAppleIDProvider.getCredentialState`
- 测试时可以用模拟器，但真实 Sign in with Apple 弹窗需要在真机上验证
