import { ApiClient } from '../net/ApiClient';
import {
  AuthMeta, AuthOperationResult, LoginResponse, TenantMembership, TenantContextView, User,
  ExamSummary, OpenExamSummary, AttemptState, SaveAnswerRequest, SaveAck, Heartbeat,
  EventRequest, EventAck, SubmitResult, HomeComponent, Article, ArticleCategory, Teacher,
  NotificationItem, CalendarItem, AnalysisView, AppealItem, PracticeSet, PracticeStatistics,
  PracticeRecord, PracticeAnswerRequest, WrongQuestion, ExamGroup, RankingRow, ClassItem,
  MemberProfile, MemberLevel, OrderItem, FaceStatus, FaceLog, DeviceAuthView,
  AttemptReview, ScorePage, PracticeVerdict, FaceUploadResponse
} from '../model/Models';

export class CandidateRepository {
  private client: ApiClient;

  constructor(client: ApiClient) {
    this.client = client;
  }

  // 认证
  async meta(): Promise<AuthMeta> {
    return await this.client.get('/auth/meta') as AuthMeta;
  }

  async login(username: string, password: string, tenantId?: string, tenantCode?: string): Promise<LoginResponse> {
    const body = JSON.stringify({ username: username, password: password, tenantId: tenantId, tenantCode: tenantCode });
    return await this.client.post('/auth/login', body) as LoginResponse;
  }

  async sendOtp(phone: string, scene: string = 'login'): Promise<AuthOperationResult> {
    return await this.client.post('/auth/send-otp', JSON.stringify({ phone: phone, scene: scene })) as AuthOperationResult;
  }

  async smsLogin(phone: string, code: string, tenantId?: string, tenantCode?: string): Promise<LoginResponse> {
    const body = JSON.stringify({ phone: phone, code: code, tenantId: tenantId, tenantCode: tenantCode });
    return await this.client.post('/auth/login-sms', body) as LoginResponse;
  }

  async register(username: string, password: string, realName: string, phone: string): Promise<LoginResponse> {
    const body = JSON.stringify({ username: username, password: password, realName: realName, phone: phone });
    return await this.client.post('/auth/register', body) as LoginResponse;
  }

  async resetPassword(phone: string, code: string, newPassword: string): Promise<AuthOperationResult> {
    const body = JSON.stringify({ phone: phone, code: code, newPassword: newPassword });
    return await this.client.post('/auth/reset-password', body) as AuthOperationResult;
  }

  async me(): Promise<User> {
    return await this.client.get('/auth/me') as User;
  }

  async tenantContext(): Promise<TenantContextView> {
    return await this.client.get('/auth/tenant-context') as TenantContextView;
  }

  async memberships(): Promise<TenantMembership[]> {
    return await this.client.get('/auth/memberships') as TenantMembership[];
  }

  async switchTenant(tenantId: string): Promise<LoginResponse> {
    return await this.client.post('/auth/switch-tenant', JSON.stringify({ tenantId: tenantId })) as LoginResponse;
  }

  // 考试
  async exams(): Promise<ExamSummary[]> {
    return await this.client.get('/exams') as ExamSummary[];
  }

  async openExams(): Promise<OpenExamSummary[]> {
    return await this.client.get('/exams/open') as OpenExamSummary[];
  }

  async payOpenExam(examId: string): Promise<OpenExamSummary> {
    return await this.client.post('/exams/' + examId + '/pay') as OpenExamSummary;
  }

  async startExam(examId: string, password?: string, qrToken?: string): Promise<AttemptState> {
    const headers = new Map<string, string>();
    if (password) headers.set('X-Exam-Password', password);
    if (qrToken) headers.set('X-Exam-Qr-Token', qrToken);
    return await this.client.post('/exams/' + examId + '/attempts', undefined, headers) as AttemptState;
  }

  async attempt(attemptId: string): Promise<AttemptState> {
    return await this.client.get('/attempts/' + attemptId) as AttemptState;
  }

