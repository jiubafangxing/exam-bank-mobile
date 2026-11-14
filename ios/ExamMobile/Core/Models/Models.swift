import Foundation

// MARK: - 认证

struct User: Codable, Identifiable, Equatable {
    var id: String?
    var username: String?
    var realName: String?
    var userType: String?
    var roles: [String]?
    var displayName: String { (realName?.isEmpty == false ? realName : username) ?? "同学" }
}

struct TenantMembership: Codable, Identifiable, Hashable {
    var tenantId: String?
    var tenantCode: String?
    var tenantName: String?
    var domain: String?
    var isDefault: Bool?
    var id: String { tenantId ?? tenantCode ?? UUID().uuidString }
}

struct LoginResponse: Codable {
    var token: String?
    var user: User?
    var tenantId: String?
    var tenantCode: String?
    var requiresTenantSelection: Bool?
    var tenants: [TenantMembership]?
}

struct TenantContextView: Codable {
    var tenantId: String?
    var tenantCode: String?
    var requiresTenantSelection: Bool?
    var tenants: [TenantMembership]?
}

struct AuthMeta: Codable {
    var tenantMode: String?
    var smsEnabled: Bool?
    var wechatEnabled: Bool?
}

struct AuthOperationResult: Codable {
    var sent: Bool?
    var reset: Bool?
    var updated: Bool?
    var bound: Bool?
    var unbound: Bool?
    var authorized: Bool?
}

// MARK: - 请求体

struct LoginRequest: Codable {
    var username: String
    var password: String
    var tenantId: String?
    var tenantCode: String?
}

struct RegisterRequest: Codable {
    var username: String
    var password: String
    var realName: String?
    var phone: String?
    var email: String?
    var idCard: String?
    var tenantId: String?
}

struct SendOtpRequest: Codable {
    var phone: String
    var scene: String
}

struct SmsLoginRequest: Codable {
    var phone: String
    var code: String
    var tenantId: String?
    var tenantCode: String?
}

struct ResetPasswordRequest: Codable {
    var phone: String
    var code: String
    var newPassword: String
}

struct SwitchTenantRequest: Codable {
    var tenantId: String
}

struct UpdateProfileRequest: Codable {
    var realName: String?
    var phone: String?
    var email: String?
}

// MARK: - 考试

struct ExamSummary: Codable, Identifiable {
    var id: String?
    var name: String?
    var startTime: String?
    var endTime: String?
    var durationSeconds: Int?
    var status: String?
    var paperName: String?
    var totalScore: Double?
    var attemptStatus: String?
    var accessMode: String?
    var campaignCode: String?
    var orderNo: String?
    var payStatus: String?
    var score: Double?
    var startEpochMillis: String?
    var endEpochMillis: String?
    var coverUrl: String?
    var intro: String?
    var tags: String?
    var displayPrice: Double?
}

struct OpenExamSummary: Codable, Identifiable {
    var id: String?
    var name: String?
    var status: String?
    var accessMode: String?
    var startTime: String?
    var endTime: String?
    var durationSeconds: Int?
    var totalScore: Double?
    var price: Double?
    var orderNo: String?
    var payStatus: String?
    var eligibility: String?
    var startEpochMillis: String?
    var endEpochMillis: String?
}

struct ExamOption: Codable, Hashable {
    var key: String?
    var text: String?
    var content: String?
}

struct Question: Codable, Identifiable {
    var paperQuestionId: String?
    var questionId: String?
    var type: String?
    var typeCode: String?
    var stem: String?
    var score: Double?
    var sortNo: Int?
    var options: [ExamOption]?
    var blanks: Int?
    var id: String { paperQuestionId ?? questionId ?? UUID().uuidString }
}

struct Answer: Codable {
    var paperQuestionId: String?
    var answerJson: String?
    var answerText: String?
    var flagged: Bool?
}

struct AttemptState: Codable {
    var attemptId: String?
    var examId: String?
    var attemptNo: Int?
    var status: String?
    var startedAt: String?
    var deadlineAt: String?
    var serverTime: String?
    var examName: String?
    var paperName: String?
    var totalScore: Double?
    var passScore: Double?
    var durationSeconds: Int?
    var questions: [Question]?
    var answers: [Answer]?
    var serverEpochMillis: String?
    var deadlineEpochMillis: String?
}

struct SaveAnswerRequest: Codable {
    var answerJson: String?
    var answerText: String?
    var flagged: Bool
}

struct SaveAck: Codable {
    var savedAt: String?
}

