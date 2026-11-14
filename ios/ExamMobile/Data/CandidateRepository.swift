import Foundation

/// 考生端接口仓库（唯一接口出口）。契约由后端私有维护，仓库不含契约文档。
struct CandidateRepository {
    let client: ApiClient

    // MARK: - 认证

    func meta() async throws -> AuthMeta { try await client.get("/auth/meta") }

    func login(username: String, password: String, tenantId: String? = nil, tenantCode: String? = nil) async throws -> LoginResponse {
        try await client.post("/auth/login", body: Body.encode(LoginRequest(username: username, password: password, tenantId: tenantId, tenantCode: tenantCode)))
    }

    func sendOtp(phone: String, scene: String = "login") async throws -> AuthOperationResult {
        try await client.post("/auth/send-otp", body: Body.encode(SendOtpRequest(phone: phone, scene: scene)))
    }

    func smsLogin(phone: String, code: String, tenantId: String? = nil, tenantCode: String? = nil) async throws -> LoginResponse {
        try await client.post("/auth/login-sms", body: Body.encode(SmsLoginRequest(phone: phone, code: code, tenantId: tenantId, tenantCode: tenantCode)))
    }

    func register(username: String, password: String, realName: String, phone: String) async throws -> LoginResponse {
        try await client.post("/auth/register", body: Body.encode(RegisterRequest(username: username, password: password, realName: realName, phone: phone)))
    }

    func resetPassword(phone: String, code: String, newPassword: String) async throws -> AuthOperationResult {
        try await client.post("/auth/reset-password", body: Body.encode(ResetPasswordRequest(phone: phone, code: code, newPassword: newPassword)))
    }

    func me() async throws -> User { try await client.get("/auth/me") }

    func updateProfile(realName: String?, phone: String?, email: String?) async throws -> User {
        try await client.put("/auth/me", body: Body.encode(UpdateProfileRequest(realName: realName, phone: phone, email: email)))
    }

    func tenantContext() async throws -> TenantContextView { try await client.get("/auth/tenant-context") }

    func memberships() async throws -> [TenantMembership] { try await client.get("/auth/memberships") }

    func switchTenant(tenantId: String) async throws -> LoginResponse {
        try await client.post("/auth/switch-tenant", body: Body.encode(SwitchTenantRequest(tenantId: tenantId)))
    }

    // MARK: - 考试

    func exams(_ params: [String: String] = [:]) async throws -> [ExamSummary] { try await client.get("/exams", query: params) }

    func openExams() async throws -> [OpenExamSummary] { try await client.get("/exams/open") }

    func payOpenExam(examId: String) async throws -> OpenExamSummary { try await client.post("/exams/\(examId)/pay") }

    func startExam(examId: String, password: String? = nil, qrToken: String? = nil) async throws -> AttemptState {
        var headers: [String: String] = [:]
        if let password = password { headers["X-Exam-Password"] = password }
        if let qrToken = qrToken { headers["X-Exam-Qr-Token"] = qrToken }
        return try await client.post("/exams/\(examId)/attempts", body: nil, headers: headers)
    }

    func attempt(attemptId: String) async throws -> AttemptState { try await client.get("/attempts/\(attemptId)") }

    func saveAnswer(attemptId: String, paperQuestionId: String, body: SaveAnswerRequest) async throws -> SaveAck {
        try await client.put("/attempts/\(attemptId)/answers/\(paperQuestionId)", body: Body.encode(body))
    }

    func heartbeat(attemptId: String) async throws -> Heartbeat { try await client.post("/attempts/\(attemptId)/heartbeat") }

    func reportEvent(attemptId: String, body: EventRequest) async throws -> EventAck {
        try await client.post("/attempts/\(attemptId)/events", body: Body.encode(body))
    }

    func submit(attemptId: String) async throws -> SubmitResult { try await client.post("/attempts/\(attemptId)/submit") }

    func result(attemptId: String) async throws -> SubmitResult { try await client.get("/attempts/\(attemptId)/result") }

    func review(attemptId: String) async throws -> AttemptReview { try await client.get("/attempts/\(attemptId)/review") }

    func examRanking(examId: String) async throws -> [RankingRow] { try await client.get("/exams/\(examId)/ranking") }

    // MARK: - 成绩 / 通知 / 日历 / 分析 / 申诉

    func scores(page: Int = 1, size: Int = 20) async throws -> ScorePage {
        try await client.get("/scores", query: ["page": "\(page)", "size": "\(size)"])
    }

    func notifications() async throws -> [NotificationItem] { try await client.get("/notifications") }
    func markNotificationRead(_ id: String) async throws -> Any { try await client.postEmpty("/notifications/\(id)/read") }
    func markAllNotificationsRead() async throws -> Any { try await client.postEmpty("/notifications/read-all") }
    func calendar() async throws -> [CalendarItem] { try await client.get("/calendar") }
    func analysis() async throws -> AnalysisView { try await client.get("/analysis") }
    func appeals() async throws -> [AppealItem] { try await client.get("/appeals") }

    func createAppeal(examId: String, reason: String) async throws -> Any {
        try await client.postEmpty("/appeals", body: Body.encode(["examId": examId, "reason": reason]))
    }

    // MARK: - 练习