  async saveAnswer(attemptId: string, paperQuestionId: string, body: SaveAnswerRequest): Promise<SaveAck> {
    return await this.client.put('/attempts/' + attemptId + '/answers/' + paperQuestionId, JSON.stringify(body)) as SaveAck;
  }

  async heartbeat(attemptId: string): Promise<Heartbeat> {
    return await this.client.post('/attempts/' + attemptId + '/heartbeat') as Heartbeat;
  }

  async reportEvent(attemptId: string, body: EventRequest): Promise<EventAck> {
    return await this.client.post('/attempts/' + attemptId + '/events', JSON.stringify(body)) as EventAck;
  }

  async submit(attemptId: string): Promise<SubmitResult> {
    return await this.client.post('/attempts/' + attemptId + '/submit') as SubmitResult;
  }

  async result(attemptId: string): Promise<SubmitResult> {
    return await this.client.get('/attempts/' + attemptId + '/result') as SubmitResult;
  }

  async review(attemptId: string): Promise<AttemptReview> {
    return await this.client.get('/attempts/' + attemptId + '/review') as AttemptReview;
  }

  // 成绩 / 通知 / 日历 / 分析 / 申诉
  async scores(page: number = 1, size: number = 20): Promise<ScorePage> {
    const query = new Map<string, string>();
    query.set('page', String(page));
    query.set('size', String(size));
    return await this.client.get('/scores', query) as ScorePage;
  }

  async notifications(): Promise<NotificationItem[]> {
    return await this.client.get('/notifications') as NotificationItem[];
  }

  async markNotificationRead(id: string): Promise<Object> {
    return await this.client.post('/notifications/' + id + '/read');
  }

  async markAllNotificationsRead(): Promise<Object> {
    return await this.client.post('/notifications/read-all');
  }

  async calendar(): Promise<CalendarItem[]> {
    return await this.client.get('/calendar') as CalendarItem[];
  }

  async analysis(): Promise<AnalysisView> {
    return await this.client.get('/analysis') as AnalysisView;
  }

  async appeals(): Promise<AppealItem[]> {
    return await this.client.get('/appeals') as AppealItem[];
  }

  async createAppeal(examId: string, reason: string): Promise<Object> {
    return await this.client.post('/appeals', JSON.stringify({ examId: examId, reason: reason }));
  }

  // 练习
  async practiceSets(): Promise<PracticeSet[]> {
    return await this.client.get('/practice-sets') as PracticeSet[];
  }

  async practiceStatistics(): Promise<PracticeStatistics> {
    return await this.client.get('/practice-sets/statistics') as PracticeStatistics;
  }

  async practiceStart(setId: string): Promise<PracticeRecord> {
    return await this.client.post('/practice-sets/' + setId + '/start', JSON.stringify({})) as PracticeRecord;
  }

  async practiceAnswer(recordId: string, body: PracticeAnswerRequest): Promise<PracticeVerdict> {
    return await this.client.post('/practice-sets/records/' + recordId + '/answers', JSON.stringify(body)) as PracticeVerdict;
  }

  async practiceFinish(recordId: string): Promise<Object> {
    return await this.client.post('/practice-sets/records/' + recordId + '/finish');
  }

  // 错题
  async wrongQuestions(includeMastered: boolean = false): Promise<WrongQuestion[]> {
    const query = new Map<string, string>();
    query.set('includeMastered', includeMastered ? 'true' : 'false');
    return await this.client.get('/wrong-questions', query) as WrongQuestion[];
  }

  async masterWrong(rowId: string): Promise<Object> {
    return await this.client.post('/wrong-questions/' + rowId + '/master');
  }

  async unmasterWrong(rowId: string): Promise<Object> {
    return await this.client.post('/wrong-questions/' + rowId + '/unmaster');
  }

  // 考试组 / 排行
  async examGroups(): Promise<ExamGroup[]> {
    return await this.client.get('/exam-groups') as ExamGroup[];
  }

