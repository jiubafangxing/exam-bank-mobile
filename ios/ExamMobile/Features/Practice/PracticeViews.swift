import SwiftUI

struct PracticeListView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                RemoteContent(loader: {
                    async let stats = env.repository.practiceStatistics()
                    async let sets = env.repository.practiceSets()
                    return (try await stats, try await sets)
                }) { data in
                    let (stats, sets) = data
                    SectionCard {
                        HStack {
                            StatCell(title: "练习次数", value: "\(stats.totalRecords ?? 0)")
                            StatCell(title: "完成", value: "\(stats.finishedRecords ?? 0)")
                            StatCell(title: "正确率", value: "\(Int((stats.averageAccuracy ?? 0) * 100))%")
                            StatCell(title: "题量", value: "\(stats.totalQuestions ?? 0)")
                        }
                    }
                    if sets.isEmpty {
                        EmptyStateView(text: "暂无练习题集")
                    } else {
                        ForEach(sets) { set in
                            NavigationLink(value: Route.practiceTaking(set.id ?? "")) {
                                SectionCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(set.name ?? "").font(.system(size: 16, weight: .semibold))
                                            if let desc = set.description, !desc.isEmpty {
                                                Text(desc).font(.system(size: 12)).foregroundColor(Tokens.textSecondary).lineLimit(1)
                                            }
                                            HStack(spacing: 12) {
                                                Text("\(set.questionCount ?? 0) 题").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                                if let score = set.totalScore {
                                                    Text("\(Formatters.scoreText(score)) 分").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                                }
                                            }
                                        }
                                        Spacer()
                                        TagPill(text: "开始练习")
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    NavigationLink(value: Route.practiceStats) {
                        Text("查看练习统计").font(.system(size: 13)).foregroundColor(Tokens.primary)
                    }
                }
            }
            .padding(16)
        }
        .pageBackground()
        .navigationTitle("在线练习")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatCell: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(Tokens.primary)
            Text(title).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PracticeStatsView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        RemoteContent(loader: { try await env.repository.practiceStatistics() }) { stats in
            ScrollView {
                VStack(spacing: 12) {
                    SectionCard {
                        HStack {
                            StatCell(title: "练习次数", value: "\(stats.totalRecords ?? 0)")
                            StatCell(title: "完成", value: "\(stats.finishedRecords ?? 0)")
                            StatCell(title: "正确率", value: "\(Int((stats.averageAccuracy ?? 0) * 100))%")
                        }
                        DividerLine().padding(.vertical, 12)
                        KeyValueRow(label: "累计做题", value: "\(stats.totalQuestions ?? 0)")
                        KeyValueRow(label: "答对", value: "\(stats.correctQuestions ?? 0)")
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

struct PracticeTakingView: View {
    @EnvironmentObject var env: AppEnvironment
    let setId: String
    @State private var record: PracticeRecord?
    @State private var index = 0
    @State private var selected: [String] = []
    @State private var verdict: PracticeVerdict?
    @State private var loading = true
    @State private var submitting = false
    @State private var error: String?
    @State private var toast: String?
    @Environment(\.dismiss) private var dismiss

    private var questions: [Question] {
        let list = record?.questions ?? []
        if !list.isEmpty { return list }
        if let q = record?.question { return [q] }
        return []
    }

    var body: some View {
        Group {
            if loading {
                LoadingView()
            } else if let error = error {
                VStack(spacing: 12) { ErrorBanner(message: error) }.padding(16)
            } else if let current = questions.indices.contains(index) ? questions[index] : nil {
                VStack(spacing: 0) {
                    HStack {
                        Text("\((record?.title ?? record?.setName) ?? "练习") · 第 \(record?.attemptNo ?? 1) 次")
                            .font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
                        Spacer()
                        Text("\(record?.answeredCount ?? (index + 1))/\(record?.questionCount ?? questions.count) · 对 \(record?.correctCount ?? 0) / 错 \(record?.wrongCount ?? 0)")
                            .font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                    }
                    .padding(16)
                    .background(Tokens.primarySoft)

                    ScrollView {
                        VStack(spacing: 12) {
                            practiceCard(current)
                            if let verdict = verdict {
                                SectionCard {
                                    Text(verdict.correct == true ? "回答正确" : "回答错误")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(verdict.correct == true ? Tokens.success : Tokens.danger)
                                    if let expected = verdict.expectedText, !expected.isEmpty {
                                        Text("正确答案：\(expected)")
                                            .font(.system(size: 13)).foregroundColor(Tokens.success).padding(.top, 6)
                                    }
                                    if let analysis = verdict.analysis, !analysis.isEmpty {
                                        Text("解析").font(.system(size: 12)).foregroundColor(Tokens.textSecondary).padding(.top, 8)
                                        RichText(content: analysis, fontSize: 13).padding(.top, 4)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }

                    HStack {
                        SecondaryButton(title: "上一题", enabled: index > 0 && verdict == nil) {
                            if index > 0 { index -= 1; selected = []; verdict = nil }
                        }
                        Spacer()
                        if verdict == nil {
                            Button {
                                submit(current)
                            } label: {
                                Text(submitting ? "提交中…" : "提交本题")
                                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                                    .padding(.horizontal, 20).frame(minHeight: 44)
                                    .background(selected.isEmpty ? Tokens.primary.opacity(0.4) : Tokens.primary)
                                    .clipShape(Capsule())
                            }
                            .disabled(submitting || selected.isEmpty)
                        } else {
                            Button {
                                next()
                            } label: {
                                Text(index < questions.count - 1 ? "下一题" : "完成")
                                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                                    .padding(.horizontal, 20).frame(minHeight: 44)
                                    .background(index < questions.count - 1 ? Tokens.primary : Tokens.success)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(12)
                    .background(Tokens.surface)
                }
            } else {
                EmptyStateView(text: "暂无题目")
            }
        }
        .pageBackground()
        .navigationTitle("在线练习")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .task { await load() }
    }

    @ViewBuilder
    private func practiceCard(_ question: Question) -> some View {
        let color = Tokens.typeColor(resolvedType(question))
        SectionCard {
            HStack(spacing: 8) {
                TagPill(text: Formatters.questionTypeLabel(resolvedType(question)), fg: color.fg, bg: color.bg)
                Text("\(Formatters.scoreText(question.score)) 分").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
            }
            RichText(content: question.stem, fontSize: 16).padding(.top, 12)
            VStack(spacing: 10) {
                ForEach(question.options ?? [], id: \.key) { option in
                    let isSel = selected.contains(option.key ?? "")
                    Button {
                        guard verdict == nil else { return }
                        let key = option.key ?? ""
                        if resolvedType(question) == "MULTIPLE" {
                            if let i = selected.firstIndex(of: key) { selected.remove(at: i) } else { selected.append(key) }
                        } else {
                            selected = [key]
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(option.key ?? "").font(.system(size: 14, weight: .bold))
                                .foregroundColor(isSel ? Tokens.primary : Tokens.textPrimary)
                            HtmlText(content: option.text ?? option.content, fontSize: 15)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isSel ? Tokens.primarySoft : Tokens.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 14)
        }
    }

    private func load() async {
        loading = true
        do {
            record = try await env.repository.practiceStart(setId: setId)
        } catch {
            self.error = (error as? ApiError)?.errorDescription ?? "加载失败"
        }
        loading = false
    }

    private func submit(_ question: Question) {
        guard !submitting, verdict == nil else { return }
        let json = (try? JSONSerialization.data(withJSONObject: selected))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        submitting = true
        Task {
            do {
                verdict = try await env.repository.practiceAnswer(
                    recordId: record?.recordId ?? "",
                    body: PracticeAnswerRequest(questionId: question.questionId ?? "", answerJson: json)
                )
            } catch {
                toast = (error as? ApiError)?.errorDescription ?? "提交失败"
            }
            submitting = false
        }
    }

    private func next() {
        guard verdict != nil else { return }
        if index < questions.count - 1 {
            index += 1
            selected = []
            verdict = nil
        } else {
            Task {
                do {
                    _ = try await env.repository.practiceFinish(recordId: record?.recordId ?? "")
                    toast = "练习完成"
                    dismiss()
                } catch {
                    toast = (error as? ApiError)?.errorDescription ?? "完成失败"
                }
            }
        }
    }
}

struct WrongView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var includeMastered = false
    @State private var reload = 0
    @State private var toast: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Toggle("包含已掌握", isOn: $includeMastered)
                    .font(.system(size: 13))
                    .padding(.horizontal, 4)

                RemoteContent(
                    loader: { try await env.repository.wrongQuestions(includeMastered: includeMastered) },
                    emptyCheck: { $0.isEmpty }
                ) { list in
                    ForEach(list) { wrong in
                        SectionCard {
                            HStack {
                                TagPill(text: Formatters.questionTypeLabel(wrong.questionType))
                                Text("错 \(wrong.wrongCount ?? 0) 次").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                Spacer()
                                Button {
                                    Task {
                                        do {
                                            if wrong.mastered == true {
                                                _ = try await env.repository.unmasterWrong(wrong.id ?? "")
                                            } else {
                                                _ = try await env.repository.masterWrong(wrong.id ?? "")
                                            }
                                            reload += 1
                                        } catch {
                                            toast = (error as? ApiError)?.errorDescription ?? "操作失败"
                                        }
                                    }
                                } label: {
                                    Text(wrong.mastered == true ? "取消掌握" : "标记掌握")
                                        .font(.system(size: 12))
                                        .foregroundColor(wrong.mastered == true ? Tokens.textSecondary : Tokens.primary)
                                }
                                .buttonStyle(.plain)
                            }
                            Text(wrong.stem ?? "题目内容")
                                .font(.system(size: 15))
                                .lineLimit(3)
                                .padding(.top, 8)
                            if wrong.mastered == true {
                                TagPill(text: "已掌握", fg: Tokens.success, bg: Tokens.successSoft).padding(.top, 6)
                            }
                        }
                    }
                }
                .id(reload)
            }
            .padding(16)
        }
        .pageBackground()
        .navigationTitle("我的错题集")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
    }
}


private func resolvedType(_ question: Question) -> String {
    if let type = question.type, !type.isEmpty { return type }
    return question.typeCode ?? ""
}
