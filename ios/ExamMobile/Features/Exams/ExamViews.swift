import Foundation
import SwiftUI

// MARK: - 考试列表

private struct ExamFilterOption: Identifiable {
    let value: String
    let label: String
    var id: String { value }
}

struct ExamListView: View {
    @EnvironmentObject var env: AppEnvironment
    @Environment(\.openURL) private var openURL

    @State private var keyword = ""
    @State private var appliedKeyword = ""
    @State private var paidFilter = ""
    @State private var sort = "startTime"
    @State private var reload = 0

    @State private var passwordDialog = false
    @State private var passwordValue = ""
    @State private var pendingExamId: String?
    @State private var pendingResult = false

    @State private var toast: String?
    @State private var goExamTaking = false
    @State private var goResult = false
    @State private var targetExamId = ""
    @State private var targetAttemptId = ""

    private let paidOptions: [ExamFilterOption] = [
        ExamFilterOption(value: "", label: "全部"),
        ExamFilterOption(value: "false", label: "免费"),
        ExamFilterOption(value: "true", label: "付费")
    ]

    private let sortOptions: [ExamFilterOption] = [
        ExamFilterOption(value: "startTime", label: "最新"),
        ExamFilterOption(value: "name", label: "名称"),
        ExamFilterOption(value: "priceAsc", label: "价格↑"),
        ExamFilterOption(value: "priceDesc", label: "价格↓")
    ]

    private var params: [String: String] {
        var result: [String: String] = [:]
        let trimmed = appliedKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { result["keyword"] = trimmed }
        if !paidFilter.isEmpty { result["paid"] = paidFilter }
        if !sort.isEmpty { result["sort"] = sort }
        return result
    }

