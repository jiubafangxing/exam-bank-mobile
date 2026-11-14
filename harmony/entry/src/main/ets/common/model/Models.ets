// 与 Android / iOS 对齐的数据模型（字段名保持一致）
export interface User {
  id?: string;
  username?: string;
  realName?: string;
  userType?: string;
  roles?: string[];
}

export interface TenantMembership {
  tenantId?: string;
  tenantCode?: string;
  tenantName?: string;
  domain?: string;
  isDefault?: boolean;
}

export interface LoginResponse {
  token?: string;
  user?: User;
  tenantId?: string;
  tenantCode?: string;
  requiresTenantSelection?: boolean;
  tenants?: TenantMembership[];
}

export interface TenantContextView {
  tenantId?: string;
  tenantCode?: string;
  requiresTenantSelection?: boolean;
  tenants?: TenantMembership[];
}

export interface AuthMeta {
  tenantMode?: string;
  smsEnabled?: boolean;
  wechatEnabled?: boolean;
}

export interface AuthOperationResult {
  sent?: boolean;
  reset?: boolean;
  updated?: boolean;
  bound?: boolean;
  unbound?: boolean;
  authorized?: boolean;
}

export interface ExamSummary {
  id?: string;
  name?: string;
  startTime?: string;
  endTime?: string;
  durationSeconds?: number;
  status?: string;
  paperName?: string;
  totalScore?: number;
  attemptStatus?: string;
  accessMode?: string;
  orderNo?: string;
  payStatus?: string;
  score?: number;
  startEpochMillis?: string;
  endEpochMillis?: string;
  coverUrl?: string;
  intro?: string;
  tags?: string;
  displayPrice?: number;
}

export interface OpenExamSummary {
  id?: string;
  name?: string;
  status?: string;
  accessMode?: string;
  startTime?: string;
  endTime?: string;
  durationSeconds?: number;
  totalScore?: number;
  price?: number;
  orderNo?: string;
  payStatus?: string;
  eligibility?: string;
  startEpochMillis?: string;
  endEpochMillis?: string;
}

export interface ExamOption {
  key?: string;
  text?: string;
  content?: string;
}

export interface Question {
  paperQuestionId?: string;
  questionId?: string;
  type?: string;
  typeCode?: string;
  stem?: string;
  score?: number;
  sortNo?: number;
  options?: ExamOption[];
  blanks?: number;
}

export interface Answer {
  paperQuestionId?: string;
  answerJson?: string;
  answerText?: string;
  flagged?: boolean;
}

export interface AttemptState {
  attemptId?: string;
  examId?: string;
  attemptNo?: number;
  status?: string;
  startedAt?: string;
  deadlineAt?: string;
  serverTime?: string;
  examName?: string;
  paperName?: string;
  totalScore?: number;
  passScore?: number;
  durationSeconds?: number;
  questions?: Question[];
  answers?: Answer[];
  serverEpochMillis?: string;
  deadlineEpochMillis?: string;
}

export interface SaveAnswerRequest {
  answerJson?: string;
  answerText?: string;
  flagged: boolean;
}

export interface SaveAck {
  savedAt?: string;
}

export interface Heartbeat {
  serverTime?: string;
  deadlineAt?: string;
  remainingSeconds?: number;
  serverEpochMillis?: string;
  deadlineEpochMillis?: string;
}

export interface EventRequest {
  eventType: string;
  clientTime?: string;
  detail?: string;
}

export interface EventAck {
  receivedAt?: string;
  receivedEpochMillis?: string;
}

export interface SubmitResult {
  attemptId?: string;
  examId?: string;
  objectiveScore?: number;
  objectiveTotal?: number;
  subjectiveScore?: number;
  subjectiveTotal?: number;
  totalScore?: number;
  isPassed?: boolean;
  correctCount?: number;
  wrongCount?: number;
  pendingCount?: number;
  auto?: boolean;
  submittedAt?: string;
  submittedEpochMillis?: string;
}

export interface HomeItem {
  id?: string;
  title?: string;
  name?: string;
  summary?: string;
  intro?: string;
  description?: string;
  category?: string;
  coverUrl?: string;
  avatarUrl?: string;
  imageUrl?: string;
  path?: string;
  url?: string;
}

export interface HomeComponent {
  id?: string;
  componentType?: string;
  title?: string;
  items?: HomeItem[];
}

export interface Article {
  id?: string;
  title?: string;
  summary?: string;
  content?: string;
  coverUrl?: string;
  category?: string;
  createdAt?: string;
}

export interface ArticleCategory {
  id?: string;
  name?: string;
  code?: string;
}

export interface Teacher {
  id?: string;
  name?: string;
  title?: string;
  intro?: string;
  avatarUrl?: string;
}

export interface NotificationItem {
  id?: string;
  title?: string;
  content?: string;
  type?: string;
  read?: boolean;
  createdAt?: string;
}

export interface CalendarItem {
  id?: string;
  title?: string;
  date?: string;
  startTime?: string;
  endTime?: string;
  type?: string;
  examId?: string;
}

export interface AnalysisView {
  totalExams?: number;
  attendedExams?: number;
  averageScore?: number;
  avgScore?: number;
  highestScore?: number;
  lowestScore?: number;
  passRate?: number;
  studyMinutes?: number;
  weakestTypes?: string[];
  weakPoints?: string[];
  trend?: ScorePoint[];
}