struct Heartbeat: Codable {
    var serverTime: String?
    var deadlineAt: String?
    var remainingSeconds: Int?
    var serverEpochMillis: String?
    var deadlineEpochMillis: String?
}

struct EventRequest: Codable {
    var eventType: String
    var clientTime: String?
    var detail: String?
}

struct EventAck: Codable {
    var receivedAt: String?
    var receivedEpochMillis: String?
}

struct SubmitResult: Codable {
    var attemptId: String?
    var examId: String?
    var objectiveScore: Double?
    var objectiveTotal: Double?
    var subjectiveScore: Double?
    var subjectiveTotal: Double?
    var totalScore: Double?
    var isPassed: Bool?
    var correctCount: Int?
    var wrongCount: Int?
    var pendingCount: Int?
    var auto: Bool?
    var submittedAt: String?
    var submittedEpochMillis: String?
}

// MARK: - 内容 / 首页

struct HomeComponent: Codable, Identifiable {
    var id: String?
    var componentType: String?
    var title: String?
    var items: [HomeItem]?
}

struct HomeItem: Codable, Identifiable {
    var id: String?
    var title: String?
    var name: String?
    var summary: String?
    var intro: String?
    var description: String?
    var category: String?
    var coverUrl: String?
    var avatarUrl: String?
    var imageUrl: String?
    var path: String?
    var url: String?
}

struct Article: Codable, Identifiable {
    var id: String?
    var title: String?
    var summary: String?
    var content: String?
    var coverUrl: String?
    var category: String?
    var createdAt: String?
}

struct ArticleCategory: Codable, Identifiable {
    var id: String?
    var name: String?
    var code: String?
}

struct Teacher: Codable, Identifiable {
    var id: String?
    var name: String?
    var title: String?
    var intro: String?
    var avatarUrl: String?
}

struct NotificationItem: Codable, Identifiable {
    var id: String?
    var title: String?
    var content: String?
    var type: String?
    var read: Bool?
    var createdAt: String?
}

struct CalendarItem: Codable, Identifiable {
    var id: String?
    var title: String?
    var date: String?
    var startTime: String?
    var endTime: String?
    var type: String?
    var examId: String?
}

struct AnalysisView: Codable {
    var totalExams: Int?
    var attendedExams: Int?
    var averageScore: Double?
    var avgScore: Double?
    var highestScore: Double?
    var lowestScore: Double?
    var passRate: Double?
    var studyMinutes: Int?
    var weakestTypes: [String]?
    var weakPoints: [String]?
    var trend: [ScorePoint]?
}

struct ScorePoint: Codable, Identifiable {
    var label: String?
    var value: Double?
    var id: String { label ?? UUID().uuidString }
}

struct AppealItem: Codable, Identifiable {
    var id: String?
    var examId: String?
    var examName: String?
    var reason: String?
    var status: String?
    var reply: String?
    var createdAt: String?
}

// MARK: - 练习 / 错题

struct PracticeSet: Codable, Identifiable {
    var id: String?
    var name: String?
    var description: String?
    var questionCount: Int?
    var totalScore: Double?
    var category: String?
    var coverUrl: String?
}

struct PracticeStatistics: Codable {
    var totalRecords: Int?
    var finishedRecords: Int?
    var averageAccuracy: Double?
    var totalQuestions: Int?
    var correctQuestions: Int?
}

struct PracticeStartRequest: Codable {
    var password: String?
    var qrToken: String?
}

struct PracticeRecord: Codable {
    var recordId: String?
    var setId: String?
    var setName: String?
    var title: String?
    var attemptNo: Int?
    var answeredCount: Int?
    var questionCount: Int?
    var status: String?
    var question: Question?
    var questions: [Question]?
    var answers: [Answer]?
    var currentIndex: Int?
    var totalQuestions: Int?
    var correctCount: Int?
    var wrongCount: Int?
}

struct PracticeAnswerRequest: Codable {
    var questionId: String
    var answerJson: String?
    var answerText: String?
    var elapsedMs: Int?
}

struct WrongQuestion: Codable, Identifiable {
    var id: String?
    var questionId: String?
    var questionType: String?
    var stem: String?
    var sourceType: String?
    var wrongCount: Int?
    var mastered: Bool?
    var lastWrongAt: String?
}

// MARK: - 考试组 / 排行 / 班级

struct ExamGroupItem: Codable, Identifiable {
    var examId: String?
    var examName: String?
    var sortNo: Int?
    var passScore: Double?
    var status: String?
    var id: String { examId ?? UUID().uuidString }
}

