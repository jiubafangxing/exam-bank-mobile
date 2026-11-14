# AGENTS.md — 工程约定（务必遵守）

## 0. 安全红线（最高优先级）

- **禁止**在本仓库任何文件中写入 API Key / Secret / 用户名 / 密码 / 数据库口令 /
  私钥 / JWT 真实值。真实值只放本地不入库文件。
- 仓库只提交 `*.example` 占位模板；新增配置项必须同步更新对应 `.example`。
- 提交前必须通过 `scripts/scan-secrets.sh`（pre-commit 已接入）。
- 任何打印/日志不得输出 `Authorization`、`password`、`token` 原值。

## 1. 三端各自原生，契约共享

- Android：Kotlin + Jetpack Compose，MVVM，手动 DI（`AppContainer`）。
- iOS：Swift + SwiftUI，MVVM（`ObservableObject`），async/await URLSession。
- Harmony：ArkTS + ArkUI，状态管理 `@State/@Observed`，`@ohos.net.http`。
- 接口契约由后端 `exam-bank` 私有维护，**禁止把契约文档/Schema 提交到本仓库**；
  客户端只实现调用，改动需在后端确认后再同步到客户端代码。

## 2. 统一网络约定（不记录具体契约）

- 基础地址由构建期注入（`API_BASE_URL`），源码与文档不写死任何域名/路径。
- 鉴权与会话令牌通过请求头携带，令牌存平台安全存储。
- 统一响应信封解包：业务码非成功即抛业务错误并展示服务端文案；兼容裸对象/裸数组。
- 雪花 ID 与 epoch 毫秒一律按**字符串**解析，禁止转数值（防 64 位精度丢失）。
- 未授权：清会话 → 跳登录；其余错误统一轻提示。
- **禁止**在本仓库任何文档中复述接口路径、字段清单或 Schema。

## 3. 考试作答状态机（三端必须一致）

1. 开考/续考：获取作答状态（题目、已存答案、服务器时间）。
2. 倒计时以服务器时间/截止时间为准，本地每秒递减；**每 30s** 心跳校准。
3. 答案变更 **500ms 防抖** 保存；保存状态 `pending/saving/saved/error` 可视化。
4. 切后台/失焦/回焦上报行为事件（1s 节流）。
5. 交卷前 flush 所有未保存答案；提交幂等；剩余时间归零自动交卷。
6. 答案编码：单选/判断为单元素数组，多选为多元素数组，填空按空顺序数组，问答走文本字段。

## 4. 配置与不变量

- 语言：UI 文案中文；代码标识英文。
- 主题：遵循 `shared/design/tokens.json`，主色 `#1F5F99`，背景 `#F4F6FB`。
- 平台差异只允许出现在「存储、网络实现、导航框架、原生能力（相机/人脸/推送）」层。
- 业务字段名、状态枚举、错误码三端保持一致。

## 5. 目录约定

- Android：`ui/screens` 一屏一文件；`data` 放 API；`core` 放网络/存储/配置/模型。
- iOS：`Features/<feature>/` 一功能一目录；`Core` 放网络/存储/配置/模型。
- Harmony：`pages/` 一页一文件；`common` 放网络/存储/配置/模型。
