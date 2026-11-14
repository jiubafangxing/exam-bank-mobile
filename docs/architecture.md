# 架构说明

> 本文件只描述客户端架构，不包含后端接口路径、字段或契约细节。

## 1. 总体

```
                    ┌──────────────────────────────┐
                    │  exam-bank (后端, 独立私有)   │
                    │  candidate-service            │
                    └───────────────┬──────────────┘
                                    │ HTTPS + Bearer JWT
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
 ┌──────▼──────┐            ┌───────▼──────┐            ┌───────▼──────┐
 │  Android    │            │     iOS      │            │  HarmonyOS   │
 │ Kotlin+     │            │ Swift+       │            │ ArkTS+       │
 │ Compose     │            │ SwiftUI      │            │ ArkUI        │
 └──────┬──────┘            └───────┬──────┘            └───────┬──────┘
        └─────────── 共享设计令牌（shared/design/）────────────────┘
```

三端**各自原生**，不共享运行时代码；仅通过 `shared/design/tokens.json` 保持一致视觉。
接口契约由后端私有一份，**不进本仓库**（见 `shared/openapi/README.md`）。

## 2. 分层（三端一致）

```
presentation（页面 / View / Composable）
   │  只做 UI 与用户交互，调用 ViewModel/Store
viewmodel（状态 + 业务编排）
   │  倒计时、防抖保存、心跳、交卷状态机
data（Repository / API）
   │  统一信封解包、错误映射、DTO
core（network / storage / config / model）
      OkHttp/URLSession/ohos.http；Keystore/Keychain/preferences；构建期注入配置
```

## 3. 网络层

- 统一 `ApiClient`：baseUrl + Bearer 注入 + 客户端类型头 + 信封解包 + 未授权处理。
- 错误模型：业务码 + 文案 + HTTP 状态。
- 日志脱敏：Authorization / password / token 字段不打印。
- 具体路径与字段以实现层为准，不在文档中复述契约。

## 4. 会话与安全

- 会话令牌存平台安全存储；启动时校验有效性，失效则清会话。
- 多租户：登录后若需选择机构，进入选择流程再换取会话。
- 绝不持久化密码；绝不写入源码/配置文件（见 `SECURITY.md`）。

## 5. 作答状态机（核心）

```
[开考/续考] 获取作答状态（题目、已存答案、服务器时间）
   │
   ▼
[作答中] 本地倒计时(每秒) + 定时心跳校准
   │  答案变更 → 防抖保存
   │  切后台/失焦 → 行为事件上报（节流）
   ▼
[交卷] flush 未保存答案 → 提交（幂等）
   │
   ▼
[成绩] 结果页；解析回看
```

## 6. 构建时配置注入

- 域名等构建配置**不进仓库**，由 `scripts/inject-config.sh` 从环境变量写入本地忽略文件；
- 本地开发手动 export；CI 由 GitHub Actions 从 **Secrets** 注入（见 `.github/workflows/`、`docs/ci.md`）。

| 平台 | 注入目标 | 读取方式 |
|------|----------|----------|
| Android | `android/local.properties` | Gradle `buildConfigField` → `BuildConfig` |
| iOS | `ios/Configs/Secrets.xcconfig` | `Info.plist` → `Bundle.main` → `AppConfig` |
| Harmony | `harmony/local.properties` + `GeneratedConfig.ets` | `GeneratedConfig` |
