import Foundation
import Combine

struct LocalAnswer: Equatable {
    var answerJson: String?
    var answerText: String = ""
    var flagged: Bool = false
}

/// 作答状态机：开考/续考 → 逐题防抖保存 → 30s 心跳 → 交卷（自动/手动）。
final class ExamTakingViewModel: ObservableObject {
    @Published var state: UiState<AttemptState> = .loading
    @Published var currentIndex = 0
    @Published var remaining = 0
    @Published var answers: [String: LocalAnswer] = [:]
    @Published var fillValues: [String: [String]] = [:]
    @Published var saveStatus: [String: String] = [:]
    @Published var submitting = false
    @Published var toast: String?
    @Published var submittedAttemptId: String?

    let examId: String
    private let repository: CandidateRepository

    private var countdownTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var debounceTasks: [String: Task<Void, Never>] = [:]
    private var localDeadline = Date()
    private var autoSubmitting = false
    private var lastEvent: [String: Date] = [:]

    init(examId: String, repository: CandidateRepository) {
        self.examId = examId
        self.repository = repository
    }

    var attempt: AttemptState? { state.value }
    var questions: [Question] { attempt?.questions ?? [] }
    var currentQuestion: Question? { questions.indices.contains(currentIndex) ? questions[currentIndex] : nil }

    @MainActor
    func load() async {
        state = .loading
        do {
            let data = try await repository.startExam(examId: examId)
            apply(data)
            if data.status == "SUBMITTED" || data.status == "GRADED" {
                submittedAttemptId = data.attemptId
                return
            }
            state = .success(data)
            startTimers()
            reportEvent("FOCUS", "exam-loaded")
        } catch {
            state = .failure((error as? ApiError)?.errorDescription ?? "加载考试失败")
        }
    }

    private func apply(_ data: AttemptState) {
        var ans: [String: LocalAnswer] = [:]
        var fills: [String: [String]] = [:]
        for q in data.questions ?? [] {
            let id = q.paperQuestionId ?? ""
            ans[id] = LocalAnswer()
            if q.type == "FILL" { fills[id] = Array(repeating: "", count: max(q.blanks ?? 1, 1)) }
        }
        for a in data.answers ?? [] {
            let id = a.paperQuestionId ?? ""
            ans[id] = LocalAnswer(answerJson: a.answerJson, answerText: a.answerText ?? "", flagged: a.flagged ?? false)
            if let q = (data.questions ?? []).first(where: { $0.paperQuestionId == id }), q.type == "FILL" {
                fills[id] = parseArray(a.answerJson, length: max(q.blanks ?? 1, 1))
            }
            saveStatus[id] = "saved"
        }
        answers = ans
        fillValues = fills
        let remain = (Int(data.deadlineEpochMillis ?? "0") ?? 0) - (Int(data.serverEpochMillis ?? "0") ?? 0)
        remaining = max(remain / 1000, 0)
        localDeadline = Date().addingTimeInterval(TimeInterval(remaining))
    }

    private func parseArray(_ value: String?, length: Int) -> [String] {
        var result = Array(repeating: "", count: length)
        guard let value = value, let data = value.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [Any] else { return result }
        for (i, item) in arr.enumerated() where i < length {
            result[i] = String(describing: item)
        }
        return result
    }

