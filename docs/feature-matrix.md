# 功能矩阵 — 考生端全功能迁移

三端（Android / iOS / HarmonyOS）逐项对应，UI 结构一致（见 `docs/ui-spec.md`）。
> 说明：本文件只描述**功能范围**，不记录任何后端接口路径、字段或契约细节。

图例：✅ 已实现　◐ 已接线/基础版　○ 预留

| # | 功能 | Web 对应视图 | Android | iOS | Harmony |
|---|------|--------------|:------:|:---:|:-------:|
| 1 | 登录（账号密码） | LoginView | ✅ | ✅ | ✅ |
| 2 | 短信验证码登录 | SmsLoginView | ✅ | ✅ | ✅ |
| 3 | 注册 | RegisterView | ✅ | ✅ | ✅ |
| 4 | 重置密码 | ResetPasswordView | ✅ | ✅ | ✅ |
| 5 | 租户选择/切换 | SelectTenantView | ✅ | ✅ | ✅ |
| 6 | 登录能力探测（短信开关等） | — | ✅ | ✅ | ✅ |
| 7 | 首页组件（Banner/导航/列表） | HomeView | ✅ | ✅ | ✅ |
| 8 | 我的资料 | ProfileView | ✅ | ✅ | ✅ |
| 9 | 考试列表 | ExamListView | ✅ | ✅ | ✅ |
| 10 | 开放考试（付费报名） | ExamListView | ✅ | ✅ | ✅ |
| 11 | 开考/续考 | ExamTakingView | ✅ | ✅ | ✅ |
| 12 | 在线作答（5 题型/防抖保存/心跳/事件） | ExamTakingView | ✅ | ✅ | ✅ |
| 13 | 交卷 | ExamTakingView | ✅ | ✅ | ✅ |
| 14 | 成绩结果 | ResultView | ✅ | ✅ | ✅ |
| 15 | 成绩列表 | ScoreView | ✅ | ✅ | ✅ |
| 16 | 答案解析/回看 | AnswerReviewView | ✅ | ✅ | ✅ |
| 17 | 练习列表/统计 | PracticeListView/StatsView | ✅ | ✅ | ✅ |
| 18 | 在线练习作答 | PracticeTakingView | ✅ | ✅ | ✅ |
| 19 | 错题集（掌握/取消） | WrongListView | ✅ | ✅ | ✅ |
| 20 | 考试组 | ExamGroupListView | ✅ | ✅ | ✅ |
| 21 | 排行榜（积分/班级） | RankingView | ✅ | ✅ | ✅ |
| 22 | 考试排行榜 | — | ✅ | ✅ | ✅ |
| 23 | 班级列表/详情/加入 | ClassListView | ✅ | ✅ | ✅ |
| 24 | 会员中心/等级 | MemberCenterView | ✅ | ✅ | ✅ |
| 25 | 订单（创建/支付/取消） | MemberCenterView | ✅ | ✅ | ✅ |
| 26 | 内容/文章/分类 | ArticleListView/DetailView | ✅ | ✅ | ✅ |
| 27 | 教师风采 | TeacherShowcaseView | ✅ | ✅ | ✅ |
| 28 | 消息通知（已读） | NotificationView | ✅ | ✅ | ✅ |
| 29 | 考试日历 | CalendarView | ✅ | ✅ | ✅ |
| 30 | 个人分析 | AnalysisView | ✅ | ✅ | ✅ |
| 31 | 成绩申诉 | AppealView | ✅ | ✅ | ✅ |
| 32 | 人脸核验（拍照上传/采集/活体/比对/日志） | FaceVerifyView | ✅ | ✅ | ✅ |
| 33 | 设备管理（绑定/解绑） | DeviceView | ✅ | ✅ | ✅ |

说明：
- 富文本题干/选项/解析/文章：三端均使用 WebView / WKWebView / Web 组件渲染 HTML，并通过 KaTeX 渲染 `$...$` / `$$...$$` 公式，与 H5 `RichContent` 对齐。KaTeX 资源默认走公共 CDN（jsdelivr），可替换为国内镜像或随包内置；**不涉及后端域名**。
- 练习逐题判定（对错/正确答案/解析）、考试组展开明细、班级搜索/筛选/密码/付费/审核加入、会员等级购买与订单取消、人脸拍照上传/活体/相似度日志均已实现。
- 人脸核验的相机/相册调用为各端原生能力：Android 系统图片选择器、iOS PhotosPicker、HarmonyOS PhotoViewPicker。
- 微信一键登录仅在小程序/开放平台具备；原生 App 保留能力封装与预留入口。