  async pointsRanking(limit: number = 50): Promise<RankingRow[]> {
    const query = new Map<string, string>();
    query.set('limit', String(limit));
    return await this.client.get('/rankings/points', query) as RankingRow[];
  }

  async classRanking(limit: number = 20): Promise<RankingRow[]> {
    const query = new Map<string, string>();
    query.set('limit', String(limit));
    return await this.client.get('/rankings/classes', query) as RankingRow[];
  }

  // 班级
  async myClasses(): Promise<ClassItem[]> {
    return await this.client.get('/classes/mine') as ClassItem[];
  }

  async classes(params?: Map<string, string>): Promise<ClassItem[]> {
    return await this.client.get('/classes', params) as ClassItem[];
  }

  async joinClass(id: string, password?: string): Promise<Object> {
    return await this.client.post('/classes/' + id + '/join', JSON.stringify({ password: password }));
  }

  // 会员 / 订单
  async memberProfile(): Promise<MemberProfile> {
    return await this.client.get('/member/profile') as MemberProfile;
  }

  async memberLevels(): Promise<MemberLevel[]> {
    return await this.client.get('/member/levels') as MemberLevel[];
  }

  async orders(): Promise<OrderItem[]> {
    return await this.client.get('/orders') as OrderItem[];
  }

  async createOrder(bizType: string, bizId: string): Promise<OrderItem> {
    return await this.client.post('/orders', JSON.stringify({ bizType: bizType, bizId: bizId })) as OrderItem;
  }

  async payOrder(id: string): Promise<Object> {
    return await this.client.post('/orders/' + id + '/pay');
  }

  async cancelOrder(id: string): Promise<Object> {
    return await this.client.post('/orders/' + id + '/cancel');
  }

  // 内容
  async home(): Promise<HomeComponent[]> {
    return await this.client.get('/home') as HomeComponent[];
  }

  async articles(): Promise<Article[]> {
    return await this.client.get('/articles') as Article[];
  }

  async article(id: string): Promise<Article> {
    return await this.client.get('/articles/' + id) as Article;
  }

  async articleCategories(): Promise<ArticleCategory[]> {
    return await this.client.get('/article-categories') as ArticleCategory[];
  }

  async showcaseTeachers(): Promise<Teacher[]> {
    return await this.client.get('/teachers/showcase') as Teacher[];
  }

  // 人脸 / 设备
  async faceStatus(): Promise<FaceStatus> {
    return await this.client.get('/face/status') as FaceStatus;
  }

  async faceCollect(photoUrl: string): Promise<Object> {
    return await this.client.post('/face/collect', JSON.stringify({ photoUrl: photoUrl }));
  }

  async faceVerify(photoUrl?: string, examId?: string, livenessStatus?: string): Promise<Object> {
    return await this.client.post('/face/verify', JSON.stringify({ photoUrl: photoUrl, examId: examId, livenessStatus: livenessStatus }));
  }

  async faceUpload(data: ArrayBuffer, filename: string = 'face.jpg'): Promise<FaceUploadResponse> {
    return await this.client.postMultipart('/face/upload', data, filename) as FaceUploadResponse;
  }

  async faceLogs(): Promise<FaceLog[]> {
    return await this.client.get('/face/logs') as FaceLog[];
  }

  async bindDevice(deviceId: string, deviceName: string, deviceType: string): Promise<Object> {
    return await this.client.post('/auth/device/bind', JSON.stringify({ deviceId: deviceId, deviceName: deviceName, deviceType: deviceType }));
  }

  async unbindDevice(deviceId: string): Promise<Object> {
    return await this.client.post('/auth/device/unbind?deviceId=' + encodeURIComponent(deviceId));
  }

  async deviceAuth(): Promise<DeviceAuthView> {
    return await this.client.get('/auth/device/auth') as DeviceAuthView;
  }
}

export const repo: CandidateRepository = new CandidateRepository(new ApiClient());
