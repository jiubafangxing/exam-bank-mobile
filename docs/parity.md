# 与 H5 考生端的功能对齐说明

对照 `exam-bank/web-candidate`（29 个视图）逐项实现，三端（Android / iOS / HarmonyOS）保持一致。

## 1. 已完全对齐

- **认证**：账号密码登录、短信登录、注册、重置密码、多租户选择/切换、个人中心「修改密码」入口。
- **首页**：问候语、8 个快捷入口、Banner / NAV / 列表组件、可配置的「考试报名」外部入口。
- **考试**：列表筛选、开放报名与支付、开考/续考、5 种题型作答、500ms 防抖保存、30s 心跳、前后台事件、答题卡、标记、自动/手动交卷、成绩页、**结构化答题详情**（正确/错误/待阅卷、我的答案、正确答案、解析、展示策略）。
- **成绩**：分页列表（考试名、总分、客观/主观、发布状态、发布时间、加载更多）。
- **练习**：题集列表、统计、**逐题判定**（对错 / 正确答案 / 解析 / 下一题）、错题集（掌握/取消）。
- **考试组**：通关/闯关、及格线、已通关/进度、每场状态（已通过/未通过/可参加/未解锁/成绩未发布）。
- **排行榜**：积分榜（level、points）、班级榜（participants、averageScore）。
- **班级**：搜索、免费/付费筛选、排序（价格升/降、人数、最新）、免费/密码/付费/审核四种加入方式、封面、审核中状态。
- **会员**：资料、VIP 到期、积分为余额、等级列表、**等级购买（下单+支付）**、订单支付/取消。
- **内容**：文章列表/详情（富文本）、教师风采、首页组件。
- **其它**：消息通知（单条/全部已读）、考试日历、个人分析（总/已参加/平均分/及格率/最低最高/薄弱知识点/趋势）、成绩申诉、人脸核验（拍照上传/采集/活体/相似度日志）、设备绑定/解绑。
- **富文本**：题干、选项、解析、文章支持 HTML 与 KaTeX 公式（`$...$`、`$$...$$`、`\(...\)`、`\[...\]`）。

## 2. 平台实现差异（不影响功能一致性）

| 能力 | Android | iOS | HarmonyOS |
|------|---------|-----|-----------|
| 富文本/公式 | WebView + KaTeX | WKWebView + KaTeX | Web + KaTeX |
| 图片选择 | `ActivityResultContracts.GetContent` | `PhotosPicker` | `PhotoViewPicker` |
| 上传 | OkHttp multipart | URLSession multipart | `http` + ArrayBuffer multipart |
| 会话存储 | EncryptedSharedPreferences | Keychain | preferences |
| 导航 | Navigation Compose | NavigationStack | `@ohos.router` |

KaTeX 资源默认走公共 CDN（`cdn.jsdelivr.net`），**不涉及后端域名**；可替换为国内镜像或随包内置。

## 3. 已知非功能差异 / 可选

- **考试报名**：H5 使用相对路径 `/registration/`；原生需通过 `REGISTRATION_URL` 配置绝对地址，未配置时隐藏入口。
- **导出**：H5 封装了 `accountExport` / `examsExport`，但视图未使用；原生未提供入口。
- **扫码开考**：H5 可通过 URL query `code` 携带 QR token；原生未做扫码深链。
- **性能**：答题详情每道题一个 WebView/Web 组件，题量很大时建议改为折叠/懒加载。
- **视觉细节**：H5 使用 Vant 组件、原生使用平台控件，存在细微外观差异；三端彼此保持一致（见 `docs/ui-spec.md`）。

## 4. 构建验证

三端均通过 GitHub Actions 在云端编译，不在本地消耗 CPU/内存。首次运行会暴露编译期差异，需按日志修复。
