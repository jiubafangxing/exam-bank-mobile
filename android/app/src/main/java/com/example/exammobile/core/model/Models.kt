package com.example.exammobile.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

val AppJson: Json = Json {
    ignoreUnknownKeys = true
    isLenient = true
    explicitNulls = false
    coerceInputValues = true
}

// ---------------- 认证 ----------------

@Serializable
data class User(
    val id: String = "",
    val username: String = "",
    val realName: String = "",
    val userType: String = "",
    val roles: List<String> = emptyList()
)

@Serializable
data class TenantMembership(
    val tenantId: String = "",
    val tenantCode: String = "",
    val tenantName: String = "",
    val domain: String? = null,
    val isDefault: Boolean? = null
)

@Serializable
data class LoginResponse(
    val token: String = "",
    val user: User = User(),
    val tenantId: String? = null,
    val tenantCode: String? = null,
    val requiresTenantSelection: Boolean? = null,
    val tenants: List<TenantMembership>? = null
)

@Serializable
data class TenantContextView(
    val tenantId: String? = null,
    val tenantCode: String? = null,
    val requiresTenantSelection: Boolean = false,
    val tenants: List<TenantMembership> = emptyList()
)

@Serializable
data class AuthMeta(
    val tenantMode: String = "SILO",
    val smsEnabled: Boolean = false,
    val wechatEnabled: Boolean = false
)

@Serializable
data class AuthOperationResult(
    val sent: Boolean? = null,
    val reset: Boolean? = null,
    val updated: Boolean? = null,
    val bound: Boolean? = null,
    val unbound: Boolean? = null,
    val authorized: Boolean? = null
)

// ---------------- 考试 ----------------

@Serializable
data class ExamSummary(
    val id: String = "",
    val name: String = "",
    val startTime: String? = null,
    val endTime: String? = null,
    val durationSeconds: Int = 0,
    val status: String = "",
    val paperName: String? = null,
    val totalScore: Double? = null,
    val attemptStatus: String = "",
    val accessMode: String? = null,
    val campaignCode: String? = null,
    val orderNo: String? = null,
    val payStatus: String? = null,
    val score: Double? = null,
    val startEpochMillis: String = "0",
    val endEpochMillis: String = "0",
    val coverUrl: String? = null,
    val intro: String? = null,
    val tags: String? = null,
    val displayPrice: Double? = null
)

@Serializable
data class OpenExamSummary(
    val id: String = "",
    val name: String = "",
    val status: String = "",
    val accessMode: String = "",
    val startTime: String? = null,
    val endTime: String? = null,
    val durationSeconds: Int = 0,
    val totalScore: Double? = null,
    val price: Double? = null,
    val orderNo: String? = null,
    val payStatus: String = "UNPAID",
    val eligibility: String = "",
    val startEpochMillis: String = "0",
    val endEpochMillis: String = "0"
)

@Serializable
data class Option(val key: String = "", val text: String = "", val content: String? = null)

@Serializable
data class Question(
    val paperQuestionId: String = "",
    val questionId: String = "",
    val type: String = "",
    val typeCode: String? = null,
    val stem: String = "",
    val score: Double = 0.0,
    val sortNo: Int = 0,
    val options: List<Option> = emptyList(),
    val blanks: Int = 0
)

@Serializable
data class Answer(
    val paperQuestionId: String = "",
    val answerJson: String? = null,
    val answerText: String? = null,
    val flagged: Boolean = false
)

@Serializable
data class AttemptState(
    val attemptId: String = "",
    val examId: String = "",
    val attemptNo: Int = 1,
    val status: String = "",
    val startedAt: String? = null,
    val deadlineAt: String? = null,
    val serverTime: String? = null,
    val examName: String = "",
    val paperName: String? = null,
    val totalScore: Double? = null,
    val passScore: Double? = null,
    val durationSeconds: Int = 0,
    val questions: List<Question> = emptyList(),
    val answers: List<Answer> = emptyList(),
    val serverEpochMillis: String = "0",
    val deadlineEpochMillis: String = "0"
)

