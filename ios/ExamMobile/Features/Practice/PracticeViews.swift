import Foundation
import SwiftUI

// MARK: - 练习列表

private struct PracticeSourceOption: Identifiable {
    let value: String
    let label: String
    var id: String { value }
}

struct PracticeListView: View {
    @EnvironmentObject var env: AppEnvironment

    @State private var reload = 0
    @State private var passwordDialog = false
    @State private var passwordValue = ""
    @State private var pendingSet: PracticeSet?
    @State private var toast: String?

    @State private var goTaking = false
    @State private var goMemberOrder = false
    @State private var goStats = false
    @State private var targetRecordId = ""
    @State private var memberBizId = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                GradientHero(gradient: Tokens.accentGradient) {
                    Text("在线练习")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.white)
                    Text("逐题判定、自动收录错题，坚持每天进步一点。")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.88))
                        .padding(.top, 5)
                }

                RemoteContent(
                    loader: {
                        async let stats = env.repository.practiceStatistics()
                        async let sets = env.repository.practiceSets()
                        return (try await stats, try await sets)
                    },
                    emptyCheck: { _ in false }
                ) { data in
                    let (stats, sets) = data
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "练习概览",
                            actionLabel: "详细统计",
                            action: { goStats = true }
                        )
                        HStack(spacing: 10) {
                            StatTile(
                                label: "练习次数",
                                value: "\(stats.totalRecords ?? 0)",
                                tint: Tokens.primary,
                                bg: Tokens.primarySoft
                            )
                            StatTile(
                                label: "完成",
                                value: "\(stats.finishedRecords ?? 0)",
                                tint: Tokens.accent,
                                bg: Tokens.accentSoft
                            )
                            StatTile(
                                label: "正确率",
                                value: "\(Int((stats.averageAccuracy ?? 0) * 100))%",
                                tint: Tokens.success,
                                bg: Tokens.successSoft
                            )
                            StatTile(
                                label: "题量",
                                value: "\(stats.totalQuestions ?? 0)",
                                tint: Tokens.violet,
                                bg: Tokens.violetSoft
                            )
                        }

                        SectionHeader(title: "练习题库")
                        if sets.isEmpty {
                            EmptyStateView(text: "暂无练习题集")
                        } else {
                            ForEach(sets) { set in
                                setCard(set)
                            }
                        }
                    }
                }
                .id(reload)
            }
            .padding(.horizontal, Tokens.pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .pageBackground()
        .navigationTitle("在线练习")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .alert("请输入练习密码", isPresented: $passwordDialog) {
            SecureField("练习密码", text: $passwordValue)
            Button("进入练习") {
                guard let set = pendingSet else { return }
                let password = passwordValue.trimmingCharacters(in: .whitespacesAndNewlines)
                pendingSet = nil
                passwordDialog = false
                guard !password.isEmpty else {
                    toast = "请输入练习密码"
                    return
                }
                start(set, password: password)
            }
            Button("取消", role: .cancel) { pendingSet = nil }
        } message: {
            Text("该练习需要输入密码后才能进入")
        }
        .navigationDestination(isPresented: $goTaking) {
            PracticeTakingView(recordId: targetRecordId)
        }
        .navigationDestination(isPresented: $goMemberOrder) {
            MemberView(pendingBizType: "PRACTICE", pendingBizId: memberBizId)
        }
        .navigationDestination(isPresented: $goStats) {
            PracticeStatsView()
        }
    }

    @ViewBuilder
    private func setCard(_ set: PracticeSet) -> some View {
        let unlocked = set.isUnlocked
        let statusText: String = {
            if !unlocked {
                let reason = String((set.lockReason ?? "").prefix(6))
                return reason.isEmpty ? "未开放" : reason
            }
            return set.joined == true ? "继续练习" : "开始练习"
        }()
        let statusFg = !unlocked ? Tokens.warning : (set.joined == true ? Tokens.success : Tokens.primary)
        let statusBg = !unlocked ? Tokens.warningSoft : (set.joined == true ? Tokens.successSoft : Tokens.primarySoft)

        SectionCard {
            Button { handleOpen(set) } label: {
                HStack(spacing: 12) {
                    IconTile(
                        icon: "square.and.pencil",
                        tint: Tokens.accent,
                        bg: Tokens.accentSoft,
                        size: 46,
                        iconSize: 21
                    )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(set.name ?? "")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Tokens.textPrimary)
                            .lineLimit(2)
                        if let desc = set.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 12))
                                .foregroundColor(Tokens.textSecondary)
                                .lineLimit(1)
                        }
                        HStack(spacing: 6) {
                            TagPill(
                                text: practiceModeText(set.mode),
                                fg: Tokens.accent,
                                bg: Tokens.accentSoft
                            )
                            Text("\(set.questionCount ?? 0) 题")
                                .font(.system(size: 11))
                                .foregroundColor(Tokens.textSecondary)
                            if let duration = set.durationSeconds, duration > 0 {
                                Text("限时 \(max(1, (duration + 59) / 60)) 分钟")
                                    .font(.system(size: 11))
                                    .foregroundColor(Tokens.textSecondary)
                            }
                            if let points = set.pointsCost, points > 0 {
                                Text("\(points) 积分")
                                    .font(.system(size: 11))
                                    .foregroundColor(Tokens.amber)
                            }
                            if let price = set.price, price > 0 {
                                Text("¥\(Formatters.scoreText(price))")
                                    .font(.system(size: 11))
                                    .foregroundColor(Tokens.danger)
                            }
                        }
                        .padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                    TagPill(text: statusText, fg: statusFg, bg: statusBg)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func handleOpen(_ set: PracticeSet) {
        let setId = set.id ?? ""
        guard !setId.isEmpty else { return }
        if !set.isUnlocked {
            let reason = set.lockReason ?? ""
            if reason.contains("密码") {
                pendingSet = set
                passwordValue = ""
                passwordDialog = true
                return
            }
            toast = reason.isEmpty ? "该练习需要先满足进入条件" : reason
            if reason.contains("购买") {
                memberBizId = setId
                goMemberOrder = true
            }
            return
        }
        if set.accessMode == "POINTS" {
            toast = "将消耗 \(set.pointsCost ?? 0) 积分进入"
        }
        start(set)
    }

    private func start(_ set: PracticeSet, password: String? = nil) {
        guard let setId = set.id, !setId.isEmpty else { return }
        Task { @MainActor in
            do {
                let record = try await env.repository.practiceStart(setId: setId, password: password)
                let recordId = (record.recordId?.isEmpty == false ? record.recordId : record.setId) ?? setId
                targetRecordId = recordId
                goTaking = true
                if let password = password, !password.isEmpty {
                    toast = "已进入练习"
                }
            } catch {
                toast = (error as? ApiError)?.errorDescription ?? "进入练习失败"
            }
        }
    }
}

