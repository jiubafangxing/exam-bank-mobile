# exam-bank-mobile

在线考试系统 · **考生端三端原生客户端**（Android / iOS / HarmonyOS）。

本仓库与后端 `exam-bank` **并列独立**，只负责移动端考生 App，不包含任何服务端代码。
三端均使用各自官方语言原生开发，共享同一份接口契约与设计令牌，不共享运行时代码。

| 端 | 语言 | UI 框架 | 构建 |
|----|------|---------|------|
| Android | Kotlin | Jetpack Compose + Material 3 | Gradle / AGP |
| iOS | Swift | SwiftUI | Xcode / XcodeGen |
| HarmonyOS | ArkTS | ArkUI (HarmonyOS Next) | DevEco Studio / hvigor |

## 目录结构

```
exam-bank-mobile/
├─ android/              # Kotlin + Jetpack Compose 原生 App
├─ ios/                  # Swift + SwiftUI 原生 App（XcodeGen 工程）
├─ harmony/              # ArkTS + ArkUI 原生 App（HarmonyOS Next）
├─ shared/
│  ├─ openapi/           # 后端契约仅本地私有，禁止入库（见该目录 README）
│  └─ design/            # 设计令牌（颜色/间距/圆角/字体），三端各自转译
├─ docs/                 # 架构、接口映射、功能矩阵、构建说明、安全策略
├─ scripts/              # 密钥扫描、Git hooks 安装
└─ .githooks/            # pre-commit 密钥拦截
```

## 安全红线（务必先读）

> 本仓库**绝对不允许**出现：API Key、官网登录用户名/密码、数据库密码、JWT/Secret、
> 证书私钥、云厂商 AccessKey。真实值只放本地不入库文件，仓库只提交 `*.example` 模板。
> 详见 [SECURITY.md](SECURITY.md)，并由 `scripts/scan-secrets.sh` + pre-commit 强制拦截。

```bash
# 安装提交前密钥扫描（每个克隆只需一次）
bash scripts/install-git-hooks.sh
```

## 本地配置（真实值不入库）

三端统一模式：**仓库只放占位模板，运行前在本地生成真实配置**。

| 端 | 模板（提交） | 本地真实文件（忽略） |
|----|--------------|----------------------|
| Android | `android/local.properties.example` | `android/local.properties` |
| iOS | `ios/Configs/Secrets.xcconfig.example` | `ios/Configs/Secrets.xcconfig` |
| Harmony | `harmony/local.properties.example` | `harmony/local.properties` |

配置项仅两类，均非机密以外的业务地址：
- `API_BASE_URL`：考试端后端地址（如 `https://<your-host>/api`）；
- 是否允许明文 HTTP（仅本地联调用，默认关闭）。

**登录用户名/密码永不写入任何配置文件**，只由用户在 App 运行时输入，
并用系统安全存储持久化会话 Token（Android Keystore / iOS Keychain / Harmony 加密偏好）。

## 快速开始

```bash
# Android
cd android
cp local.properties.example local.properties   # 填 sdk.dir 与 API_BASE_URL
./gradlew :app:assembleDebug

# iOS（需 macOS + Xcode）
cd ios
cp Configs/Secrets.xcconfig.example Configs/Secrets.xcconfig
xcodegen generate                              # 或直接打开 ios/ExamMobile.xcodeproj（若已生成）
open ExamMobile.xcodeproj

# HarmonyOS（需 DevEco Studio 5.x，API 12+）
cd harmony
cp local.properties.example local.properties
# 用 DevEco Studio 打开 harmony/ 目录，配置签名后运行 entry
```

## 功能范围

考生端全功能迁移，页面清单与三端对应关系见 [docs/feature-matrix.md](docs/feature-matrix.md)。
架构见 [docs/architecture.md](docs/architecture.md)，UI 规范见 [docs/ui-spec.md](docs/ui-spec.md)，与 H5 的对齐说明见 [docs/parity.md](docs/parity.md)。

## 实现状态

- **Android**：Kotlin + Compose，完整页面与作答状态机（26 个 Kotlin 文件）。
- **iOS**：SwiftUI，XcodeGen 工程 + 完整页面（27 个 Swift 文件）。
- **HarmonyOS**：ArkTS + ArkUI，完整页面（38 个 ArkTS 文件，26 个页面）。
- 三端共用 `shared/design/tokens.json` 视觉令牌与同一套交互状态机。
- 富文本/公式：三端 WebView / WKWebView / Web + KaTeX（公共 CDN，可替换）。
- 构建全部在 GitHub Actions 云端完成，不占本地资源；首次推送由 CI 编译并暴露问题。