@Serializable
data class SaveAnswerRequest(
    val answerJson: String? = null,
    val answerText: String? = null,
    val flagged: Boolean = false
)

@Serializable
data class SaveAck(val savedAt: String? = null)

@Serializable
data class Heartbeat(
    val serverTime: String? = null,
    val deadlineAt: String? = null,
    val remainingSeconds: Int = 0,
    val serverEpochMillis: String = "0",
    val deadlineEpochMillis: String = "0"
)

@Serializable
data class EventRequest(
    val eventType: String,
    val clientTime: String? = null,
    val detail: String? = null
)

@Serializable
data class EventAck(
    val receivedAt: String? = null,
    val receivedEpochMillis: String? = null
)

@Serializable
data class SubmitResult(
    val attemptId: String = "",
    val examId: String = "",
    val objectiveScore: Double = 0.0,
    val objectiveTotal: Double = 0.0,
    val subjectiveScore: Double = 0.0,
    val subjectiveTotal: Double = 0.0,
    val totalScore: Double = 0.0,
    val isPassed: Boolean? = null,
    val correctCount: Int = 0,
    val wrongCount: Int = 0,
    val pendingCount: Int = 0,
    val auto: Boolean = false,
    val submittedAt: String? = null,
    val submittedEpochMillis: String? = null
)

// ---------------- 通用列表/内容 ----------------

@Serializable
data class PageResponse<T>(
    val records: List<T> = emptyList(),
    val total: Long = 0,
    val page: Int = 1,
    val size: Int = 20
)

@Serializable
data class HomeComponent(
    val id: String? = null,
    val componentType: String = "",
    val title: String? = null,
    val items: List<HomeItem> = emptyList()
)

@Serializable
data class HomeItem(
    val id: String? = null,
    val title: String? = null,
    val name: String? = null,
    val summary: String? = null,
    val intro: String? = null,
    val description: String? = null,
    val category: String? = null,
    val coverUrl: String? = null,
    val avatarUrl: String? = null,
    val imageUrl: String? = null,
    val path: String? = null,
    val url: String? = null
)

@Serializable
data class Article(
    val id: String = "",
    val title: String = "",
    val summary: String? = null,
    val content: String? = null,
    val coverUrl: String? = null,
    val category: String? = null,
    val createdAt: String? = null
)

@Serializable
data class ArticleCategory(val id: String = "", val name: String = "", val code: String? = null)

@Serializable
data class Teacher(
    val id: String = "",
    val name: String = "",
    val title: String? = null,
    val intro: String? = null,
    val avatarUrl: String? = null
)

@Serializable
data class NotificationItem(
    val id: String = "",
    val title: String = "",
    val content: String? = null,
    val type: String? = null,
    val read: Boolean = false,
    val createdAt: String? = null
)

@Serializable
data class CalendarItem(
    val id: String = "",
    val title: String = "",
    val date: String? = null,
    val startTime: String? = null,
    val endTime: String? = null,
    val type: String? = null,
    val examId: String? = null
)

@Serializable
data class AnalysisView(
    val totalExams: Int = 0,
    val attendedExams: Int? = null,
    val averageScore: Double = 0.0,
    val avgScore: Double? = null,
    val highestScore: Double = 0.0,
    val lowestScore: Double? = null,
    val passRate: Double = 0.0,
    val studyMinutes: Int = 0,
    val weakestTypes: List<String> = emptyList(),
    val weakPoints: List<String> = emptyList(),
    val trend: List<ScorePoint> = emptyList()
)

@Serializable
data class ScorePoint(val label: String = "", val value: Double = 0.0)

@Serializable
data class AppealItem(
    val id: String = "",
    val examId: String? = null,
    val examName: String? = null,
    val reason: String? = null,
    val status: String = "",
    val reply: String? = null,
    val createdAt: String? = null
)

// ---------------- 练习 ----------------

@Serializable
data class PracticeSet(
    val id: String = "",
    val name: String = "",
    val description: String? = null,
    val questionCount: Int = 0,
    val totalScore: Double? = null,
    val category: String? = null,
    val coverUrl: String? = null
)

