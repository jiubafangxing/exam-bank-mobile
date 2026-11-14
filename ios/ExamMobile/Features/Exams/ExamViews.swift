import SwiftUI

enum ExamFilter: String, CaseIterable {
    case all = "全部"
    case ongoing = "进行中"
    case finished = "已结束"
    case open = "开放报名"
}

struct ExamListView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var filter: ExamFilter = .all
    @State private var reload = 0
    @State private var toast: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ExamFilter.allCases, id: \.self) { item in
                        Button { filter = item } label: {
                            Text(item.rawValue)
                                .font(.system(size: 13))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(filter == item ? Tokens.primary : Tokens.surface)
                                .foregroundColor(filter == item ? .white : Tokens.textSecondary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            if filter == .open {
                RemoteContent(
                    loader: { try await env.repository.openExams() },
                    emptyCheck: { $0.isEmpty }
                ) { list in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(list) { exam in openCard(exam) }
                        }
                        .padding(16)
                    }
                }
                .id(reload)
            } else {
                RemoteContent(
                    loader: { try await env.repository.exams() },
                    emptyCheck: { filtered($0).isEmpty }
                ) { list in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(filtered(list)) { exam in examCard(exam) }
                        }
                        .padding(16)
                    }
                }
                .id(reload)
            }
        }
        .pageBackground()
        .navigationTitle("我的考试")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
    }

    private func filtered(_ list: [ExamSummary]) -> [ExamSummary] {
        switch filter {
        case .ongoing:
            return list.filter { ["STARTED", "IN_PROGRESS", "ASSIGNED"].contains($0.attemptStatus ?? "") }
        case .finished:
            return list.filter { ["SUBMITTED", "GRADING", "GRADED", "EXPIRED", "ABSENT"].contains($0.attemptStatus ?? "") }
        default:
            return list
        }
    }

    @ViewBuilder
    private func examCard(_ exam: ExamSummary) -> some View {
        NavigationLink(value: Route.examTaking(exam.id ?? "")) {
            SectionCard {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(exam.name ?? "").font(.system(size: 16, weight: .semibold)).foregroundColor(Tokens.textPrimary).lineLimit(1)
                        Spacer()
                        TagPill(
                            text: Formatters.attemptStatusLabel(exam.attemptStatus),
                            fg: ["STARTED", "IN_PROGRESS"].contains(exam.attemptStatus ?? "") ? Tokens.primary : Tokens.textSecondary,
                            bg: ["STARTED", "IN_PROGRESS"].contains(exam.attemptStatus ?? "") ? Tokens.primarySoft : Tokens.surfaceAlt
                        )
                    }
                    if let paper = exam.paperName, !paper.isEmpty {
                        Text(paper).font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
                    }
                    HStack(spacing: 16) {
                        Text(Formatters.epochToDateTime(exam.startEpochMillis)).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                        Text(Formatters.durationText(exam.durationSeconds)).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                        if let score = exam.score {
                            Text("得分 \(Formatters.scoreText(score))").font(.system(size: 12)).foregroundColor(Tokens.primary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func openCard(_ exam: OpenExamSummary) -> some View {
        SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exam.name ?? "").font(.system(size: 16, weight: .semibold))
                    Text("\(Formatters.epochToDateTime(exam.startEpochMillis)) · \(Formatters.durationText(exam.durationSeconds))")
                        .font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if let price = exam.price {
                        Text("¥\(Formatters.scoreText(price))").font(.system(size: 15, weight: .semibold)).foregroundColor(Tokens.danger)
                    }
                    if exam.payStatus == "PAID" || exam.eligibility == "ELIGIBLE" {
                        TagPill(text: "已报名", fg: Tokens.success, bg: Tokens.successSoft)
                    } else {
                        SecondaryButton(title: "报名") {
                            Task {
                                do {
                                    _ = try await env.repository.payOpenExam(examId: exam.id ?? "")
                                    toast = "报名成功"
                                    reload += 1
                                } catch {
                                    toast = (error as? ApiError)?.errorDescription ?? "报名失败"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 作答页

struct ExamTakingView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var vm: ExamTakingViewModel
    @State private var showSheet = false
    @State private var showConfirm = false
    @State private var resultId = ""
    @State private var showResult = false
    @Environment(\.dismiss) private var dismiss

    init(examId: String, repository: CandidateRepository) {
        _vm = StateObject(wrappedValue: ExamTakingViewModel(examId: examId, repository: repository))
    }

    var body: some View {
        Group {
            switch vm.state {
            case .idle, .loading:
                LoadingView()
            case .failure(let message):
                VStack(spacing: 12) {
                    ErrorBanner(message: message)
                    SecondaryButton(title: "重试") { Task { await vm.load() } }
                }
                .padding(Tokens.pagePadding)
            case .success(let attempt):
                content(attempt)
            }
        }
        .pageBackground()
        .navigationTitle(attemptTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CountdownText(remaining: vm.remaining)
            }
        }
        .toast($vm.toast)
        .sheet(isPresented: $showSheet) { answerSheet }
        .alert("交卷确认", isPresented: $showConfirm) {
            Button("确认交卷", role: .destructive) { Task { await vm.submit(auto: false) } }
            Button("再检查一下", role: .cancel) {}
        } message: {
            Text("交卷后不可再修改答案，确认交卷？")
        }
        .navigationDestination(isPresented: $showResult) {
            ResultView(attemptId: resultId, repository: env.repository)
        }
        .onChange(of: vm.submittedAttemptId) { newValue in
            if let id = newValue, !id.isEmpty {
                resultId = id
                showResult = true
            }
        }
        .task {
            if case .idle = vm.state { await vm.load() }
            else if case .loading = vm.state { await vm.load() }
        }
        .onAppear { vm.reportEvent("FOCUS", "onAppear") }
        .onDisappear { vm.reportEvent("APP_SWITCH", "onDisappear") }
        .onChange(of: scenePhase) { phase in
            vm.reportEvent(phase == .active ? "FOCUS" : "APP_SWITCH", phase == .active ? "active" : "inactive")
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    private var attemptTitle: String {
        if case .success(let attempt) = vm.state { return attempt.examName ?? "在线作答" }
        return "在线作答"
    }

    @ViewBuilder
    private func content(_ attempt: AttemptState) -> some View {
        let questions = attempt.questions ?? []
        VStack(spacing: 0) {
            HStack {
                Text("第 \(vm.currentIndex + 1) / \(questions.count) 题").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                Spacer()
                Text("已答 \(questions.filter { vm.isAnswered($0) }.count) · 已保存 \(vm.saveStatus.values.filter { $0 == "saved" }.count)")
                    .font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                Spacer()
                Text("\(Formatters.scoreText(vm.currentQuestion?.score)) 分").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Tokens.primarySoft)

            ScrollView {
                if let question = vm.currentQuestion {
                    questionCard(question)
                        .padding(16)
                }
            }

            HStack {
                SecondaryButton(title: "上一题", enabled: vm.currentIndex > 0) { vm.jump(to: vm.currentIndex - 1) }
                SecondaryButton(title: "答题卡") { showSheet = true }
                Spacer()
                if vm.currentIndex < questions.count - 1 {
                    Button { vm.jump(to: vm.currentIndex + 1) } label: {
                        Text("下一题").font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                            .padding(.horizontal, 20).frame(minHeight: 44).background(Tokens.primary).clipShape(Capsule())
                    }
                } else {
                    Button { showConfirm = true } label: {
                        Text("交卷").font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                            .padding(.horizontal, 20).frame(minHeight: 44).background(Tokens.success).clipShape(Capsule())
                    }
                    .disabled(vm.submitting)
                }
            }
            .padding(12)
            .background(Tokens.surface)
        }
    }

    @ViewBuilder
    private func questionCard(_ question: Question) -> some View {
        let color = Tokens.typeColor(resolvedType(question))
        SectionCard {
            HStack(spacing: 8) {
                Text("第 \(question.sortNo ?? 0) 题").font(.system(size: 15, weight: .bold))
                TagPill(text: Formatters.questionTypeLabel(resolvedType(question)), fg: color.fg, bg: color.bg)
                Spacer()
                Text(saveStatusText(question))
                    .font(.system(size: 11))
                    .foregroundColor(saveStatusColor(question))
                Button { vm.toggleFlag(question) } label: {
                    Text("标记").font(.system(size: 12))
                        .foregroundColor(vm.answer(of: question).flagged ? Tokens.warning : Tokens.textSecondary)
                }
                .buttonStyle(.plain)
            }

            RichText(content: question.stem, fontSize: 16)
                .padding(.top, 14)

            if question.type == "FILL" {
                let values = vm.fillValues[question.paperQuestionId ?? ""] ?? Array(repeating: "", count: max(question.blanks ?? 1, 1))
                ForEach(0..<values.count, id: \.self) { index in
                    HStack {
                        Text("第\(index + 1)空").font(.system(size: 13)).foregroundColor(Tokens.textSecondary).frame(width: 56, alignment: .leading)
                        TextField("请输入答案", text: Binding(
                            get: { values[index] },
                            set: { vm.updateFill(question, index: index, value: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    .padding(.top, 10)
                }
            } else if question.type == "ESSAY" {
                TextEditor(text: Binding(
                    get: { vm.answer(of: question).answerText },
                    set: { vm.updateEssay(question, text: $0) }
                ))
                .frame(minHeight: 140)
                .padding(6)
                .background(Tokens.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.top, 14)
            } else {
                VStack(spacing: 10) {
                    ForEach(question.options ?? [], id: \.key) { option in
                        let selected = vm.isSelected(question, option.key ?? "")
                        Button { vm.choose(question, option.key ?? "") } label: {
                            HStack(spacing: 10) {
                                Text(option.key ?? "")
                                    .font(.system(size: 12))
                                    .foregroundColor(selected ? .white : Tokens.textPrimary)
                                    .frame(width: 24, height: 24)
                                    .background(selected ? Tokens.primary : Tokens.surfaceAlt)
                                    .clipShape(Circle())
                                HtmlText(content: option.text ?? option.content, fontSize: 15)
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(selected ? Tokens.primarySoft : Tokens.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(selected ? Tokens.primary : Tokens.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 14)
            }
        }
    }

    private func saveStatusText(_ question: Question) -> String {
        switch vm.saveStatus[question.paperQuestionId ?? ""] ?? "pending" {
        case "saving": return "保存中"
        case "saved": return "已保存"
        case "error": return "保存失败"
        default: return "待保存"
        }
    }

    private func saveStatusColor(_ question: Question) -> Color {
        switch vm.saveStatus[question.paperQuestionId ?? ""] ?? "pending" {
        case "saved": return Tokens.success
        case "error": return Tokens.danger
        default: return Tokens.textTertiary
        }
    }

    private var answerSheet: some View {
        NavigationStack {
            ScrollView {
                if case .success(let attempt) = vm.state {
                    let questions = attempt.questions ?? []
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(Array(questions.indices), id: \.self) { index in
                            let question = questions[index]
                            Button {
                                vm.jump(to: index); showSheet = false
                            } label: {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: index == vm.currentIndex ? .bold : .regular))
                                    .foregroundColor(index == vm.currentIndex ? Tokens.primary : Tokens.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(vm.isAnswered(question) ? Tokens.primarySoft : Tokens.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(index == vm.currentIndex ? Tokens.primary : (vm.answer(of: question).flagged ? Tokens.warning : Tokens.border), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .pageBackground()
            .navigationTitle("答题卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("关闭") { showSheet = false } }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "交卷") {
                    showSheet = false
                    showConfirm = true
                }
                .padding(16)
                .background(Tokens.surface)
            }
        }
    }
}

// MARK: - 成绩页

struct ResultView: View {
    @EnvironmentObject var env: AppEnvironment
    let attemptId: String
    let repository: CandidateRepository

    init(attemptId: String, repository: CandidateRepository) {
        self.attemptId = attemptId
        self.repository = repository
    }

    var body: some View {
        RemoteContent(loader: { try await repository.result(attemptId: attemptId) }) { result in
            ScrollView {
                VStack(spacing: 16) {
                    SectionCard {
                        VStack(spacing: 8) {
                            Text(Formatters.scoreText(result.totalScore)).font(.system(size: 44, weight: .bold)).foregroundColor(Tokens.primary)
                            Text("总分").font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
                            if let passed = result.isPassed {
                                TagPill(text: passed ? "已通过" : "未通过", fg: passed ? Tokens.success : Tokens.danger, bg: passed ? Tokens.successSoft : Tokens.dangerSoft)
                            } else {
                                TagPill(text: "主观题阅卷中", fg: Tokens.warning, bg: Tokens.warningSoft)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        DividerLine().padding(.vertical, 12)
                        KeyValueRow(label: "客观题", value: "\(Formatters.scoreText(result.objectiveScore)) / \(Formatters.scoreText(result.objectiveTotal))")
                        KeyValueRow(label: "主观题", value: "\(Formatters.scoreText(result.subjectiveScore)) / \(Formatters.scoreText(result.subjectiveTotal))")
                        KeyValueRow(label: "答对", value: "\(result.correctCount ?? 0) 题")
                        KeyValueRow(label: "答错", value: "\(result.wrongCount ?? 0) 题")
                        KeyValueRow(label: "待阅", value: "\(result.pendingCount ?? 0) 题")
                        if result.auto == true { KeyValueRow(label: "交卷方式", value: "超时自动交卷") }
                    }
                    NavigationLink(value: Route.review(attemptId)) {
                        Text("查看解析").font(.system(size: 16, weight: .medium)).foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 48).background(Tokens.primary).clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
        .pageBackground()
        .navigationTitle("成绩")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReviewView: View {
    let attemptId: String
    let repository: CandidateRepository

    init(attemptId: String, repository: CandidateRepository) {
        self.attemptId = attemptId
        self.repository = repository
    }

    var body: some View {
        RemoteContent(loader: { try await repository.review(attemptId: attemptId) }) { review in
            if review.allowed == false {
                ScrollView {
                    ErrorBanner(message: policyText(review.policy)).padding(16)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        SectionCard {
                            HStack {
                                Text("共 \(review.questions?.count ?? 0) 题").font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
                                Spacer()
                                Text("得分 \(Formatters.scoreText(review.score?.totalScore))")
                                    .font(.system(size: 15, weight: .semibold)).foregroundColor(Tokens.primary)
                            }
                        }
                        ForEach(Array((review.questions ?? []).indices), id: \.self) { index in
                            let item = (review.questions ?? [])[index]
                            SectionCard {
                                HStack(spacing: 8) {
                                    Text("第 \(index + 1) 题").font(.system(size: 15, weight: .bold))
                                    if item.correct == true {
                                        TagPill(text: "正确", fg: Tokens.success, bg: Tokens.successSoft)
                                    } else if item.correct == false {
                                        TagPill(text: "错误", fg: Tokens.danger, bg: Tokens.dangerSoft)
                                    } else {
                                        TagPill(text: "待阅卷", fg: Tokens.warning, bg: Tokens.warningSoft)
                                    }
                                    Spacer()
                                    Text("\(Formatters.scoreText(item.score)) 分").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                }
                                RichText(content: item.stem, fontSize: 15).padding(.top, 8)
                                if let options = item.options, !options.isEmpty {
                                    VStack(alignment: .leading, spacing: 3) {
                                        ForEach(options, id: \.key) { option in
                                            HStack(spacing: 8) {
                                                Text(option.key ?? "").font(.system(size: 14, weight: .bold)).foregroundColor(Tokens.primary)
                                                HtmlText(content: option.text ?? option.content, fontSize: 14)
                                                Spacer(minLength: 0)
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                DividerLine().padding(.vertical, 8)
                                KeyValueRow(label: "我的答案", value: formatAnswer(item.myAnswerJson))
                                if let expected = item.expected, !expected.isEmpty {
                                    KeyValueRow(label: "正确答案", value: expected.joined(separator: " / "))
                                }
                                if let analysis = item.analysis, !analysis.isEmpty {
                                    Text("解析").font(.system(size: 12)).foregroundColor(Tokens.textSecondary).padding(.top, 8)
                                    RichText(content: analysis, fontSize: 13).padding(.top, 2)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .pageBackground()
        .navigationTitle("答题详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policyText(_ policy: String?) -> String {
        switch policy {
        case "NEVER": return "本场考试不展示答题详情"
        case "AFTER_PUBLISH": return "成绩发布后可查看答题详情"
        case "AFTER_END": return "考试结束后可查看答题详情"
        default: return "暂不可查看答题详情"
        }
    }

    private func formatAnswer(_ value: String?) -> String {
        guard let value = value, !value.isEmpty else { return "未作答" }
        guard let data = value.data(using: .utf8), let array = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            return value
        }
        return array.map { String(describing: $0) }.joined(separator: " / ")
    }
}


private func resolvedType(_ question: Question) -> String {
    if let type = question.type, !type.isEmpty { return type }
    return question.typeCode ?? ""
}