struct ExamGroup: Codable, Identifiable {
    var id: String?
    var name: String?
    var description: String?
    var groupType: String?
    var passScore: Double?
    var passed: Bool?
    var passedCount: Int?
    var requiredCount: Int?
    var examCount: Int?
    var completedCount: Int?
    var items: [ExamGroupItem]?
    var startTime: String?
    var endTime: String?
    var status: String?
}

struct RankingRow: Codable, Identifiable {
    var rank: Int?
    var userId: String?
    var memberNo: String?
    var name: String?
    var avatarUrl: String?
    var levelCode: String?
    var score: Double?
    var averageScore: Double?
    var points: Int?
    var classId: String?
    var className: String?
    var participants: Int?
    var isMe: Bool?
    var id: String { userId ?? classId ?? UUID().uuidString }
}

struct ClassItem: Codable, Identifiable {
    var id: String?
    var name: String?
    var description: String?
    var memberCount: Int?
    var studentCount: Int?
    var price: Double?
    var joinStatus: String?
    var joinMode: String?
    var joined: Bool?
    var inviteCode: String?
    var coverUrl: String?
}

struct JoinClassRequest: Codable {
    var inviteCode: String?
    var password: String?
}

// MARK: - 会员 / 订单

struct MemberProfile: Codable {
    var userId: String?
    var realName: String?
    var levelName: String?
    var levelCode: String?
    var vipExpireAt: String?
    var points: Int?
    var pointsBalance: Int?
    var growth: Int?
    var nextLevelPoints: Int?
    var benefits: [String]?
}

struct MemberLevel: Codable, Identifiable {
    var id: String?
    var code: String?
    var name: String?
    var durationDays: Int?
    var description: String?
    var price: Double?
    var minPoints: Int?
    var benefits: [String]?
    var key: String { id ?? code ?? name ?? UUID().uuidString }
}

struct OrderItem: Codable, Identifiable {
    var id: String?
    var orderNo: String?
    var bizType: String?
    var bizId: String?
    var title: String?
    var amount: Double?
    var status: String?
    var createdAt: String?
}

struct CreateOrderRequest: Codable {
    var bizType: String
    var bizId: String
}

// MARK: - 人脸 / 设备

struct FacePhotoStatus: Codable {
    var status: String?
    var photoUrl: String?
}

struct FaceVerifyResult: Codable {
    var result: String?
    var similarity: Double?
    var verifiedAt: String?
}

struct FaceStatus: Codable {
    var collected: Bool?
    var verified: Bool?
    var required: Bool?
    var livenessRequired: Bool?
    var photo: FacePhotoStatus?
    var latestVerify: FaceVerifyResult?
    var message: String?
}

struct FaceCollectRequest: Codable {
    var photoUrl: String
}

struct FaceVerifyRequest: Codable {
    var photoUrl: String?
    var examId: String?
    var livenessStatus: String?
    var livenessToken: String?
    var scene: String?
}

struct FaceLog: Codable, Identifiable {
    var id: String?
    var scene: String?
    var result: String?
    var livenessStatus: String?
    var similarity: Double?
    var verifiedAt: String?
    var createdAt: String?
}

struct FaceUploadResponse: Codable {
    var url: String?
}

struct DeviceBindRequest: Codable {
    var deviceId: String
    var deviceName: String?
    var deviceType: String?
}

struct DeviceAuthView: Codable {
    var authorized: Bool?
    var deviceId: String?
    var deviceName: String?
    var message: String?
}

// MARK: - 答题详情 / 成绩列表

struct ReviewScore: Codable {
    var totalScore: Double?
}

struct ReviewQuestion: Codable, Identifiable {
    var paperQuestionId: String?
    var correct: Bool?
    var score: Double?
    var stem: String?
    var options: [ExamOption]?
    var myAnswerJson: String?
    var expected: [String]?
    var analysis: String?
    var id: String { paperQuestionId ?? UUID().uuidString }
}

struct AttemptReview: Codable {
    var allowed: Bool?
    var policy: String?
    var score: ReviewScore?
    var questions: [ReviewQuestion]?
}

struct ScoreRecord: Codable, Identifiable {
    var id: String?
    var examName: String?
    var totalScore: Double?
    var objectiveScore: Double?
    var subjectiveScore: Double?
    var status: String?
    var publishedAt: String?
}

struct ScorePage: Codable {
    var records: [ScoreRecord]?
    var total: Int?
    var page: Int?
    var size: Int?
}


struct PracticeVerdict: Codable {
    var correct: Bool?
    var expectedText: String?
    var analysis: String?
}
