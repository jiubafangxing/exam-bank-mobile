# CI/CD — 全部在 GitHub Actions 云端构建

> 目标：**本地不跑编译**，三端构建、产物归档全部交给 GitHub 托管 runner，
> 不消耗本地 CPU/内存。公开仓库的托管 runner 免费。

## 1. 三条流水线

| 工作流 | Runner | 产物 | 说明 |
|--------|--------|------|------|
| `.github/workflows/android.yml` | `ubuntu-latest` | `app-debug.apk` | AGP + Gradle，Java 17 |
| `.github/workflows/ios.yml` | `macos-14` | `*.app`（模拟器，免签名） | XcodeGen + xcodebuild |
| `.github/workflows/harmony.yml` | `ubuntu-latest` | `*.hap`（debug，免签名） | `ErBWs/setup-ohos` 装 hvigor/ohpm/SDK |
| `.github/workflows/ci.yml` | `ubuntu-latest` | — | 密钥扫描 + 脚本语法 |

触发：push 到 `main`、PR、或手动 `workflow_dispatch`。

## 2. 配置：域名放 Secrets（公开仓库关键点）

**公开仓库**下，`vars`（Variables）可能被 fork 的 PR 工作流读取并用于外带；
而 `secrets` 不会传给 fork PR。因此域名等构建配置放 **Secrets**，工作流里：

```yaml
API_BASE_URL: ${{ secrets.API_BASE_URL || vars.API_BASE_URL }}
```

并设置 `QUIET=1`，`scripts/inject-config.sh` 在 CI 下**不打印域名原值**，避免公开日志泄露。

需要配置的 Secrets（Settings → Secrets and variables → Actions → Secrets）：

| 名称 | 必填 | 说明 |
|------|:---:|------|
| `API_BASE_URL` | ✅ | 考试端后端地址，如 `https://<host>/api` |
| `ANDROID_KEYSTORE_BASE64` | 发布签名时 | jks 的 base64（发布流水线用） |
| `ANDROID_KEYSTORE_PASSWORD` | 发布签名时 | keystore 口令 |
| `ANDROID_KEY_ALIAS` | 发布签名时 | 别名 |
| `ANDROID_KEY_PASSWORD` | 发布签名时 | key 口令 |
| `HARMONY_P12_BASE64` 等 | 发布签名时 | 鸿蒙签名材料 |

非敏感的构建开关可放 Variables：`API_ALLOW_CLEARTEXT`、`ANDROID_APP_ID`、`REGISTRATION_URL`（可选，考试报名外部入口）、
`IOS_BUNDLE_ID`、`HARMONY_BUNDLE_NAME`、`HARMONY_CLI_VERSION`。

> 严禁把 API Key、官网登录账号密码、数据库口令放进任何 Variables/Secrets 之外的
> 文件或日志；本仓库只需要后端域名，客户端不应持有任何服务端密钥。

## 3. 不在本机构建

- 文档中的本地命令仅用于**打开工程/调试**；
- 日常验证与出包一律 `git push` 触发 Actions，或 `workflow_dispatch` 手动触发；
- 若本机已安装 `gh`：`gh workflow run build-android.yml`（只提交任务，编译在云端）。

## 4. 发布签名（可选，后续开启）

Debug 产物免签名即可安装验证。正式发布再增加签名步骤：
- Android：CI 中 `base64 -d` 还原 keystore → `signingConfigs` 读取环境变量；
- iOS：导入 `.p12` + provisioning profile 到临时 keychain，`xcodebuild archive/export`；
- Harmony：`build-profile.json5` 的 `signingConfigs` 指向 CI 临时材料。

所有签名材料只经 Secrets 注入，构建结束后随 runner 销毁，不入库、不打印。