@Serializable
data class PracticeStatistics(
    val totalRecords: Int = 0,
    val finishedRecords: Int = 0,
    val averageAccuracy: Double = 0.0,
    val totalQuestions: Int = 0,
    val correctQuestions: Int = 0
)

@Serializable
data class PracticeStartRequest(val password: String? = null, val qrToken: String? = null)

@Serializable
data class PracticeRecord(
    val recordId: String = "",
    val setId: String = "",
    val setName: String = "",
    val title: String? = null,
    val attemptNo: Int? = null,
    val answeredCount: Int? = null,
    val questionCount: Int? = null,
    val status: String = "",
    val question: Question? = null,
    val questions: List<Question> = emptyList(),
    val answers: List<Answer> = emptyList(),
    val currentIndex: Int = 0,
    val totalQuestions: Int = 0,
    val correctCount: Int = 0,
    val wrongCount: Int = 0
)

@Serializable
data class PracticeAnswerRequest(
    val questionId: String,
    val answerJson: String? = null,
    val answerText: String? = null,
    val elapsedMs: Long? = null
)

@Serializable
data class WrongQuestion(
    val id: String = "",
    val questionId: String = "",
    val questionType: String? = null,
    val stem: String? = null,
    val sourceType: String? = null,
    val wrongCount: Int = 0,
    val mastered: Boolean = false,
    val lastWrongAt: String? = null
)

// ---------------- 考试组 / 排行 ----------------

@Serializable
data class ExamGroup(
    val id: String = "",
    val name: String = "",
    val description: String? = null,
    val groupType: String? = null,
    val passScore: Double? = null,
    val passed: Boolean? = null,
    val passedCount: Int? = null,
    val requiredCount: Int? = null,
    val examCount: Int = 0,
    val completedCount: Int = 0,
    val items: List<ExamGroupItem> = emptyList(),
    val startTime: String? = null,
    val endTime: String? = null,
    val status: String? = null
)

@Serializable
data class ExamGroupItem(
    val examId: String = "",
    val examName: String? = null,
    val sortNo: Int = 0,
    val passScore: Double? = null,
    val status: String = ""
)

@Serializable
data class RankingRow(
    val rank: Int = 0,
    val userId: String? = null,
    val memberNo: String? = null,
    val name: String = "",
    val avatarUrl: String? = null,
    val levelCode: String? = null,
    val score: Double? = null,
    val averageScore: Double? = null,
    val points: Int? = null,
    val classId: String? = null,
    val className: String? = null,
    val participants: Int? = null,
    val isMe: Boolean = false
)

// ---------------- 班级 ----------------

@Serializable
data class ClassItem(
    val id: String = "",
    val name: String = "",
    val description: String? = null,
    val memberCount: Int = 0,
    val studentCount: Int? = null,
    val price: Double? = null,
    val joinStatus: String? = null,
    val joinMode: String? = null,
    val joined: Boolean = false,
    val inviteCode: String? = null,
    val coverUrl: String? = null
)

@Serializable
data class JoinClassRequest(val inviteCode: String? = null, val password: String? = null)

// ---------------- 会员 / 订单 ----------------

@Serializable
data class MemberProfile(
    val userId: String = "",
    val realName: String? = null,
    val levelName: String = "",
    val levelCode: String? = null,
    val vipExpireAt: String? = null,
    val points: Int = 0,
    val pointsBalance: Int? = null,
    val growth: Int = 0,
    val nextLevelPoints: Int? = null,
    val benefits: List<String> = emptyList()
)

@Serializable
data class MemberLevel(
    val id: String = "",
    val code: String = "",
    val name: String = "",
    val durationDays: Int? = null,
    val description: String? = null,
    val price: Double? = null,
    val minPoints: Int = 0,
    val benefits: List<String> = emptyList()
)

@Serializable
data class OrderItem(
    val id: String = "",
    val orderNo: String = "",
    val bizType: String = "",
    val bizId: String? = null,
    val title: String? = null,
    val amount: Double = 0.0,
    val status: String = "",
    val createdAt: String? = null
)