private func practiceModeText(_ mode: String?) -> String {
    switch mode {
    case "FIXED": return "固定试题"
    case "RANDOM": return "随机抽题"
    case "SHUFFLE": return "顺序随机"
    default: return "在线练习"
    }
}

// MARK: - 练习统计

struct PracticeStatsView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        RemoteContent(loader: { try await env.repository.practiceStatistics() }) { stats in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GradientHero(gradient: Tokens.accentGradient) {
                        Text("练习数据")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("每一次练习都在积累底气")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.88))
                            .padding(.top, 5)
                    }
                    HStack(spacing: 10) {
                        StatTile(
                            label: "练习次数",
                            value: "\(stats.totalRecords ?? 0)",
                            tint: Tokens.primary,
                            bg: Tokens.primarySoft
                        )
                        StatTile(
                            label: "完成",
                            value: "\(stats.finishedRecords ?? 0)",
                            tint: Tokens.accent,
                            bg: Tokens.accentSoft
                        )
                        StatTile(
                            label: "正确率",
                            value: "\(Int((stats.averageAccuracy ?? 0) * 100))%",
                            tint: Tokens.success,
                            bg: Tokens.successSoft
                        )
                    }
                    SectionHeader(title: "答题明细")
                    SectionCard {
                        KeyValueRow(label: "累计做题", value: "\(stats.totalQuestions ?? 0)")
                        KeyValueRow(label: "答对", value: "\(stats.correctQuestions ?? 0)")
                        KeyValueRow(
                            label: "答错",
                            value: "\(max((stats.totalQuestions ?? 0) - (stats.correctQuestions ?? 0), 0))"
                        )
                    }
                }
                .padding(16)
            }
        }
        .pageBackground()
        .navigationTitle("练习统计")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 练习作答

