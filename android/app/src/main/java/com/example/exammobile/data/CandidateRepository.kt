package com.example.exammobile.data

import com.example.exammobile.core.model.*
import com.example.exammobile.core.network.ApiClient
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.decodeFromJsonElement
import java.io.File

/**
 * 考生端接口仓库（唯一接口出口）。
 * 具体契约由后端私有维护，仓库内不保留契约文档。
 */
class CandidateRepository(private val api: ApiClient) {

    private inline fun <reified T> JsonElement.decode(): T =
        AppJson.decodeFromJsonElement<T>(this)

    private inline fun <reified T> JsonElement.decodeList(): List<T> =
        AppJson.decodeFromJsonElement<List<T>>(this)

    // ---------------- 认证 ----------------

    suspend fun meta(): AuthMeta = api.get("/auth/meta").decode()

    suspend fun login(username: String, password: String, tenantId: String? = null, tenantCode: String? = null): LoginResponse =
        api.post("/auth/login", AppJson.encodeToString(LoginRequest.serializer(), LoginRequest(username, password, tenantId, tenantCode))).decode()

    suspend fun sendOtp(phone: String, scene: String = "login"): AuthOperationResult =
        api.post("/auth/send-otp", AppJson.encodeToString(SendOtpRequest.serializer(), SendOtpRequest(phone, scene))).decode()

    suspend fun smsLogin(phone: String, code: String, tenantId: String? = null, tenantCode: String? = null): LoginResponse =
        api.post("/auth/login-sms", AppJson.encodeToString(SmsLoginRequest.serializer(), SmsLoginRequest(phone, code, tenantId, tenantCode))).decode()

    suspend fun register(username: String, password: String, realName: String, phone: String): LoginResponse =
        api.post("/auth/register", AppJson.encodeToString(RegisterRequest.serializer(), RegisterRequest(username, password, realName, phone))).decode()

    suspend fun resetPassword(phone: String, code: String, newPassword: String): AuthOperationResult =
        api.post("/auth/reset-password", AppJson.encodeToString(ResetPasswordRequest.serializer(), ResetPasswordRequest(phone, code, newPassword))).decode()

    suspend fun me(): User = api.get("/auth/me").decode()

    suspend fun updateProfile(realName: String?, phone: String?, email: String?): User =
        api.put("/auth/me", AppJson.encodeToString(UpdateProfileRequest.serializer(), UpdateProfileRequest(realName, phone, email))).decode()

    suspend fun tenantContext(): TenantContextView = api.get("/auth/tenant-context").decode()

    suspend fun memberships(): List<TenantMembership> = api.get("/auth/memberships").decodeList()

    suspend fun switchTenant(tenantId: String): LoginResponse =
        api.post("/auth/switch-tenant", AppJson.encodeToString(SwitchTenantRequest.serializer(), SwitchTenantRequest(tenantId))).decode()

    // ---------------- 考试 ----------------

    suspend fun exams(params: Map<String, String?> = emptyMap()): List<ExamSummary> =
        api.get("/exams", params).decodeList()

    suspend fun openExams(): List<OpenExamSummary> = api.get("/exams/open").decodeList()

    suspend fun payOpenExam(examId: String): OpenExamSummary = api.post("/exams/$examId/pay").decode()

    suspend fun startExam(examId: String, password: String? = null, qrToken: String? = null): AttemptState {
        val headers = buildMap {
            password?.let { put("X-Exam-Password", it) }
            qrToken?.let { put("X-Exam-Qr-Token", it) }
        }
        return api.post("/exams/$examId/attempts", null, headers).decode()
    }

    suspend fun attempt(attemptId: String): AttemptState = api.get("/attempts/$attemptId").decode()

    suspend fun saveAnswer(attemptId: String, paperQuestionId: String, body: SaveAnswerRequest): SaveAck =
        api.put("/attempts/$attemptId/answers/$paperQuestionId", AppJson.encodeToString(SaveAnswerRequest.serializer(), body)).decode()

    suspend fun heartbeat(attemptId: String): Heartbeat = api.post("/attempts/$attemptId/heartbeat").decode()

    suspend fun reportEvent(attemptId: String, body: EventRequest): EventAck =
        api.post("/attempts/$attemptId/events", AppJson.encodeToString(EventRequest.serializer(), body)).decode()

    suspend fun submit(attemptId: String): SubmitResult = api.post("/attempts/$attemptId/submit").decode()

    suspend fun result(attemptId: String): SubmitResult = api.get("/attempts/$attemptId/result").decode()

    suspend fun review(attemptId: String): ReviewView = api.get("/attempts/$attemptId/review").decode()

    suspend fun examRanking(examId: String): List<RankingRow> = api.get("/exams/$examId/ranking").decodeList()

    // ---------------- 成绩 / 通知 / 日历 / 分析 / 申诉 ----------------

    suspend fun scores(page: Int = 1, size: Int = 20): ScorePage =
        api.get("/scores", mapOf("page" to "$page", "size" to "$size")).decode()

    suspend fun notifications(): List<NotificationItem> = api.get("/notifications").decodeList()

    suspend fun markNotificationRead(id: String): AuthOperationResult = api.post("/notifications/$id/read").decode()

    suspend fun markAllNotificationsRead(): AuthOperationResult = api.post("/notifications/read-all").decode()

    suspend fun calendar(): List<CalendarItem> = api.get("/calendar").decodeList()

    suspend fun analysis(): AnalysisView = api.get("/analysis").decode()

    suspend fun appeals(): List<AppealItem> = api.get("/appeals").decodeList()