@Serializable
data class CreateOrderRequest(val bizType: String, val bizId: String)

// ---------------- 人脸 / 设备 ----------------

@Serializable
data class FaceStatus(
    val collected: Boolean = false,
    val verified: Boolean = false,
    val required: Boolean = false,
    val livenessRequired: Boolean? = null,
    val photo: FacePhotoStatus? = null,
    val latestVerify: FaceVerifyResult? = null,
    val message: String? = null
)

@Serializable
data class FacePhotoStatus(val status: String? = null, val photoUrl: String? = null)

@Serializable
data class FaceVerifyResult(val result: String? = null, val similarity: Double? = null, val verifiedAt: String? = null)

@Serializable
data class FaceCollectRequest(val photoUrl: String)

@Serializable
data class FaceVerifyRequest(
    val photoUrl: String? = null,
    val examId: String? = null,
    val livenessStatus: String? = null,
    val livenessToken: String? = null,
    val scene: String? = null
)

@Serializable
data class FaceLog(
    val id: String = "",
    val scene: String? = null,
    val result: String? = null,
    val livenessStatus: String? = null,
    val similarity: Double? = null,
    val verifiedAt: String? = null,
    val createdAt: String? = null
)

@Serializable
data class FaceUploadResponse(val url: String = "")

@Serializable
data class DeviceBindRequest(
    val deviceId: String,
    val deviceName: String? = null,
    val deviceType: String? = null
)

@Serializable
data class DeviceAuthView(
    val authorized: Boolean = false,
    val deviceId: String? = null,
    val deviceName: String? = null,
    val message: String? = null
)

// ---------------- 请求体 ----------------

@Serializable
data class LoginRequest(
    val username: String,
    val password: String,
    val tenantId: String? = null,
    val tenantCode: String? = null
)

@Serializable
data class RegisterRequest(
    val username: String,
    val password: String,
    val realName: String? = null,
    val phone: String? = null,
    val email: String? = null,
    val idCard: String? = null,
    val tenantId: String? = null
)

@Serializable
data class SendOtpRequest(val phone: String, val scene: String = "login")

@Serializable
data class SmsLoginRequest(
    val phone: String,
    val code: String,
    val tenantId: String? = null,
    val tenantCode: String? = null
)

@Serializable
data class ResetPasswordRequest(val phone: String, val code: String, val newPassword: String)

@Serializable
data class SwitchTenantRequest(val tenantId: String)

@Serializable
data class WechatCodeLoginRequest(
    val code: String,
    val tenantId: String? = null,
    val tenantCode: String? = null,
    val inviteCode: String? = null,
    val appId: String? = null,
    val nickname: String? = null
)

@Serializable
data class UpdateProfileRequest(
    val realName: String? = null,
    val phone: String? = null,
    val email: String? = null
)

// ---------------- 答题详情 / 成绩列表 ----------------

@Serializable
data class ReviewScore(val totalScore: Double? = null)

@Serializable
data class ReviewQuestion(
    val paperQuestionId: String = "",
    val correct: Boolean? = null,
    val score: Double? = null,
    val stem: String? = null,
    val options: List<Option> = emptyList(),
    val myAnswerJson: String? = null,
    val expected: List<String> = emptyList(),
    val analysis: String? = null
)

@Serializable
data class ReviewView(
    val allowed: Boolean = true,
    val policy: String? = null,
    val score: ReviewScore? = null,
    val questions: List<ReviewQuestion> = emptyList()
)

@Serializable
data class ScoreRecord(
    val id: String = "",
    val examName: String? = null,
    val totalScore: Double? = null,
    val objectiveScore: Double? = null,
    val subjectiveScore: Double? = null,
    val status: String? = null,
    val publishedAt: String? = null
)

@Serializable
data class ScorePage(
    val records: List<ScoreRecord> = emptyList(),
    val total: Long = 0,
    val page: Int = 1,
    val size: Int = 20
)


@Serializable
data class PracticeVerdict(
    val correct: Boolean? = null,
    val expectedText: String? = null,
    val analysis: String? = null
)