export interface ScorePoint {
  label?: string;
  value?: number;
}

export interface AppealItem {
  id?: string;
  examId?: string;
  examName?: string;
  reason?: string;
  status?: string;
  reply?: string;
  createdAt?: string;
}

export interface PracticeSet {
  id?: string;
  name?: string;
  description?: string;
  questionCount?: number;
  totalScore?: number;
  category?: string;
  coverUrl?: string;
}

export interface PracticeStatistics {
  totalRecords?: number;
  finishedRecords?: number;
  averageAccuracy?: number;
  totalQuestions?: number;
  correctQuestions?: number;
}

export interface PracticeRecord {
  recordId?: string;
  setId?: string;
  setName?: string;
  title?: string;
  attemptNo?: number;
  answeredCount?: number;
  questionCount?: number;
  status?: string;
  question?: Question;
  questions?: Question[];
  answers?: Answer[];
  currentIndex?: number;
  totalQuestions?: number;
  correctCount?: number;
  wrongCount?: number;
}

export interface PracticeAnswerRequest {
  questionId: string;
  answerJson?: string;
  answerText?: string;
  elapsedMs?: number;
}

export interface WrongQuestion {
  id?: string;
  questionId?: string;
  questionType?: string;
  stem?: string;
  sourceType?: string;
  wrongCount?: number;
  mastered?: boolean;
  lastWrongAt?: string;
}

export interface ExamGroupItem {
  examId?: string;
  examName?: string;
  sortNo?: number;
  passScore?: number;
  status?: string;
}

export interface ExamGroup {
  id?: string;
  name?: string;
  description?: string;
  groupType?: string;
  passScore?: number;
  passed?: boolean;
  passedCount?: number;
  requiredCount?: number;
  examCount?: number;
  completedCount?: number;
  items?: ExamGroupItem[];
  startTime?: string;
  endTime?: string;
  status?: string;
}

export interface RankingRow {
  rank?: number;
  userId?: string;
  memberNo?: string;
  name?: string;
  avatarUrl?: string;
  levelCode?: string;
  score?: number;
  averageScore?: number;
  points?: number;
  classId?: string;
  className?: string;
  participants?: number;
  isMe?: boolean;
}

export interface ClassItem {
  id?: string;
  name?: string;
  description?: string;
  memberCount?: number;
  studentCount?: number;
  price?: number;
  joinStatus?: string;
  joinMode?: string;
  joined?: boolean;
  inviteCode?: string;
  coverUrl?: string;
}

export interface MemberProfile {
  userId?: string;
  realName?: string;
  levelName?: string;
  levelCode?: string;
  vipExpireAt?: string;
  points?: number;
  pointsBalance?: number;
  growth?: number;
  nextLevelPoints?: number;
  benefits?: string[];
}

export interface MemberLevel {
  id?: string;
  code?: string;
  name?: string;
  durationDays?: number;
  description?: string;
  price?: number;
  minPoints?: number;
  benefits?: string[];
}

export interface OrderItem {
  id?: string;
  orderNo?: string;
  bizType?: string;
  bizId?: string;
  title?: string;
  amount?: number;
  status?: string;
  createdAt?: string;
}

export interface FacePhotoStatus {
  status?: string;
  photoUrl?: string;
}

export interface FaceVerifyResult {
  result?: string;
  similarity?: number;
  verifiedAt?: string;
}

export interface FaceStatus {
  collected?: boolean;
  verified?: boolean;
  required?: boolean;
  livenessRequired?: boolean;
  photo?: FacePhotoStatus;
  latestVerify?: FaceVerifyResult;
  message?: string;
}

export interface FaceLog {
  id?: string;
  scene?: string;
  result?: string;
  livenessStatus?: string;
  similarity?: number;
  verifiedAt?: string;
  createdAt?: string;
}

export interface FaceUploadResponse {
  url?: string;
}

export interface DeviceAuthView {
  authorized?: boolean;
  deviceId?: string;
  deviceName?: string;
  message?: string;
}

export interface Envelope {
  code?: number;
  message?: string;
  data?: Object;
}

export interface ExamRouteParams {
  examId?: string;
  attemptId?: string;
  setId?: string;
  articleId?: string;
}

// 答题详情 / 成绩列表
export interface ReviewScore {
  totalScore?: number;
}

export interface ReviewQuestion {
  paperQuestionId?: string;
  correct?: boolean;
  score?: number;
  stem?: string;
  options?: ExamOption[];
  myAnswerJson?: string;
  expected?: string[];
  analysis?: string;
}

export interface AttemptReview {
  allowed?: boolean;
  policy?: string;
  score?: ReviewScore;
  questions?: ReviewQuestion[];
}

export interface ScoreRecord {
  id?: string;
  examName?: string;
  totalScore?: number;
  objectiveScore?: number;
  subjectiveScore?: number;
  status?: string;
  publishedAt?: string;
}

export interface ScorePage {
  records?: ScoreRecord[];
  total?: number;
  page?: number;
  size?: number;
}


export interface PracticeVerdict {
  correct?: boolean;
  expectedText?: string;
  analysis?: string;
}