    suspend fun createAppeal(body: JsonElement): AppealItem =
        api.post("/appeals", AppJson.encodeToString(JsonElement.serializer(), body)).decode()

    // ---------------- 练习 ----------------

    suspend fun practiceSets(): List<PracticeSet> = api.get("/practice-sets").decodeList()

    suspend fun practiceStatistics(): PracticeStatistics = api.get("/practice-sets/statistics").decode()

    suspend fun practiceStart(setId: String, password: String? = null, qrToken: String? = null): PracticeRecord =
        api.post("/practice-sets/$setId/start", AppJson.encodeToString(PracticeStartRequest.serializer(), PracticeStartRequest(password, qrToken))).decode()

    suspend fun practiceState(recordId: String): PracticeRecord = api.get("/practice-sets/records/$recordId").decode()

    suspend fun practiceAnswer(recordId: String, body: PracticeAnswerRequest): PracticeVerdict =
        api.post("/practice-sets/records/$recordId/answers", AppJson.encodeToString(PracticeAnswerRequest.serializer(), body)).decode()

    suspend fun practiceFinish(recordId: String): JsonElement = api.post("/practice-sets/records/$recordId/finish")

    suspend fun practiceAbandon(recordId: String): JsonElement = api.post("/practice-sets/records/$recordId/abandon")

    // ---------------- 错题 ----------------

    suspend fun wrongQuestions(sourceType: String? = null, includeMastered: Boolean? = null): List<WrongQuestion> =
        api.get("/wrong-questions", buildMap {
            sourceType?.let { put("sourceType", it) }
            includeMastered?.let { put("includeMastered", it.toString()) }
        }).decodeList()

    suspend fun masterWrong(rowId: String): JsonElement = api.post("/wrong-questions/$rowId/master")

    suspend fun unmasterWrong(rowId: String): JsonElement = api.post("/wrong-questions/$rowId/unmaster")

    // ---------------- 考试组 / 排行 ----------------

    suspend fun examGroups(): List<ExamGroup> = api.get("/exam-groups").decodeList()

    suspend fun examGroup(id: String): JsonElement = api.get("/exam-groups/$id")

    suspend fun pointsRanking(limit: Int = 50): List<RankingRow> =
        api.get("/rankings/points", mapOf("limit" to "$limit")).decodeList()

    suspend fun classRanking(limit: Int = 20): List<RankingRow> =
        api.get("/rankings/classes", mapOf("limit" to "$limit")).decodeList()

    // ---------------- 班级 ----------------

    suspend fun classes(params: Map<String, String?> = emptyMap()): List<ClassItem> =
        api.get("/classes", params).decodeList()

    suspend fun myClasses(): List<ClassItem> = api.get("/classes/mine").decodeList()

    suspend fun classDetail(id: String): JsonElement = api.get("/classes/$id")

    suspend fun joinClass(id: String, inviteCode: String? = null, password: String? = null): JsonElement =
        api.post("/classes/$id/join", AppJson.encodeToString(JoinClassRequest.serializer(), JoinClassRequest(inviteCode, password)))

    // ---------------- 会员 / 订单 ----------------

    suspend fun memberProfile(): MemberProfile = api.get("/member/profile").decode()

    suspend fun memberLevels(): List<MemberLevel> = api.get("/member/levels").decodeList()

    suspend fun orders(): List<OrderItem> = api.get("/orders").decodeList()

    suspend fun createOrder(bizType: String, bizId: String): OrderItem =
        api.post("/orders", AppJson.encodeToString(CreateOrderRequest.serializer(), CreateOrderRequest(bizType, bizId))).decode()

    suspend fun payOrder(orderId: String): JsonElement = api.post("/orders/$orderId/pay")

    suspend fun cancelOrder(orderId: String): JsonElement = api.post("/orders/$orderId/cancel")

    // ---------------- 内容 ----------------

    suspend fun home(): List<HomeComponent> = api.get("/home").decodeList()

    suspend fun articleCategories(): List<ArticleCategory> = api.get("/article-categories").decodeList()

    suspend fun articles(params: Map<String, String?> = emptyMap()): List<Article> =
        api.get("/articles", params).decodeList()

    suspend fun article(id: String): Article = api.get("/articles/$id").decode()

    suspend fun showcaseTeachers(): List<Teacher> = api.get("/teachers/showcase").decodeList()

    // ---------------- 人脸 / 设备 ----------------

    suspend fun faceStatus(): FaceStatus = api.get("/face/status").decode()

    suspend fun faceCollect(photoUrl: String): JsonElement =
        api.post("/face/collect", AppJson.encodeToString(FaceCollectRequest.serializer(), FaceCollectRequest(photoUrl)))

    suspend fun faceVerify(body: FaceVerifyRequest): JsonElement =
        api.post("/face/verify", AppJson.encodeToString(FaceVerifyRequest.serializer(), body))

    suspend fun faceLogs(): List<FaceLog> = api.get("/face/logs").decodeList()

    suspend fun faceUpload(file: File): FaceUploadResponse = api.postMultipart("/face/upload", file).decode()

    suspend fun bindDevice(body: DeviceBindRequest): JsonElement =
        api.post("/auth/device/bind", AppJson.encodeToString(DeviceBindRequest.serializer(), body))

    suspend fun unbindDevice(deviceId: String): JsonElement =
        api.post("/auth/device/unbind?deviceId=${java.net.URLEncoder.encode(deviceId, "UTF-8")}")

    suspend fun deviceAuth(): DeviceAuthView = api.get("/auth/device/auth").decode()
}