    private var listKey: String {
        "\(appliedKeyword)|\(paidFilter)|\(sort)|\(reload)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                GradientHero {
                    Text("\(Formatters.greeting())，同学")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.white)
                    Text("欢迎回来，请按考试时间参加；支持断线续考，作答会自动保存。")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.88))
                        .lineSpacing(4)
                        .padding(.top, 6)
                }

                filterCard

                RemoteContent(
                    loader: {
                        async let assigned = env.repository.exams(params)
                        async let openList = env.repository.openExams()
                        return (try await assigned, try await openList)
                    },
                    emptyCheck: { _ in false }
                ) { data in
                    let (assigned, openList) = data
                    let assignedIds = Set(assigned.compactMap { $0.id })
                    let openVisible = openList.filter { !assignedIds.contains($0.id ?? "") }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "我的考试")
                        if assigned.isEmpty {
                            EmptyStateView(text: "暂无考试")
                        } else {
                            ForEach(assigned) { exam in
                                examCard(exam)
                            }
                        }
                        if !openVisible.isEmpty {
                            SectionHeader(title: "开放考试")
                            ForEach(openVisible) { exam in
                                openCard(exam)
                            }
                        }
                    }
                }
                .id(listKey)
            }
            .padding(.horizontal, Tokens.pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .pageBackground()
        .navigationTitle("我的考试")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .alert("请输入考试密码", isPresented: $passwordDialog) {
            SecureField("考试密码", text: $passwordValue)
            Button("进入考试") {
                let password = passwordValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let examId = pendingExamId, !password.isEmpty else {
                    toast = "请输入考试密码"
                    return
                }
                let asResult = pendingResult
                pendingExamId = nil
                passwordDialog = false
                launchExam(examId: examId, result: asResult, password: password)
            }
            Button("取消", role: .cancel) { pendingExamId = nil }
        } message: {
            Text("该考试需要输入密码后才能进入")
        }
        .navigationDestination(isPresented: $goExamTaking) {
            ExamTakingView(examId: targetExamId, repository: env.repository)
        }
        .navigationDestination(isPresented: $goResult) {
            ResultView(attemptId: targetAttemptId, repository: env.repository)
        }
    }

    private var filterCard: some View {
        SectionCard {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Tokens.textTertiary)
                TextField("搜索考试名称", text: $keyword)
                    .font(.system(size: 13))
                    .submitLabel(.search)
                    .onSubmit {
                        appliedKeyword = keyword
                        reload += 1
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Tokens.surfaceAlt.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(paidOptions) { option in
                        FilterChip(title: option.label, selected: paidFilter == option.value) {
                            paidFilter = option.value
                        }
                    }
                    ForEach(sortOptions) { option in
                        FilterChip(title: option.label, selected: sort == option.value) {
                            sort = option.value
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
    }

    @ViewBuilder
    private func examCard(_ exam: ExamSummary) -> some View {
        let tag = examTag(exam.attemptStatus)
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                if let cover = exam.coverUrl, let url = URL(string: cover) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Tokens.surfaceAlt
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                HStack(alignment: .top, spacing: 8) {
                    Text(exam.name ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Tokens.textPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    TagPill(text: tag.text, fg: tag.fg, bg: tag.bg)
                }
                if !(exam.paperName ?? "").isEmpty || exam.displayPrice != nil {
                    HStack(spacing: 0) {
                        Text(exam.paperName ?? "未命名试卷")
                            .font(.system(size: 13))
                            .foregroundColor(Tokens.textSecondary)
                        if let price = exam.displayPrice {
                            Text(" · ¥\(Formatters.scoreText(price))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Tokens.danger)
                        }
                    }
                }
                if let intro = exam.intro, !intro.isEmpty {
                    Text(intro)
                        .font(.system(size: 12))
                        .foregroundColor(Tokens.textSecondary)
                        .lineLimit(2)
                }
                HStack(alignment: .top, spacing: 14) {
                    MiniMeta(label: "开始", value: displayTime(exam.startEpochMillis, exam.startTime))
                    MiniMeta(label: "时长", value: Formatters.durationText(exam.durationSeconds))
                    if let total = exam.totalScore {
                        MiniMeta(label: "总分", value: Formatters.scoreText(total))
                    }
                    if let score = exam.score {
                        MiniMeta(label: "得分", value: Formatters.scoreText(score), valueColor: Tokens.primary)
                    }
                }
                .padding(.top, 2)
                HStack(spacing: 10) {
                    if canStartExam(exam.attemptStatus) {
                        MiniGradientButton(title: "开始/继续作答") {
                            launchExam(examId: exam.id ?? "")
                        }
                    }
                    if ["SUBMITTED", "GRADED"].contains(exam.attemptStatus ?? "") {
                        MiniSoftButton(title: "查看成绩") {
                            launchExam(examId: exam.id ?? "", result: true)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func openCard(_ exam: OpenExamSummary) -> some View {
        let tag = openTag(exam)
        SectionCard {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exam.name ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Tokens.textPrimary)
                        .lineLimit(2)
                    HStack(spacing: 0) {
                        Text(accessModeText(exam.accessMode))
                            .font(.system(size: 12))
                            .foregroundColor(Tokens.textSecondary)
                        if let price = exam.price, price > 0 {
                            Text(" / ¥\(Formatters.scoreText(price))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Tokens.danger)
                        }
                    }
                    Text("\(displayTime(exam.startEpochMillis, exam.startTime)) · \(Formatters.durationText(exam.durationSeconds))")
                        .font(.system(size: 12))
                        .foregroundColor(Tokens.textSecondary)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 8) {
                    TagPill(text: tag.text, fg: tag.fg, bg: tag.bg)
                    if exam.eligibility == "NEED_PAYMENT" {
                        MiniGradientButton(title: "缴费进入") { startOpen(exam) }
                    } else if exam.eligibility == "READY_TO_START" {
                        MiniGradientButton(title: "开始作答") { startOpen(exam) }
                    } else if exam.accessMode == "REGISTER" || exam.accessMode == "APPROVAL" {
                        MiniSoftButton(title: "去报名") { openRegistration() }
                    } else {
                        Text(openConditionText(exam))
                            .font(.system(size: 12))
                            .foregroundColor(Tokens.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - 操作

    private func launchExam(examId: String, result: Bool = false, password: String? = nil) {
        guard !examId.isEmpty else { return }
        Task { @MainActor in
            do {
                let state = try await env.repository.startExam(examId: examId, password: password)
                if result || state.status == "SUBMITTED" || state.status == "GRADED" {
                    let attemptId = state.attemptId ?? ""
                    if attemptId.isEmpty {
                        toast = "暂无成绩"
                    } else {
                        targetAttemptId = attemptId
                        goResult = true
                    }
                } else {
                    targetExamId = examId
                    goExamTaking = true
                }
            } catch {
                let message = (error as? ApiError)?.errorDescription ?? "无法开始考试"
                if password == nil && message.contains("密码") {
                    pendingExamId = examId
                    pendingResult = result
                    passwordValue = ""
                    passwordDialog = true
                } else {
                    toast = message
                }
            }
        }
    }

    private func startOpen(_ exam: OpenExamSummary) {
        let examId = exam.id ?? ""
        guard !examId.isEmpty else { return }
        if exam.eligibility == "NEED_PAYMENT" {
            Task { @MainActor in
                do {
                    _ = try await env.repository.payOpenExam(examId: examId)
                    toast = "缴费成功"
                    reload += 1
                    launchExam(examId: examId)
                } catch {
                    toast = (error as? ApiError)?.errorDescription ?? "缴费失败"
                }
            }
        } else if exam.eligibility == "READY_TO_START" {
            launchExam(examId: examId)
        } else if exam.accessMode == "REGISTER" || exam.accessMode == "APPROVAL" {
            openRegistration()
        } else {
            toast = openConditionText(exam)
        }
    }

    private func openRegistration() {
        var base = AppConfig.registrationUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") { base.removeLast() }
        guard !base.isEmpty else {
            toast = "报名入口未配置"
            return
        }
        if let url = URL(string: base + "/campaigns") {
            openURL(url)
        } else {
            toast = "报名入口未配置"
        }
    }
}

private struct MiniMeta: View {
    let label: String
    let value: String
    var valueColor: Color = Tokens.textSecondary

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Tokens.textTertiary)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
    }
}

private struct MiniGradientButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Tokens.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MiniSoftButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Tokens.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Tokens.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private func examTag(_ status: String?) -> (text: String, fg: Color, bg: Color) {
    switch (status ?? "").uppercased() {
    case "IN_PROGRESS", "STARTED":
        return ("作答中", Tokens.primary, Tokens.primarySoft)
    case "GRADED":
        return ("已出分", Tokens.success, Tokens.successSoft)
    case "SUBMITTED", "GRADING":
        return ("已交卷", Tokens.warning, Tokens.warningSoft)
    case "ABSENT":
        return ("缺考", Tokens.danger, Tokens.dangerSoft)
    case "EXPIRED":
        return ("已过期", Tokens.textSecondary, Tokens.surfaceAlt)
    default:
        return (Formatters.attemptStatusLabel(status), Tokens.textSecondary, Tokens.surfaceAlt)
    }
}

private func canStartExam(_ status: String?) -> Bool {
    !["SUBMITTED", "GRADED", "REGISTERED", "REJECTED", "CANCELLED"].contains(status ?? "")
}

private func openTag(_ exam: OpenExamSummary) -> (text: String, fg: Color, bg: Color) {
    switch exam.eligibility {
    case "READY_TO_START":
        return ("可开始", Tokens.success, Tokens.successSoft)
    case "NEED_PAYMENT":
        return ("待缴费", Tokens.warning, Tokens.warningSoft)
    default:
        return ("需条件", Tokens.textSecondary, Tokens.surfaceAlt)
    }
}

private func accessModeText(_ mode: String?) -> String {
    switch mode {
    case "PAID": return "付费考试"
    case "PASSWORD": return "密码考试"
    case "VIP": return "VIP 考试"
    case "POINTS": return "积分考试"
    case "QRCODE": return "扫码考试"
    case "ORG_POSITION": return "部门考试"
    case "REGISTER": return "报名考试"
    case "APPROVAL": return "申报审核"
    case "CLASS": return "班级考试"
    case "FIXED": return "固定人群"
    default: return mode ?? "开放考试"
    }
}

private func openConditionText(_ exam: OpenExamSummary) -> String {
    switch exam.accessMode {
    case "REGISTER": return "请先报名"
    case "APPROVAL": return "报名审核中"
    default: return accessModeText(exam.accessMode)
    }
}

private func displayTime(_ epoch: String?, _ fallback: String?) -> String {
    let formatted = Formatters.epochToDateTime(epoch)
    if !formatted.isEmpty { return formatted }
    guard let fallback = fallback, !fallback.isEmpty else { return "-" }
    return fallback.replacingOccurrences(of: "T", with: " ").prefix(16).description
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
        takingBody
            .pageBackground()
            .navigationTitle(attemptTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CountdownText(remaining: vm.remaining)
                }
            }
            .toast($vm.toast)
            .sheet(isPresented: $showSheet) {
                answerSheet
            }
            .alert("交卷确认", isPresented: $showConfirm) {
                Button("确认交卷", role: .destructive) {
                    Task { await vm.submit(auto: false) }
                }
                Button("再检查一下", role: .cancel) {}
            } message: {
                Text("交卷后不可再修改答案，确认交卷？")
            }
            .navigationDestination(isPresented: $showResult) {
                ResultView(attemptId: resultId, repository: env.repository)
            }
            .onChange(of: vm.submittedAttemptId) { (newValue: String?) in
                handleSubmitted(newValue)
            }
            .task {
                await vm.loadIfNeeded()
            }
            .onAppear {
                vm.reportEvent("FOCUS", "onAppear")
            }
            .onDisappear {
                vm.reportEvent("APP_SWITCH", "onDisappear")
            }
            .modifier(ExamScenePhaseModifier(vm: vm))
    }

    @ViewBuilder
    private var takingBody: some View {
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

    private func handleSubmitted(_ id: String?) {
        guard let id = id, !id.isEmpty else { return }
        resultId = id
        showResult = true
    }

    private var attemptTitle: String {
        if case .success(let attempt) = vm.state { return attempt.examName ?? "在线作答" }
        return "在线作答"
    }

    @ViewBuilder
    private func content(_ attempt: AttemptState) -> some View {
        let questions = attempt.questions ?? []
        VStack(spacing: 0) {
            HStack {
                Text("第 \(vm.currentIndex + 1) / \(questions.count) 题")
                    .font(.system(size: 12))
                    .foregroundColor(Tokens.textSecondary)
                Spacer()
                Text("已答 \(questions.filter { vm.isAnswered($0) }.count) · 已保存 \(vm.saveStatus.values.filter { $0 == "saved" }.count)")
                    .font(.system(size: 12))
                    .foregroundColor(Tokens.textSecondary)
                Spacer()
                Text("\(Formatters.scoreText(vm.currentQuestion?.score)) 分")
                    .font(.system(size: 12))
                    .foregroundColor(Tokens.textSecondary)
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
                SecondaryButton(title: "上一题", enabled: vm.currentIndex > 0) {
                    vm.jump(to: vm.currentIndex - 1)
                }
                SecondaryButton(title: "答题卡") { showSheet = true }
                Spacer()
                if vm.currentIndex < questions.count - 1 {
                    Button { vm.jump(to: vm.currentIndex + 1) } label: {
                        Text("下一题")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 44)
                            .background(Tokens.primary)
                            .clipShape(Capsule())
                    }
                } else {
                    Button { showConfirm = true } label: {
                        Text("交卷")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 44)
                            .background(Tokens.success)
                            .clipShape(Capsule())
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
                Text("第 \(question.sortNo ?? 0) 题")
                    .font(.system(size: 15, weight: .bold))
                TagPill(text: Formatters.questionTypeLabel(resolvedType(question)), fg: color.fg, bg: color.bg)
                Spacer()
                Text(saveStatusText(question))
                    .font(.system(size: 11))
                    .foregroundColor(saveStatusColor(question))
                Button { vm.toggleFlag(question) } label: {
                    Text("标记")
                        .font(.system(size: 12))
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
                        Text("第\(index + 1)空")
                            .font(.system(size: 13))
                            .foregroundColor(Tokens.textSecondary)
                            .frame(width: 56, alignment: .leading)
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(selected ? Tokens.primary : Tokens.border, lineWidth: 1)
                            )
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
                                vm.jump(to: index)
                                showSheet = false
                            } label: {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: index == vm.currentIndex ? .bold : .regular))
                                    .foregroundColor(index == vm.currentIndex ? Tokens.primary : Tokens.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(vm.isAnswered(question) ? Tokens.primarySoft : Tokens.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(
                                                index == vm.currentIndex
                                                    ? Tokens.primary
                                                    : (vm.answer(of: question).flagged ? Tokens.warning : Tokens.border),
                                                lineWidth: 1
                                            )
                                    )
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { showSheet = false }
                }
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

private struct ExamScenePhaseModifier: ViewModifier {
    @ObservedObject var vm: ExamTakingViewModel
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.onChange(of: scenePhase) { (phase: ScenePhase) in
            vm.reportEvent(
                phase == .active ? "FOCUS" : "APP_SWITCH",
                phase == .active ? "active" : "inactive"
            )
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
                        VStack(spacing: 10) {
                            let total = (result.objectiveTotal ?? 0) + (result.subjectiveTotal ?? 0)
                            let score = result.totalScore ?? 0
                            let fraction = total <= 0 ? 0 : min(max(score / total, 0), 1)
                            ZStack {
                                Circle()
                                    .stroke(Tokens.primarySoft, lineWidth: 11)
                                Circle()
                                    .trim(from: 0, to: CGFloat(fraction))
                                    .stroke(
                                        Tokens.primaryGradient,
                                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                VStack(spacing: 0) {
                                    Text(Formatters.scoreText(result.totalScore))
                                        .font(.system(size: 44, weight: .bold))
                                        .foregroundColor(Tokens.primaryDeep)
                                    Text("总分")
                                        .font(.system(size: 12))
                                        .foregroundColor(Tokens.textSecondary)
                                }
                            }
                            .frame(width: 150, height: 150)

                            if let passed = result.isPassed {
                                TagPill(
                                    text: passed ? "考试通过" : "未通过",
                                    fg: passed ? Tokens.success : Tokens.danger,
                                    bg: passed ? Tokens.successSoft : Tokens.dangerSoft
                                )
                            } else {
                                TagPill(text: "主观题阅卷中", fg: Tokens.warning, bg: Tokens.warningSoft)
                            }
                            Text("满分 \(Formatters.scoreText(total))")
                                .font(.system(size: 12))
                                .foregroundColor(Tokens.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)

                        DividerLine()
                            .padding(.vertical, 12)

                        KeyValueRow(label: "客观题", value: "\(Formatters.scoreText(result.objectiveScore)) / \(Formatters.scoreText(result.objectiveTotal))")
                        KeyValueRow(label: "主观题", value: "\(Formatters.scoreText(result.subjectiveScore)) / \(Formatters.scoreText(result.subjectiveTotal))")
                        KeyValueRow(label: "答对", value: "\(result.correctCount ?? 0) 题")
                        KeyValueRow(label: "答错", value: "\(result.wrongCount ?? 0) 题")
                        KeyValueRow(label: "待阅", value: "\(result.pendingCount ?? 0) 题")
                        KeyValueRow(label: "交卷方式", value: result.auto == true ? "超时自动交卷" : "手动交卷")
                        if let submittedAt = result.submittedAt, !submittedAt.isEmpty {
                            KeyValueRow(label: "交卷时间", value: submittedAt)
                        }
                    }

                    NavigationLink(value: Route.review(attemptId)) {
                        Text("查看解析")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Tokens.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(
                                color: Tokens.buttonShadowColor,
                                radius: Tokens.buttonShadowRadius,
                                x: 0,
                                y: Tokens.buttonShadowY
                            )
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

// MARK: - 解析页

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
                    ErrorBanner(message: policyText(review.policy))
                        .padding(16)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        SectionCard {
                            HStack {
                                Text("共 \(review.questions?.count ?? 0) 题")
                                    .font(.system(size: 13))
                                    .foregroundColor(Tokens.textSecondary)
                                Spacer()
                                Text("得分 \(Formatters.scoreText(review.score?.totalScore))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Tokens.primary)
                            }
                        }
                        ForEach(Array((review.questions ?? []).indices), id: \.self) { index in
                            let item = (review.questions ?? [])[index]
                            reviewCard(item, index: index)
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

    @ViewBuilder
    private func reviewCard(_ item: ReviewQuestion, index: Int) -> some View {
        SectionCard {
            HStack(spacing: 8) {
                Text("第 \(index + 1) 题")
                    .font(.system(size: 15, weight: .bold))
                if item.correct == true {
                    TagPill(text: "正确", fg: Tokens.success, bg: Tokens.successSoft)
                } else if item.correct == false {
                    TagPill(text: "错误", fg: Tokens.danger, bg: Tokens.dangerSoft)
                } else {
                    TagPill(text: "待阅卷", fg: Tokens.warning, bg: Tokens.warningSoft)
                }
                Spacer()
                Text("\(Formatters.scoreText(item.score)) 分")
                    .font(.system(size: 12))
                    .foregroundColor(Tokens.textSecondary)
            }
            RichText(content: item.stem, fontSize: 15)
                .padding(.top, 8)
            if let options = item.options, !options.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(options, id: \.key) { option in
                        HStack(spacing: 8) {
                            Text(option.key ?? "")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Tokens.primary)
                            HtmlText(content: option.text ?? option.content, fontSize: 14)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.top, 8)
            }
            DividerLine()
                .padding(.vertical, 8)
            KeyValueRow(label: "我的答案", value: formatAnswer(item.myAnswerJson))
            if let expected = item.expected, !expected.isEmpty {
                KeyValueRow(label: "正确答案", value: expected.joined(separator: " / "))
            }
            if let analysis = item.analysis, !analysis.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("解析")
                        .font(.system(size: 12))
                        .foregroundColor(Tokens.textSecondary)
                    RichText(content: analysis, fontSize: 13)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Tokens.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.top, 10)
            }
        }
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
        guard let data = value.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            return value
        }
        return array.map { String(describing: $0) }.joined(separator: " / ")
    }
}

private func resolvedType(_ question: Question) -> String {
    if let type = question.type, !type.isEmpty { return type }
    return question.typeCode ?? ""
}
