import Foundation
import SwiftUI
import PhotosUI

// MARK: - 成绩

struct ScoreView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var records: [ScoreRecord] = []
    @State private var page = 1
    @State private var total = 0
    @State private var loading = true
    @State private var loadingMore = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                GradientHero {
                    Text("我的成绩")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(.white)
                    Text("每一次考试都是成长的刻度，继续稳稳向前。")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.88))
                        .padding(.top, 5)
                }
                SectionHeader(title: "成绩记录")
                if loading && records.isEmpty {
                    LoadingView()
                } else if let error = error, records.isEmpty {
                    ErrorBanner(message: error).padding(.horizontal, 16)
                } else if records.isEmpty {
                    EmptyStateView(text: "暂无成绩记录")
                } else {
                    ForEach(records) { score in
                        SectionCard {
                            HStack {
                                Text(score.examName ?? "考试").font(.system(size: 15, weight: .semibold)).foregroundColor(Tokens.textPrimary).lineLimit(1)
                                Spacer()
                                Text(Formatters.scoreText(score.totalScore)).font(.system(size: 24, weight: .bold)).foregroundColor(Tokens.primary)
                            }
                            HStack {
                                Text("客观题 \(Formatters.scoreText(score.objectiveScore))").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                Text("主观题 \(Formatters.scoreText(score.subjectiveScore))").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                Spacer()
                                if score.status == "PUBLISHED" {
                                    TagPill(text: "已发布", fg: Tokens.success, bg: Tokens.successSoft)
                                } else {
                                    TagPill(text: "待发布", fg: Tokens.warning, bg: Tokens.warningSoft)
                                }
                            }
                            if let published = score.publishedAt, !published.isEmpty {
                                Text("发布时间：\(published)").font(.system(size: 11)).foregroundColor(Tokens.textTertiary)
                            }
                        }
                    }
                    if records.count < total {
                        SecondaryButton(title: loadingMore ? "加载中…" : "加载更多") {
                            guard !loadingMore else { return }
                            Task { await load(page + 1) }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(16)
        }
        .pageBackground()
        .navigationTitle("我的成绩")
        .navigationBarTitleDisplayMode(.inline)
        .task { if records.isEmpty { await load(1) } }
    }

    private func load(_ nextPage: Int) async {
        if nextPage == 1 { loading = true } else { loadingMore = true }
        defer { loading = false; loadingMore = false }
        do {
            let res = try await env.repository.scores(page: nextPage, size: 20)
            let recs = res.records ?? []
            records = nextPage == 1 ? recs : records + recs
            total = res.total ?? records.count
            page = nextPage
            error = nil
        } catch {
            self.error = (error as? ApiError)?.errorDescription ?? "加载失败"
        }
    }
}