struct PracticeTakingView: View {
    @EnvironmentObject var env: AppEnvironment
    let recordId: String

    @State private var record: PracticeRecord?
    @State private var loading = true
    @State private var error: String?
    @State private var index = 0
    @State private var selected: [String] = []
    @State private var fillInputs: [String] = []
    @State private var essayText = ""
    @State private var verdict: PracticeVerdict?
    @State private var submitting = false
    @State private var showDone = false
    @State private var showExit = false
    @State private var answeredCount = 0
    @State private var correctCount = 0
    @State private var wrongCount = 0
    @State private var toast: String?
    @Environment(\.dismiss) private var dismiss

    init(recordId: String) {
        self.recordId = recordId
    }

    private var questions: [Question] {
        let list = record?.questions ?? []
        if !list.isEmpty { return list }
        if let question = record?.question { return [question] }
        return []
    }

    private var current: Question? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    private var practiceTitle: String {
        if let title = record?.title, !title.isEmpty { return title }
        if let name = record?.setName, !name.isEmpty { return name }
        return "练习"
    }

    var body: some View {
        Group {
            if loading {
                LoadingView()
            } else if let error = error {
                VStack(spacing: 12) {
                    ErrorBanner(message: error)
                    SecondaryButton(title: "重试") { Task { await load() } }
                }
                .padding(16)
            } else if let current = current {
                content(current)
            } else {
                EmptyStateView(text: "暂无题目")
            }
        }
        .pageBackground()
        .navigationTitle("在线练习")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .task { await load() }
        .onChange(of: index) { _ in resetInputs() }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("退出") { showExit = true }
                    .font(.system(size: 13))
            }
        }
        .confirmationDialog("退出练习？", isPresented: $showExit, titleVisibility: .visible) {
            Button("放弃并退出", role: .destructive) { abandonAndExit() }
            Button("继续作答", role: .cancel) {}
        } message: {
            Text("退出后本次练习将放弃，已作答内容会保留为记录。")
        }
        .alert("练习完成", isPresented: $showDone) {
            Button("结束并退出") { finishAndExit() }
            Button("留在当前", role: .cancel) {}
        } message: {
            Text("已完成 \(answeredCount)/\(record?.questionCount ?? questions.count) 题\n正确 \(correctCount) 题 · 错误 \(wrongCount) 题")
        }
    }

    private func content(_ current: Question) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(practiceTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Tokens.textPrimary)
                        .lineLimit(1)
                    Text("第 \(record?.attemptNo ?? 1) 次练习")
                        .font(.system(size: 11))
                        .foregroundColor(Tokens.textSecondary)
                }
                Spacer(minLength: 0)
                TagPill(
                    text: "已答 \(answeredCount)/\(record?.questionCount ?? questions.count)",
                    fg: Tokens.primary,
                    bg: Tokens.primarySoft
                )
                TagPill(text: "对 \(correctCount)", fg: Tokens.success, bg: Tokens.successSoft)
                TagPill(text: "错 \(wrongCount)", fg: Tokens.danger, bg: Tokens.dangerSoft)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Tokens.surface)

            ScrollView {
                VStack(spacing: 12) {
                    questionCard(current)
                }
                .padding(16)
            }

            bottomBar(current)
        }
    }

    @ViewBuilder
    private func questionCard(_ current: Question) -> some View {
        let type = typeOf(current)
        let color = Tokens.typeColor(type)
        SectionCard {
            HStack(spacing: 8) {
                TagPill(text: Formatters.questionTypeLabel(type), fg: color.fg, bg: color.bg)
                Text("第 \(index + 1) / \(questions.count) 题")
                    .font(.system(size: 12))
                    .foregroundColor(Tokens.textSecondary)
                Spacer()
                Text("\(Formatters.scoreText(current.score)) 分")
                    .font(.system(size: 12))
                    .foregroundColor(Tokens.textSecondary)
            }
            RichText(content: current.stem, fontSize: 16)
                .padding(.top, 14)

            let options = current.options ?? []
            if !options.isEmpty {
                optionsView(current, options: options)
                    .padding(.top, 14)
            } else if type == "FILL" {
                fillView(current)
                    .padding(.top, 14)
            } else {
                essayView
                    .padding(.top, 14)
            }

            if let verdict = verdict {
                verdictBox(verdict)
                    .padding(.top, 14)
            }
        }
    }

    private func optionsView(_ current: Question, options: [ExamOption]) -> some View {
        let type = typeOf(current)
        let expectedKeys = (verdict?.expectedKeys ?? []).map { $0.uppercased() }
        return VStack(spacing: 10) {
            ForEach(options, id: \.key) { option in
                let key = option.key ?? ""
                let isSelected = selected.contains(key)
                let showCorrect = verdict != nil && expectedKeys.contains(key.uppercased())
                Button {
                    choose(current, key: key, type: type)
                } label: {
                    HStack(spacing: 10) {
                        Text(key)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(showCorrect || isSelected ? .white : Tokens.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(showCorrect ? Tokens.success : (isSelected ? Tokens.primary : Tokens.surface))
                            .clipShape(Circle())
                        HtmlText(content: option.text ?? option.content, fontSize: 15)
                        Spacer(minLength: 0)
                        if showCorrect {
                            Text("正确答案")
                                .font(.system(size: 10))
                                .foregroundColor(Tokens.success)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        showCorrect
                            ? Tokens.successSoft
                            : (isSelected ? Tokens.primarySoft : Tokens.surfaceAlt.opacity(0.55))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(verdict != nil)
            }
        }
    }

    private func fillView(_ current: Question) -> some View {
        let blanks = max(current.blanks ?? 1, 1)
        return VStack(spacing: 10) {
            ForEach(0..<blanks, id: \.self) { i in
                HStack {
                    Text("第 \(i + 1) 空")
                        .font(.system(size: 13))
                        .foregroundColor(Tokens.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    TextField("请输入答案", text: Binding(
                        get: { fillInputs.indices.contains(i) ? fillInputs[i] : "" },
                        set: { updateFill(i, $0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .disabled(verdict != nil)
                }
            }
        }
    }

    private var essayView: some View {
        TextEditor(text: $essayText)
            .frame(minHeight: 140)
            .padding(6)
            .background(Tokens.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(verdict != nil)
    }

    private func verdictBox(_ verdict: PracticeVerdict) -> some View {
        let correct = verdict.correct == true
        let expectedText = verdict.expectedText ?? (verdict.expected ?? []).joined(separator: " / ")
        return VStack(alignment: .leading, spacing: 0) {
            Text(correct ? "回答正确" : "回答错误")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(correct ? Tokens.success : Tokens.danger)
            if !correct && !expectedText.isEmpty {
                Text("正确答案：\(expectedText)")
                    .font(.system(size: 13))
                    .foregroundColor(Tokens.success)
                    .padding(.top, 6)
            }
            if let analysis = verdict.analysis, !analysis.isEmpty {
                Text("解析")
                    .font(.system(size: 12))
                    .foregroundColor(Tokens.textSecondary)
                    .padding(.top, 10)
                RichText(content: analysis, fontSize: 13)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(correct ? Tokens.successSoft : Tokens.dangerSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func bottomBar(_ current: Question) -> some View {
        HStack(spacing: 10) {
            SecondaryButton(
                title: "上一题",
                enabled: index > 0 && verdict == nil
            ) {
                if index > 0 { index -= 1 }
            }
            if verdict == nil {
                PrimaryButton(
                    title: submitting ? "提交中…" : "提交本题",
                    loading: submitting
                ) {
                    submitCurrent(current)
                }
            } else {
                PrimaryButton(
                    title: index < questions.count - 1 ? "下一题" : "完成练习"
                ) {
                    next()
                }
            }
        }
        .padding(12)
        .background(Tokens.surface)
    }

    private func typeOf(_ question: Question?) -> String {
        guard let question = question else { return "" }
        if let type = question.type, !type.isEmpty { return type }
        return question.typeCode ?? ""
    }

    private func choose(_ current: Question, key: String, type: String) {
        guard verdict == nil, !key.isEmpty else { return }
        if type == "MULTIPLE" {
            if let i = selected.firstIndex(of: key) {
                selected.remove(at: i)
            } else {
                selected.append(key)
            }
        } else {
            selected = [key]
        }
    }

    private func updateFill(_ i: Int, _ value: String) {
        while fillInputs.count <= i {
            fillInputs.append("")
        }
        fillInputs[i] = value
    }

    private func submitCurrent(_ current: Question) {
        guard !submitting, verdict == nil else { return }
        let type = typeOf(current)
        let options = current.options ?? []
        var answerJson: String? = nil
        var answerText: String? = nil

        if !options.isEmpty {
            guard !selected.isEmpty else {
                toast = "请先作答本题"
                return
            }
            answerJson = encodeArray(selected)
        } else if type == "FILL" {
            guard fillInputs.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                toast = "请先作答本题"
                return
            }
            answerJson = encodeArray(fillInputs)
        } else {
            guard !essayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                toast = "请先作答本题"
                return
            }
            answerText = essayText
        }

        let questionId = current.questionId ?? current.paperQuestionId ?? ""
        submitting = true
        Task { @MainActor in
            do {
                let result = try await env.repository.practiceAnswer(
                    recordId: recordId,
                    body: PracticeAnswerRequest(
                        questionId: questionId,
                        answerJson: answerJson,
                        answerText: answerText
                    )
                )
                verdict = result
                answeredCount = result.answeredCount ?? (answeredCount + 1)
                correctCount = result.correctCount ?? (correctCount + (result.correct == true ? 1 : 0))
                wrongCount = result.wrongCount ?? (wrongCount + (result.correct == false ? 1 : 0))
            } catch {
                toast = (error as? ApiError)?.errorDescription ?? "提交失败"
            }
            submitting = false
        }
    }

    private func encodeArray(_ values: [String]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: values)) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private func next() {
        guard verdict != nil else { return }
        if index < questions.count - 1 {
            index += 1
        } else {
            showDone = true
        }
    }

    private func resetInputs() {
        let blanks = max(current?.blanks ?? 1, 1)
        selected = []
        fillInputs = Array(repeating: "", count: blanks)
        essayText = ""
        verdict = nil
    }

    private func load() async {
        loading = true
        error = nil
        do {
            let rec = try await env.repository.practiceState(recordId: recordId)
            record = rec
            answeredCount = rec.answeredCount ?? 0
            correctCount = rec.correctCount ?? 0
            wrongCount = rec.wrongCount ?? 0
            index = max(rec.currentIndex ?? 0, 0)
            resetInputs()
        } catch {
            self.error = (error as? ApiError)?.errorDescription ?? "加载失败"
        }
        loading = false
    }

    private func finishAndExit() {
        Task { @MainActor in
            do {
                _ = try await env.repository.practiceFinish(recordId: recordId)
                toast = "练习完成"
                dismiss()
            } catch {
                toast = (error as? ApiError)?.errorDescription ?? "完成失败"
            }
        }
    }

    private func abandonAndExit() {
        Task { @MainActor in
            _ = try? await env.repository.practiceAbandon(recordId: recordId)
            dismiss()
        }
    }
}

// MARK: - 错题集

struct WrongView: View {
    @EnvironmentObject var env: AppEnvironment

    @State private var source = ""
    @State private var reviewOnly = false
    @State private var expanded: Set<String> = []
    @State private var reload = 0
    @State private var toast: String?

    private let sourceOptions: [PracticeSourceOption] = [
        PracticeSourceOption(value: "", label: "全部"),
        PracticeSourceOption(value: "EXAM", label: "考试"),
        PracticeSourceOption(value: "PRACTICE", label: "练习")
    ]

    private var listKey: String {
        "\(source)|\(reviewOnly)|\(reload)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(sourceOptions) { option in
                    FilterChip(title: option.label, selected: source == option.value) {
                        source = option.value
                    }
                }
                Spacer(minLength: 0)
                SmallAction(text: reviewOnly ? "看全部" : "只看待复习") {
                    reviewOnly.toggle()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            RemoteContent(
                loader: {
                    try await env.repository.wrongQuestions(
                        sourceType: source.isEmpty ? nil : source,
                        includeMastered: reviewOnly ? false : nil
                    )
                },
                emptyCheck: { $0.isEmpty },
                emptyText: "太棒了，暂无错题"
            ) { list in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(list) { wrong in
                            wrongCard(wrong)
                        }
                    }
                    .padding(16)
                }
            }
            .id(listKey)
        }
        .pageBackground()
        .navigationTitle("我的错题集")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
    }

    @ViewBuilder
    private func wrongCard(_ wrong: WrongQuestion) -> some View {
        let type = wrong.typeCode ?? wrong.questionType ?? ""
        let isExpanded = expanded.contains(wrong.id ?? "")

        SectionCard(padding: 14) {
            HStack(spacing: 6) {
                TagPill(
                    text: Formatters.questionTypeLabel(type),
                    fg: Tokens.primary,
                    bg: Tokens.primarySoft
                )
                TagPill(
                    text: "错 \(wrong.wrongCount ?? 0) 次",
                    fg: Tokens.danger,
                    bg: Tokens.dangerSoft
                )
                Spacer(minLength: 0)
                TagPill(
                    text: wrong.mastered == true ? "已掌握" : "待复习",
                    fg: wrong.mastered == true ? Tokens.success : Tokens.warning,
                    bg: wrong.mastered == true ? Tokens.successSoft : Tokens.warningSoft
                )
            }

            Button {
                toggleExpand(wrong)
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    if let stem = wrong.stem, !stem.isEmpty {
                        HtmlText(content: stem, fontSize: 15)
                    } else {
                        Text("题目内容")
                            .font(.system(size: 15))
                            .foregroundColor(Tokens.textPrimary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Tokens.textTertiary)
                }
                .padding(.top, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let lastWrongAt = wrong.lastWrongAt, !lastWrongAt.isEmpty {
                Text(lastWrongAt)
                    .font(.system(size: 11))
                    .foregroundColor(Tokens.textTertiary)
                    .padding(.top, 5)
            }

            if isExpanded {
                if let options = wrong.options, !options.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                            optionRow(option)
                        }
                    }
                    .padding(.top, 10)
                }

                let answer = wrong.answerText ?? wrong.expectedText
                if let answer = answer, !answer.isEmpty {
                    Text("答案：\(answer)")
                        .font(.system(size: 13))
                        .foregroundColor(Tokens.textPrimary)
                        .padding(.top, 10)
                }

                if let analysis = wrong.analysis, !analysis.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("解析")
                            .font(.system(size: 11))
                            .foregroundColor(Tokens.textSecondary)
                        RichText(content: analysis, fontSize: 13)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Tokens.surfaceAlt.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.top, 10)
                }
            }

            HStack {
                SmallAction(
                    text: wrong.mastered == true ? "标记待复习" : "我已掌握",
                    color: wrong.mastered == true ? Tokens.textSecondary : Tokens.success
                ) {
                    toggleMaster(wrong)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 10)
        }
    }

    private func optionRow(_ option: WrongOption) -> some View {
        let correct = option.correct == true
        return HStack(spacing: 9) {
            Text(option.key ?? "")
                .font(.system(size: 11))
                .foregroundColor(correct ? .white : Tokens.textSecondary)
                .frame(width: 24, height: 24)
                .background(correct ? Tokens.success : Tokens.surface)
                .clipShape(Circle())
            HtmlText(content: option.text ?? option.content, fontSize: 14)
            Spacer(minLength: 0)
            if correct {
                Text("正确答案")
                    .font(.system(size: 11))
                    .foregroundColor(Tokens.success)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(correct ? Tokens.successSoft : Tokens.surfaceAlt.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func toggleExpand(_ wrong: WrongQuestion) {
        guard let id = wrong.id, !id.isEmpty else { return }
        if expanded.contains(id) {
            expanded.remove(id)
        } else {
            expanded.insert(id)
        }
    }

    private func toggleMaster(_ wrong: WrongQuestion) {
        guard let id = wrong.id, !id.isEmpty else { return }
        Task { @MainActor in
            do {
                if wrong.mastered == true {
                    _ = try await env.repository.unmasterWrong(id)
                    toast = "已标记待复习"
                } else {
                    _ = try await env.repository.masterWrong(id)
                    toast = "已标记掌握"
                }
                reload += 1
            } catch {
                toast = (error as? ApiError)?.errorDescription ?? "操作失败"
            }
        }
    }
}