    func practiceSets() async throws -> [PracticeSet] { try await client.get("/practice-sets") }
    func practiceStatistics() async throws -> PracticeStatistics { try await client.get("/practice-sets/statistics") }

    func practiceStart(setId: String, password: String? = nil, qrToken: String? = nil) async throws -> PracticeRecord {
        try await client.post("/practice-sets/\(setId)/start", body: Body.encode(PracticeStartRequest(password: password, qrToken: qrToken)))
    }

    func practiceState(recordId: String) async throws -> PracticeRecord { try await client.get("/practice-sets/records/\(recordId)") }

    func practiceAnswer(recordId: String, body: PracticeAnswerRequest) async throws -> PracticeVerdict {
        try await client.post("/practice-sets/records/\(recordId)/answers", body: Body.encode(body))
    }

    func practiceFinish(recordId: String) async throws -> Any { try await client.postEmpty("/practice-sets/records/\(recordId)/finish") }
    func practiceAbandon(recordId: String) async throws -> Any { try await client.postEmpty("/practice-sets/records/\(recordId)/abandon") }

    // MARK: - 错题

    func wrongQuestions(sourceType: String? = nil, includeMastered: Bool? = nil) async throws -> [WrongQuestion] {
        var q: [String: String] = [:]
        if let sourceType = sourceType { q["sourceType"] = sourceType }
        if let includeMastered = includeMastered { q["includeMastered"] = "\(includeMastered)" }
        return try await client.get("/wrong-questions", query: q)
    }

    func masterWrong(_ rowId: String) async throws -> Any { try await client.postEmpty("/wrong-questions/\(rowId)/master") }
    func unmasterWrong(_ rowId: String) async throws -> Any { try await client.postEmpty("/wrong-questions/\(rowId)/unmaster") }

    // MARK: - 考试组 / 排行

    func examGroups() async throws -> [ExamGroup] { try await client.get("/exam-groups") }
    func examGroup(_ id: String) async throws -> Any { try await client.getRaw("/exam-groups/\(id)") }
    func pointsRanking(limit: Int = 50) async throws -> [RankingRow] { try await client.get("/rankings/points", query: ["limit": "\(limit)"]) }
    func classRanking(limit: Int = 20) async throws -> [RankingRow] { try await client.get("/rankings/classes", query: ["limit": "\(limit)"]) }

    // MARK: - 班级

    func classes(_ params: [String: String] = [:]) async throws -> [ClassItem] { try await client.get("/classes", query: params) }
    func myClasses() async throws -> [ClassItem] { try await client.get("/classes/mine") }
    func classDetail(_ id: String) async throws -> Any { try await client.getRaw("/classes/\(id)") }
    func joinClass(_ id: String, inviteCode: String? = nil, password: String? = nil) async throws -> Any {
        try await client.postEmpty("/classes/\(id)/join", body: Body.encode(JoinClassRequest(inviteCode: inviteCode, password: password)))
    }

    // MARK: - 会员 / 订单

    func memberProfile() async throws -> MemberProfile { try await client.get("/member/profile") }
    func memberLevels() async throws -> [MemberLevel] { try await client.get("/member/levels") }
    func orders() async throws -> [OrderItem] { try await client.get("/orders") }
    func createOrder(bizType: String, bizId: String) async throws -> OrderItem {
        try await client.post("/orders", body: Body.encode(CreateOrderRequest(bizType: bizType, bizId: bizId)))
    }
    func payOrder(_ id: String) async throws -> Any { try await client.postEmpty("/orders/\(id)/pay") }
    func cancelOrder(_ id: String) async throws -> Any { try await client.postEmpty("/orders/\(id)/cancel") }

    // MARK: - 内容

    func home() async throws -> [HomeComponent] { try await client.get("/home") }
    func articleCategories() async throws -> [ArticleCategory] { try await client.get("/article-categories") }
    func articles(_ params: [String: String] = [:]) async throws -> [Article] { try await client.get("/articles", query: params) }
    func article(_ id: String) async throws -> Article { try await client.get("/articles/\(id)") }
    func showcaseTeachers() async throws -> [Teacher] { try await client.get("/teachers/showcase") }

    // MARK: - 人脸 / 设备

    func faceStatus() async throws -> FaceStatus { try await client.get("/face/status") }
    func faceCollect(photoUrl: String) async throws -> Any { try await client.postEmpty("/face/collect", body: Body.encode(FaceCollectRequest(photoUrl: photoUrl))) }
    func faceVerify(_ body: FaceVerifyRequest) async throws -> Any { try await client.postEmpty("/face/verify", body: Body.encode(body)) }
    func faceLogs() async throws -> [FaceLog] { try await client.get("/face/logs") }
    func faceUpload(data: Data, filename: String = "face.jpg", mime: String = "image/jpeg") async throws -> FaceUploadResponse {
        try await client.upload("/face/upload", filename: filename, data: data, mime: mime)
    }
    func bindDevice(_ body: DeviceBindRequest) async throws -> Any { try await client.postEmpty("/auth/device/bind", body: Body.encode(body)) }
    func unbindDevice(_ deviceId: String) async throws -> Any {
        let encoded = deviceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceId
        return try await client.postEmpty("/auth/device/unbind?deviceId=\(encoded)")
    }
    func deviceAuth() async throws -> DeviceAuthView { try await client.get("/auth/device/auth") }
}