struct AnalysisView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        RemoteContent(loader: { try await env.repository.analysis() }) { a in
            let weak = (a.weakPoints?.isEmpty == false ? (a.weakPoints ?? []) : (a.weakestTypes ?? []))
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GradientHero {
                        Text("学习分析")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(.white)
                        Text("看清优势与薄弱点，把时间用在最需要的地方。")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.88))
                            .padding(.top, 5)
                    }
                    SectionHeader(title: "学习总览")
                    HStack(spacing: 10) {
                        StatTile(
                            label: "总考试",
                            value: "\(a.totalExams ?? 0)",
                            tint: Tokens.primary,
                            bg: Tokens.primarySoft
                        )
                        StatTile(
                            label: "已参加",
                            value: "\(a.attendedExams ?? a.totalExams ?? 0)",
                            tint: Tokens.accent,
                            bg: Tokens.accentSoft
                        )
                        StatTile(
                            label: "平均分",
                            value: Formatters.scoreText(a.avgScore ?? a.averageScore),
                            tint: Tokens.amber,
                            bg: Tokens.amberSoft
                        )
                        StatTile(
                            label: "及格率",
                            value: "\(Int((a.passRate ?? 0) * 100))%",
                            tint: Tokens.success,
                            bg: Tokens.successSoft
                        )
                    }
                    SectionCard {
                        HStack(spacing: 10) {
                            StatTile(
                                label: "最低分",
                                value: Formatters.scoreText(a.lowestScore),
                                tint: Tokens.coral,
                                bg: Tokens.coralSoft
                            )
                            StatTile(
                                label: "最高分",
                                value: Formatters.scoreText(a.highestScore),
                                tint: Tokens.violet,
                                bg: Tokens.violetSoft
                            )
                        }
                        if let minutes = a.studyMinutes, minutes > 0 {
                            KeyValueRow(label: "学习时长", value: "\(minutes) 分钟").padding(.top, 8)
                        }
                    }
                    if !weak.isEmpty {
                        SectionTitle("薄弱知识点")
                        SectionCard {
                            HStack(spacing: 8) {
                                ForEach(weak, id: \.self) { t in
                                    TagPill(text: Formatters.questionTypeLabel(t), fg: Tokens.warning, bg: Tokens.warningSoft)
                                }
                            }
                        }
                    }
                    if let trend = a.trend, !trend.isEmpty {
                        SectionTitle("成绩趋势")
                        SectionCard {
                            ForEach(trend) { point in
                                HStack {
                                    Text(point.label ?? "").font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
                                    Spacer()
                                    Text(Formatters.scoreText(point.value)).font(.system(size: 14, weight: .semibold)).foregroundColor(Tokens.primary)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .pageBackground()
        .navigationTitle("个人分析")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AnalysisCell: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 19, weight: .bold)).foregroundColor(Tokens.primary)
            Text(title).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 排行榜

struct RankingView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("排行", selection: $tab) {
                Text("积分榜").tag(0)
                Text("班级榜").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(16)

            RemoteContent(
                loader: { tab == 0 ? try await env.repository.pointsRanking() : try await env.repository.classRanking() },
                emptyCheck: { $0.isEmpty }
            ) { rows in
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(rows) { row in
                            let isClass = tab == 1
                            let title = isClass
                                ? (row.className ?? row.classId ?? "")
                                : ((row.name?.isEmpty == false) ? (row.name ?? "") : (row.memberNo ?? row.userId ?? ""))
                            let subtitle = isClass ? "\(row.participants ?? 0) 人参考" : (row.levelCode ?? "")
                            let value = isClass ? Formatters.scoreText(row.averageScore ?? row.score) : "\(row.points ?? 0) 分"
                            SectionCard {
                                HStack {
                                    Text("\(row.rank ?? 0)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor((row.rank ?? 0) <= 3 ? Tokens.warning : Tokens.textSecondary)
                                        .frame(width: 36, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(title).font(.system(size: 15, weight: row.isMe == true ? .bold : .medium))
                                        if !subtitle.isEmpty {
                                            Text(subtitle).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(Tokens.primary)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .id(tab)
        }
        .pageBackground()
        .navigationTitle("排行榜")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClassView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var tab = 0
    @State private var keyword = ""
    @State private var paidFilter = ""      // "", "false", "true"
    @State private var sort = ""            // "", priceAsc, priceDesc, students, newest
    @State private var reload = 0
    @State private var showPasswordDialog = false
    @State private var password = ""
    @State private var pendingPasswordClass: ClassItem?
    @State private var paidTarget: ClassItem?
    @State private var toast: String?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    TextField("搜索班级", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { reload += 1 }
                    SecondaryButton(title: "搜索") { reload += 1 }
                }
                HStack(spacing: 8) {
                    Picker("付费", selection: $paidFilter) {
                        Text("全部").tag("")
                        Text("免费").tag("false")
                        Text("付费").tag("true")
                    }
                    .pickerStyle(.menu)
                    Picker("排序", selection: $sort) {
                        Text("默认").tag("")
                        Text("价格↑").tag("priceAsc")
                        Text("价格↓").tag("priceDesc")
                        Text("人数").tag("students")
                        Text("最新").tag("newest")
                    }
                    .pickerStyle(.menu)
                    Spacer()
                }
                Picker("班级", selection: $tab) {
                    Text("全部班级").tag(0)
                    Text("我的班级").tag(1)
                }
                .pickerStyle(.segmented)
            }
            .padding(16)

            RemoteContent(
                loader: {
                    if tab == 1 {
                        return try await env.repository.myClasses()
                    }
                    var params: [String: String] = [:]
                    if !keyword.isEmpty { params["keyword"] = keyword }
                    if !paidFilter.isEmpty { params["paid"] = paidFilter }
                    if !sort.isEmpty { params["sort"] = sort }
                    return try await env.repository.classes(params)
                },
                emptyCheck: { $0.isEmpty },
                emptyText: "暂无班级"
            ) { list in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(list) { cls in
                            SectionCard {
                                HStack(spacing: 12) {
                                    if let cover = cls.coverUrl, let url = URL(string: cover) {
                                        AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Tokens.surfaceAlt }
                                            .frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(cls.name ?? "").font(.system(size: 16, weight: .semibold))
                                        Text(cls.description ?? "暂无简介").font(.system(size: 12)).foregroundColor(Tokens.textSecondary).lineLimit(2)
                                        HStack(spacing: 8) {
                                            TagPill(text: joinModeText(cls.joinMode))
                                            if (cls.price ?? 0) > 0 {
                                                Text("¥\(Formatters.scoreText(cls.price))").font(.system(size: 12)).foregroundColor(Tokens.danger)
                                            }
                                            Text("\(cls.studentCount ?? cls.memberCount ?? 0) 人").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if cls.joined == true {
                                        TagPill(text: "已加入", fg: Tokens.success, bg: Tokens.successSoft)
                                    } else if cls.joinStatus == "PENDING" {
                                        TagPill(text: "审核中", fg: Tokens.warning, bg: Tokens.warningSoft)
                                    } else {
                                        SecondaryButton(title: "加入") { join(cls) }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .id("\(tab)-\(paidFilter)-\(sort)-\(reload)")
        }
        .pageBackground()
        .navigationTitle("班级")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .alert("班级密码", isPresented: $showPasswordDialog) {
            TextField("请输入班级加入密码", text: $password)
            Button("加入") {
                if let target = pendingPasswordClass {
                    doJoin(target, password: password)
                }
                pendingPasswordClass = nil
            }
            Button("取消", role: .cancel) { pendingPasswordClass = nil }
        }
        .alert("付费加入", isPresented: Binding(
            get: { paidTarget != nil },
            set: { if !$0 { paidTarget = nil } }
        )) {
            Button("确认支付") {
                if let target = paidTarget { payAndJoin(target) }
                paidTarget = nil
            }
            Button("取消", role: .cancel) { paidTarget = nil }
        } message: {
            Text("需支付 ¥\(Formatters.scoreText(paidTarget?.price))，确认支付？")
        }
    }

    private func join(_ cls: ClassItem) {
        switch cls.joinMode {
        case "PAID": paidTarget = cls
        case "PASSWORD": pendingPasswordClass = cls; password = ""; showPasswordDialog = true
        default: doJoin(cls)
        }
    }

    private func doJoin(_ cls: ClassItem, password: String? = nil) {
        Task {
            do {
                _ = try await env.repository.joinClass(cls.id ?? "", password: password)
                toast = "已加入"
                reload += 1
            } catch {
                toast = (error as? ApiError)?.errorDescription ?? "加入失败"
            }
        }
    }

    private func payAndJoin(_ cls: ClassItem) {
        Task {
            do {
                let order = try await env.repository.createOrder(bizType: "CLASS", bizId: cls.id ?? "")
                _ = try await env.repository.payOrder(order.id ?? "")
                _ = try await env.repository.joinClass(cls.id ?? "")
                toast = "已加入"
                reload += 1
            } catch {
                toast = (error as? ApiError)?.errorDescription ?? "加入失败"
            }
        }
    }

    private func joinModeText(_ mode: String?) -> String {
        switch mode {
        case "FREE": return "免费加入"
        case "PASSWORD": return "密码加入"
        case "PAID": return "付费加入"
        case "APPROVAL": return "审核加入"
        default: return "加入"
        }
    }
}

struct ExamGroupView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var collapsed: Set<String> = []

    var body: some View {
        RemoteContent(loader: { try await env.repository.examGroups() }, emptyCheck: { $0.isEmpty }) { groups in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(groups) { group in
                        SectionCard {
                            Button {
                                let key = group.id ?? ""
                                if collapsed.contains(key) { collapsed.remove(key) } else { collapsed.insert(key) }
                            } label: {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(group.name ?? "").font(.system(size: 16, weight: .semibold)).foregroundColor(Tokens.textPrimary)
                                        Text("\((group.groupType == "ALL_PASS") ? "通关：全部通过" : "闯关：按顺序解锁") · 及格线 \(Formatters.scoreText(group.passScore))")
                                            .font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                    }
                                    Spacer()
                                    if group.passed == true {
                                        TagPill(text: "已通关", fg: Tokens.success, bg: Tokens.successSoft)
                                    } else if (group.passedCount ?? 0) > 0 {
                                        TagPill(text: "\(group.passedCount ?? 0)/\(group.requiredCount ?? group.examCount ?? 0)", fg: Tokens.warning, bg: Tokens.warningSoft)
                                    } else {
                                        TagPill(text: "0/\(group.requiredCount ?? group.examCount ?? 0)")
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if !collapsed.contains(group.id ?? "") {
                                let items = group.items ?? []
                                if !items.isEmpty {
                                    VStack(spacing: 0) {
                                        ForEach(items) { item in
                                            HStack(spacing: 10) {
                                                Text("\(item.sortNo ?? 0)")
                                                    .font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                                    .frame(width: 24, height: 24).background(Tokens.surfaceAlt).clipShape(Circle())
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.examName ?? item.examId ?? "").font(.system(size: 14))
                                                    Text("及格 \(Formatters.scoreText(item.passScore))").font(.system(size: 11)).foregroundColor(Tokens.textSecondary)
                                                }
                                                Spacer()
                                                let tag = groupItemTag(item.status)
                                                TagPill(text: tag.0, fg: tag.1, bg: tag.2)
                                            }
                                            .padding(.vertical, 6)
                                        }
                                    }
                                    .padding(.top, 8)
                                } else {
                                    ProgressView(value: Double(group.completedCount ?? 0), total: Double(max(group.examCount ?? 1, 1)))
                                        .tint(Tokens.primary).padding(.top, 8)
                                    Text("共 \(group.examCount ?? 0) 场 · 已完成 \(group.completedCount ?? 0) 场")
                                        .font(.system(size: 12)).foregroundColor(Tokens.textSecondary).padding(.top, 4)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .pageBackground()
        .navigationTitle("考试组进度")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func groupItemTag(_ status: String?) -> (String, Color, Color) {
        switch (status ?? "").uppercased() {
        case "PASSED": return ("已通过", Tokens.success, Tokens.successSoft)
        case "FAILED": return ("未通过", Tokens.danger, Tokens.dangerSoft)
        case "AVAILABLE": return ("可参加", Tokens.primary, Tokens.primarySoft)
        case "LOCKED": return ("未解锁", Tokens.warning, Tokens.warningSoft)
        case "NOT_PUBLISHED": return ("成绩未发布", Tokens.warning, Tokens.warningSoft)
        default: return (status ?? "", Tokens.textSecondary, Tokens.surfaceAlt)
        }
    }
}

struct MemberView: View {
    @EnvironmentObject var env: AppEnvironment
    let pendingBizType: String?
    let pendingBizId: String?

    @State private var reload = 0
    @State private var toast: String?
    @State private var buying = false
    @State private var handledPending = false

    init(pendingBizType: String? = nil, pendingBizId: String? = nil) {
        self.pendingBizType = pendingBizType
        self.pendingBizId = pendingBizId
    }

    var body: some View {
        RemoteContent(loader: {
            async let profile = env.repository.memberProfile()
            async let levels = env.repository.memberLevels()
            async let orders = env.repository.orders()
            return (try await profile, try await levels, try await orders)
        }) { data in
            let (profile, levels, orders) = data
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GradientHero(gradient: Tokens.goldGradient) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(profile.realName ?? "我") · \(memberLevelText(profile))")
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundColor(.white)
                                Text(memberExpiryText(profile))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.90))
                            }
                            Spacer(minLength: 0)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(profile.pointsBalance ?? profile.points ?? 0)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                Text("积分余额")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.white.opacity(0.85))
                            }
                        }
                    }

                    SectionHeader(title: "会员等级")
                    if levels.isEmpty {
                        EmptyStateView(text: "暂无在售等级")
                    } else {
                        ForEach(levels) { level in
                            SectionCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(level.name ?? "")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Tokens.textPrimary)
                                        Text("\(level.durationDays ?? 0) 天 · \(level.description ?? "")")
                                            .font(.system(size: 12))
                                            .foregroundColor(Tokens.textSecondary)
                                    }
                                    Spacer()
                                    Text("¥\(Formatters.scoreText(level.price))")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Tokens.danger)
                                }
                                SecondaryButton(title: buying ? "处理中…" : "立即开通") {
                                    guard !buying, let code = level.code else { return }
                                    buying = true
                                    Task { @MainActor in
                                        do {
                                            let order = try await env.repository.createOrder(bizType: "VIP", bizId: code)
                                            _ = try await env.repository.payOrder(order.id ?? "")
                                            toast = "开通成功"
                                            reload += 1
                                        } catch {
                                            toast = (error as? ApiError)?.errorDescription ?? "开通失败"
                                        }
                                        buying = false
                                    }
                                }
                                .disabled(buying)
                                .padding(.top, 8)
                            }
                        }
                    }

                    SectionHeader(title: "我的订单")
                    if orders.isEmpty {
                        EmptyStateView(text: "暂无订单")
                    } else {
                        ForEach(orders) { order in
                            SectionCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(
                                            bizText(order.bizType)
                                                + ((order.bizType == "VIP" && !(order.bizId ?? "").isEmpty) ? " / \(order.bizId!)" : "")
                                        )
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Tokens.textPrimary)
                                        Text("\(order.orderNo ?? "") · \(order.createdAt ?? "")")
                                            .font(.system(size: 11))
                                            .foregroundColor(Tokens.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("¥\(Formatters.scoreText(order.amount))")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Tokens.danger)
                                        TagPill(
                                            text: Formatters.orderStatusLabel(order.status),
                                            fg: orderTag(order.status).0,
                                            bg: orderTag(order.status).1
                                        )
                                    }
                                }
                                if ["CREATED", "UNPAID", "PENDING"].contains(order.status ?? "") {
                                    HStack(spacing: 12) {
                                        SecondaryButton(title: "继续支付") {
                                            Task { @MainActor in
                                                do {
                                                    _ = try await env.repository.payOrder(order.id ?? "")
                                                    toast = "支付成功"
                                                    reload += 1
                                                } catch {
                                                    toast = (error as? ApiError)?.errorDescription ?? "支付失败"
                                                }
                                            }
                                        }
                                        SecondaryButton(title: "取消") {
                                            Task { @MainActor in
                                                do {
                                                    _ = try await env.repository.cancelOrder(order.id ?? "")
                                                    toast = "已取消"
                                                    reload += 1
                                                } catch {
                                                    toast = (error as? ApiError)?.errorDescription ?? "取消失败"
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .id(reload)
        .pageBackground()
        .navigationTitle("会员中心")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .task { await handlePendingOrder() }
    }

    @MainActor
    private func handlePendingOrder() async {
        guard !handledPending else { return }
        guard let bizType = pendingBizType, !bizType.isEmpty,
              let bizId = pendingBizId, !bizId.isEmpty else { return }
        handledPending = true
        do {
            let all = try await env.repository.orders()
            var order = all.first {
                $0.bizType == bizType
                    && $0.bizId == bizId
                    && ["CREATED", "PAID"].contains($0.status ?? "")
            }
            if order == nil {
                order = try await env.repository.createOrder(bizType: bizType, bizId: bizId)
            }
            if let order = order, order.status != "PAID" {
                _ = try await env.repository.payOrder(order.id ?? "")
            }
            toast = "支付成功"
            reload += 1
        } catch {
            toast = (error as? ApiError)?.errorDescription ?? "支付失败"
        }
    }

    private func memberLevelText(_ profile: MemberProfile) -> String {
        if let name = profile.levelName, !name.isEmpty { return name }
        if profile.levelCode == "BASIC" || profile.levelCode == nil { return "基础会员" }
        return profile.levelCode ?? "会员"
    }

    private func memberExpiryText(_ profile: MemberProfile) -> String {
        if let expire = profile.vipExpireAt, !expire.isEmpty {
            return "VIP 有效期至 \(expire)"
        }
        if let code = profile.levelCode, code != "BASIC" {
            return "长期有效"
        }
        return "基础会员，购买等级享专属考试与练习"
    }

    private func bizText(_ biz: String?) -> String {
        switch biz {
        case "EXAM": return "考试订单"
        case "PRACTICE": return "练习订单"
        case "CLASS": return "班级订单"
        case "VIP": return "会员订单"
        default: return biz ?? "订单"
        }
    }

    private func orderTag(_ status: String?) -> (Color, Color) {
        switch status {
        case "PAID": return (Tokens.success, Tokens.successSoft)
        case "CREATED", "UNPAID", "PENDING": return (Tokens.warning, Tokens.warningSoft)
        case "REFUNDED": return (Tokens.danger, Tokens.dangerSoft)
        default: return (Tokens.textSecondary, Tokens.surfaceAlt)
        }
    }
}

struct NotificationView: View {
    @EnvironmentObject var env: AppEnvironment
    @Environment(\.openURL) private var openURL

    @State private var reload = 0
    @State private var toast: String?

    var body: some View {
        RemoteContent(
            loader: { try await env.repository.notifications() },
            emptyCheck: { $0.isEmpty },
            emptyText: "暂无通知"
        ) { list in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(list) { item in
                        SectionCard(padding: 14) {
                            notificationContent(item)
                        }
                    }
                }
                .padding(16)
            }
        }
        .id(reload)
        .pageBackground()
        .navigationTitle("消息通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("全部已读") {
                    Task { @MainActor in
                        _ = try? await env.repository.markAllNotificationsRead()
                        reload += 1
                    }
                }
                .font(.system(size: 13))
            }
        }
        .toast($toast)
    }

    @ViewBuilder
    private func notificationContent(_ item: NotificationItem) -> some View {
        let link = item.linkUrl ?? ""
        if !link.isEmpty && link.lowercased().hasPrefix("http") {
            Button {
                markRead(item, reloadList: true)
                if let url = URL(string: link) { openURL(url) }
            } label: {
                notificationRow(item, showChevron: true)
            }
            .buttonStyle(.plain)
        } else if !link.isEmpty {
            NavigationLink(value: notificationRoute(link)) {
                notificationRow(item, showChevron: true)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                markRead(item, reloadList: false)
            })
        } else {
            Button {
                markRead(item, reloadList: true)
            } label: {
                notificationRow(item, showChevron: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func notificationRow(_ item: NotificationItem, showChevron: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                if item.read != true {
                    Circle()
                        .fill(Tokens.danger)
                        .frame(width: 7, height: 7)
                        .padding(.top, 5)
                }
                Text(item.title ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Tokens.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if let type = item.type, !type.isEmpty {
                    notificationTypePill(type)
                }
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Tokens.textTertiary)
                        .padding(.top, 3)
                }
            }
            if let content = item.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 12))
                    .foregroundColor(Tokens.textSecondary)
                    .lineLimit(3)
            }
            if let created = item.createdAt, !created.isEmpty {
                Text(created)
                    .font(.system(size: 11))
                    .foregroundColor(Tokens.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func notificationTypePill(_ type: String) -> some View {
        switch type.uppercased() {
        case "APPEAL_RESULT":
            TagPill(text: "申诉", fg: Tokens.warning, bg: Tokens.warningSoft)
        case "EXAM_PUBLISH":
            TagPill(text: "考试", fg: Tokens.primary, bg: Tokens.primarySoft)
        case "SYSTEM":
            TagPill(text: "系统", fg: Tokens.slate, bg: Tokens.slateSoft)
        default:
            TagPill(text: "通知", fg: Tokens.textSecondary, bg: Tokens.surfaceAlt)
        }
    }

    private func notificationRoute(_ link: String) -> Route {
        let lower = link.lowercased()
        if lower.contains("practice") { return .practiceList }
        if lower.contains("member") { return .member }
        if lower.contains("score") { return .scores }
        if lower.contains("exam") { return .examList }
        return .notifications
    }

    private func markRead(_ item: NotificationItem, reloadList: Bool) {
        guard item.read != true else { return }
        Task { @MainActor in
            _ = try? await env.repository.markNotificationRead(item.id ?? "")
            if reloadList { reload += 1 }
        }
    }
}

// MARK: - 日历

struct CalendarView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        RemoteContent(
            loader: { try await env.repository.calendar() },
            emptyCheck: { $0.isEmpty },
            emptyText: "暂无安排"
        ) { list in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    GradientHero {
                        Text("考试日历")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(.white)
                        Text("考试与学习安排一目了然，提前规划每一天。")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.88))
                            .padding(.top, 5)
                    }
                    SectionHeader(title: "日程安排")
                    ForEach(list) { item in
                        SectionCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title ?? "").font(.system(size: 15, weight: .medium))
                                    Text([item.date, item.startTime, item.endTime].compactMap { $0 }.joined(separator: " "))
                                        .font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                }
                                Spacer()
                                if let type = item.type, !type.isEmpty {
                                    TagPill(text: type)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .pageBackground()
        .navigationTitle("考试日历")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 申诉

struct AppealView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var showDialog = false
    @State private var examId = ""
    @State private var reason = ""
    @State private var reload = 0
    @State private var toast: String?

    var body: some View {
        RemoteContent(loader: { try await env.repository.appeals() }, emptyCheck: { $0.isEmpty }) { list in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(list) { appeal in
                        SectionCard {
                            HStack {
                                Text(appeal.examName ?? appeal.examId ?? "考试").font(.system(size: 15, weight: .medium))
                                Spacer()
                                TagPill(text: appeal.status ?? "")
                            }
                            if let reason = appeal.reason, !reason.isEmpty {
                                Text(reason).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                            }
                            if let reply = appeal.reply, !reply.isEmpty {
                                Text("回复：\(reply)").font(.system(size: 12)).foregroundColor(Tokens.success)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .id(reload)
        .pageBackground()
        .navigationTitle("成绩申诉")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("发起申诉") { showDialog = true }.font(.system(size: 13))
            }
        }
        .alert("发起申诉", isPresented: $showDialog) {
            TextField("考试 ID", text: $examId)
            TextField("申诉理由", text: $reason)
            Button("提交") {
                guard !examId.isEmpty, !reason.isEmpty else { toast = "请填写完整"; return }
                Task {
                    do {
                        _ = try await env.repository.createAppeal(examId: examId, reason: reason)
                        toast = "已提交"
                        examId = ""; reason = ""
                        reload += 1
                    } catch {
                        toast = (error as? ApiError)?.errorDescription ?? "提交失败"
                    }
                }
            }
            Button("取消", role: .cancel) {}
        }
        .toast($toast)
    }
}

// MARK: - 人脸

struct FaceView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var status: FaceStatus?
    @State private var logs: [FaceLog] = []
    @State private var photoUrl = ""
    @State private var verifyPhotoUrl = ""
    @State private var examId = ""
    @State private var liveness = "PASS"
    @State private var showCollectPicker = false
    @State private var showVerifyPicker = false
    @State private var collectItem: PhotosPickerItem?
    @State private var verifyItem: PhotosPickerItem?
    @State private var loading = true
    @State private var uploading = false
    @State private var toast: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if loading {
                    LoadingView()
                } else if let status = status {
                    SectionCard {
                        KeyValueRow(label: "照片状态", value: status.photo?.status ?? (status.collected == true ? "已采集" : "未采集"))
                        KeyValueRow(label: "最近核验", value: status.latestVerify?.result ?? (status.verified == true ? "PASS" : "无"))
                        KeyValueRow(label: "是否必需", value: status.required == true ? "是" : "否")
                        if status.livenessRequired == true {
                            KeyValueRow(label: "活体检测", value: "需完成")
                        }
                        if let message = status.message, !message.isEmpty {
                            Text(message).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                        }
                    }
                }

                SectionCard {
                    Text("照片采集").font(.system(size: 14, weight: .semibold))
                    HStack(spacing: 12) {
                        SecondaryButton(title: uploading ? "上传中…" : "拍照/选择照片") { showCollectPicker = true }
                            .disabled(uploading)
                        SecondaryButton(title: "提交采集") {
                            guard !photoUrl.isEmpty else { toast = "请先上传照片"; return }
                            Task {
                                do { _ = try await env.repository.faceCollect(photoUrl: photoUrl); toast = "已提交，等待审核"; await load() }
                                catch { toast = (error as? ApiError)?.errorDescription ?? "提交失败" }
                            }
                        }
                    }
                    .padding(.top, 8)
                    if let url = URL(string: photoUrl), !photoUrl.isEmpty {
                        AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Tokens.surfaceAlt }
                            .frame(maxWidth: .infinity).frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.top, 8)
                    }
                }

                SectionCard {
                    Text("考前核验").font(.system(size: 14, weight: .semibold))
                    TextField("考试 ID（可选）", text: $examId)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 8)
                    HStack(spacing: 12) {
                        SecondaryButton(title: uploading ? "上传中…" : "现场拍照/选择照片") { showVerifyPicker = true }
                            .disabled(uploading)
                    }
                    .padding(.top, 8)
                    if let url = URL(string: verifyPhotoUrl), !verifyPhotoUrl.isEmpty {
                        AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Tokens.surfaceAlt }
                            .frame(maxWidth: .infinity).frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.top, 8)
                    }
                    HStack {
                        Text("活体检测").font(.system(size: 13)).foregroundColor(Tokens.textSecondary)
                        Picker("活体检测", selection: $liveness) {
                            Text("检测通过").tag("PASS")
                            Text("未通过").tag("FAIL")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.top, 8)
                    PrimaryButton(title: "开始核验") {
                        Task {
                            do {
                                _ = try await env.repository.faceVerify(FaceVerifyRequest(
                                    photoUrl: verifyPhotoUrl.isEmpty ? nil : verifyPhotoUrl,
                                    examId: examId.isEmpty ? nil : examId,
                                    livenessStatus: liveness
                                ))
                                toast = "已核验"
                                await load()
                            } catch {
                                toast = (error as? ApiError)?.errorDescription ?? "核验失败"
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                SectionTitle("核验记录")
                if logs.isEmpty {
                    EmptyStateView(text: "暂无记录")
                } else {
                    SectionCard {
                        ForEach(logs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.result ?? "-").font(.system(size: 13))
                                    Text("\(log.verifiedAt ?? log.createdAt ?? "")" + ((log.livenessStatus?.isEmpty == false) ? " · 活体 \(log.livenessStatus!)" : ""))
                                        .font(.system(size: 11)).foregroundColor(Tokens.textSecondary)
                                }
                                Spacer()
                                Text(log.similarity.map { "\($0)%" } ?? "-").font(.system(size: 13)).foregroundColor(Tokens.primary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(16)
        }
        .pageBackground()
        .navigationTitle("人脸核验")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .photosPicker(isPresented: $showCollectPicker, selection: $collectItem, matching: .images)
        .photosPicker(isPresented: $showVerifyPicker, selection: $verifyItem, matching: .images)
        .onChange(of: collectItem?.itemIdentifier) { _ in
            guard let item = collectItem else { return }
            upload(item) { photoUrl = $0 }
        }
        .onChange(of: verifyItem?.itemIdentifier) { _ in
            guard let item = verifyItem else { return }
            upload(item) { verifyPhotoUrl = $0 }
        }
        .toast($toast)
    }

    private func load() async {
        loading = true
        do {
            status = try await env.repository.faceStatus()
            logs = try await env.repository.faceLogs()
        } catch {
            toast = (error as? ApiError)?.errorDescription ?? "加载失败"
        }
        loading = false
    }

    private func upload(_ item: PhotosPickerItem, assign: @escaping (String) -> Void) {
        uploading = true
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    let resp = try await env.repository.faceUpload(data: data)
                    assign(resp.url ?? "")
                    toast = "照片已上传"
                }
            } catch {
                toast = (error as? ApiError)?.errorDescription ?? "上传失败"
            }
            uploading = false
        }
    }
}

struct DeviceView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var reload = 0
    @State private var toast: String?
    private let deviceId = TokenStore.deviceId()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                RemoteContent(loader: { try await env.repository.deviceAuth() }) { status in
                    SectionCard {
                        KeyValueRow(label: "授权状态", value: status.authorized == true ? "已授权" : "未授权")
                        if let name = status.deviceName, !name.isEmpty { KeyValueRow(label: "设备", value: name) }
                        if let message = status.message, !message.isEmpty {
                            Text(message).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                        }
                    }
                }
                .id(reload)
                SectionCard {
                    Text("本机设备 ID").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                    Text(deviceId).font(.system(size: 12)).foregroundColor(Tokens.textPrimary)
                    HStack(spacing: 12) {
                        SecondaryButton(title: "绑定本机") {
                            Task {
                                do {
                                    _ = try await env.repository.bindDevice(DeviceBindRequest(deviceId: deviceId, deviceName: "iOS 设备", deviceType: "IOS"))
                                    toast = "已绑定"; reload += 1
                                } catch { toast = (error as? ApiError)?.errorDescription ?? "绑定失败" }
                            }
                        }
                        SecondaryButton(title: "解绑") {
                            Task {
                                do { _ = try await env.repository.unbindDevice(deviceId); toast = "已解绑"; reload += 1 }
                                catch { toast = (error as? ApiError)?.errorDescription ?? "解绑失败" }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(16)
        }
        .pageBackground()
        .navigationTitle("设备管理")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
    }
}