    private func encodeArray(_ values: [String]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: values)) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    // MARK: - 作答交互

    func answer(of question: Question) -> LocalAnswer {
        answers[question.paperQuestionId ?? ""] ?? LocalAnswer()
    }

    func selectedKeys(_ question: Question) -> [String] {
        guard let raw = answer(of: question).answerJson, let data = raw.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [Any] else { return [] }
        return arr.map { String(describing: $0) }
    }

    func isSelected(_ question: Question, _ key: String) -> Bool {
        selectedKeys(question).contains(key)
    }

    func isAnswered(_ question: Question) -> Bool {
        switch question.type {
        case "ESSAY": return !answer(of: question).answerText.isEmpty
        case "FILL": return (fillValues[question.paperQuestionId ?? ""] ?? []).contains { !$0.isEmpty }
        default: return !selectedKeys(question).isEmpty
        }
    }

    func choose(_ question: Question, _ key: String) {
        var keys = selectedKeys(question)
        if question.type == "MULTIPLE" {
            if let i = keys.firstIndex(of: key) { keys.remove(at: i) } else { keys.append(key) }
        } else {
            keys = [key]
        }
        update(question, LocalAnswer(answerJson: encodeArray(keys), answerText: answer(of: question).answerText, flagged: answer(of: question).flagged))
    }

    func updateFill(_ question: Question, index: Int, value: String) {
        let id = question.paperQuestionId ?? ""
        var list = fillValues[id] ?? Array(repeating: "", count: max(question.blanks ?? 1, 1))
        if list.indices.contains(index) { list[index] = value }
        fillValues[id] = list
        var a = answer(of: question)
        a.answerJson = encodeArray(list)
        update(question, a)
    }

    func updateEssay(_ question: Question, text: String) {
        var a = answer(of: question)
        a.answerText = text
        update(question, a)
    }

    func toggleFlag(_ question: Question) {
        var a = answer(of: question)
        a.flagged.toggle()
        update(question, a)
    }

    private func update(_ question: Question, _ answer: LocalAnswer) {
        answers[question.paperQuestionId ?? ""] = answer
        queueSave(question)
    }

    func jump(to index: Int) {
        guard questions.indices.contains(index) else { return }
        currentIndex = index
    }

    // MARK: - 防抖保存

    private func queueSave(_ question: Question) {
        let id = question.paperQuestionId ?? ""
        saveStatus[id] = "pending"
        debounceTasks[id]?.cancel()
        debounceTasks[id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: AppConfig.debounceSaveMs * 1_000_000)
            guard !Task.isCancelled else { return }
            await self?.saveNow(question)
        }
    }

    @MainActor
    private func saveNow(_ question: Question) async {
        guard let attempt = attempt else { return }
        let id = question.paperQuestionId ?? ""
        saveStatus[id] = "saving"
        let a = answer(of: question)
        do {
            _ = try await repository.saveAnswer(
                attemptId: attempt.attemptId ?? "",
                paperQuestionId: id,
                body: SaveAnswerRequest(answerJson: a.answerJson, answerText: a.answerText.isEmpty ? nil : a.answerText, flagged: a.flagged)
            )
            saveStatus[id] = "saved"
        } catch {
            saveStatus[id] = "error"
        }
    }

    @MainActor
    private func flushAll() async {
        for q in questions where saveStatus[q.paperQuestionId ?? ""] != "saved" {
            await saveNow(q)
        }
    }

    // MARK: - 计时 / 心跳

    @MainActor
    private func startTimers() {
        stopTimers()
        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self else { return }
                let remain = Int(self.localDeadline.timeIntervalSinceNow)
                self.remaining = max(remain, 0)
                if remain <= 0 && !self.autoSubmitting {
                    self.autoSubmitting = true
                    await self.submit(auto: true)
                }
            }
        }
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: AppConfig.heartbeatSeconds * 1_000_000_000)
                guard let self = self, let attempt = self.attempt else { return }
                if let hb = try? await self.repository.heartbeat(attemptId: attempt.attemptId ?? "") {
                    self.remaining = hb.remainingSeconds ?? self.remaining
                    self.localDeadline = Date().addingTimeInterval(TimeInterval(hb.remainingSeconds ?? 0))
                }
            }
        }
    }

    @MainActor
    private func stopTimers() {
        countdownTask?.cancel(); countdownTask = nil
        heartbeatTask?.cancel(); heartbeatTask = nil
    }

    // MARK: - 交卷

    func askSubmit() { toast = nil; submitting = false; pendingConfirm = true }
    @Published var pendingConfirm = false

    @MainActor
    func submit(auto: Bool) async {
        guard let attempt = attempt, !submitting else { return }
        submitting = true
        defer { submitting = false }
        debounceTasks.values.forEach { $0.cancel() }
        await flushAll()
        do {
            _ = try await repository.submit(attemptId: attempt.attemptId ?? "")
            stopTimers()
            submittedAttemptId = attempt.attemptId
        } catch {
            autoSubmitting = false
            toast = "交卷失败，请重试：" + ((error as? ApiError)?.errorDescription ?? "")
        }
    }

    // MARK: - 行为事件

    @MainActor
    func reportEvent(_ type: String, _ detail: String) {
        guard let attempt = attempt else { return }
        let now = Date()
        if let last = lastEvent[type], now.timeIntervalSince(last) * 1000 < Double(AppConfig.eventThrottleMs) { return }
        lastEvent[type] = now
        let body = EventRequest(eventType: type, clientTime: String(Int(now.timeIntervalSince1970 * 1000)), detail: detail)
        Task { [weak self] in
            _ = try? await self?.repository.reportEvent(attemptId: attempt.attemptId ?? "", body: body)
        }
    }

    deinit {
        countdownTask?.cancel()
        heartbeatTask?.cancel()
        debounceTasks.values.forEach { $0.cancel() }
    }
}
