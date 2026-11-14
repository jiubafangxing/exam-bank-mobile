# SECURITY.md — 密钥与凭证安全策略

本仓库是**纯客户端工程**，任何服务端密钥都不应存在于此。以下为强制红线与落地机制。

## 1. 绝对禁止进入仓库的内容

| 类别 | 示例 | 处理方式 |
|------|------|----------|
| API Key / Secret | `sk-...`、`AKIA...`、`AIza...`、`ghp_...` | 绝不入库；需要时由 CI/本地注入 |
| 官网登录账号 | 用户名、手机号、邮箱 + 密码 | **绝不入库**，仅运行时用户输入 |
| 数据库凭证 | `jdbc:...password=...`、`DB_PASSWORD` | 绝不入库（客户端本就不该有） |
| JWT / 会话 Token | `eyJ...` | 仅运行时存系统安全存储，不写日志、不写文件 |
| 证书私钥 | `BEGIN ... PRIVATE KEY`、`.p12`、`.jks` | 绝不入库，签名配置走本地 |
| 云厂商凭证 | AccessKey / SecretKey / STS | 绝不入库 |
| 内网地址/账号 | 生产库 IP + 口令组合 | 地址可放本地配置，口令绝不入库 |

## 2. 落地机制（四层）

### 第 1 层：.gitignore 广谱拦截
根 `.gitignore` 覆盖密钥扩展名、`secrets/`、`*.env`、`local.properties`、
`*.xcconfig`（仅放行 `.example`）、数据库文件、签名文件，并按
`*apikey* / *secret* / *password* / *token* / *credential* / *privatekey*`
等关键字拦截疑似文件。

### 第 2 层：pre-commit 密钥扫描
`scripts/scan-secrets.sh` 对暂存区做高熵与模式匹配，命中即阻断提交：

- 私钥头 `-----BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY-----`
- 常见 Key 前缀 `sk-`、`AKIA`、`ghp_`、`xox[baprs]-`、`AIza`、`glpat-`
- JWT `eyJ...`
- 赋值型 `password=` / `passwd=` / `api[_-]?key=` / `secret=` / `token=` 后跟疑似真实值
- 高熵随机串（Shannon 熵阈值）

安装：
```bash
bash scripts/install-git-hooks.sh
```

### 第 3 层：配置模板化
三端只提交 `*.example`；真实值在本地克隆后生成，且已被 `.gitignore` 忽略。

### 第 4 层：运行时凭证隔离
- 会话 Token 存系统安全存储：Android `EncryptedSharedPreferences`（Keystore 支撑）、
  iOS `Keychain`、Harmony `preferences` + 业务层加密；
- 登录用户名/密码不持久化；如需“记住用户名”，仅存用户名且明确可选；
- 网络层日志默认脱敏 `Authorization` 头与请求体密码字段；
- Release 构建关闭明文 HTTP、关闭调试日志。

## 3. 若已误提交

1. 立即在服务端**轮换**该密钥/口令（撤销旧值）；
2. 从工作区与历史中清除（`git filter-repo` 或 BFG）；
3. 强制推送并通知所有协作者重新克隆；
4. 复盘为何扫描未拦截，补规则到 `scripts/scan-secrets.sh`。

> 注意：从 Git 历史删除**不能**替代轮换——一旦推送过，应视为已泄露。
