import Foundation
import SwiftUI

private struct QuickLink: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let route: Route
}

struct HomeView: View {
    @EnvironmentObject var env: AppEnvironment
    @Environment(\.openURL) private var openURL

    @State private var goExams = false
    @State private var goArticles = false
    @State private var goTeachers = false
    @State private var goClasses = false
    @State private var goNotifications = false

    private var quickLinks: [QuickLink] {
        [
            QuickLink(label: "我的考试", icon: "list.bullet", route: .examList),
            QuickLink(label: "在线练习", icon: "square.and.pencil", route: .practiceList),
            QuickLink(label: "错题集", icon: "exclamationmark.triangle", route: .wrong),
            QuickLink(label: "班级", icon: "person.2", route: .classes),
            QuickLink(label: "考试组", icon: "checkmark.seal", route: .examGroups),
            QuickLink(label: "排行榜", icon: "star", route: .ranking),
            QuickLink(label: "文章", icon: "doc.text", route: .articles),
            QuickLink(label: "教师风采", icon: "person.crop.circle", route: .teachers)
        ]
    }

    private var displayName: String {
        env.session.user?.displayName ?? "同学"
    }

    private var dateText: String {
        let now = Date()
        let comps = Calendar.current.dateComponents([.month, .day, .weekday], from: now)
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let index = max(0, min(6, (comps.weekday ?? 1) - 1))
        return "\(comps.month ?? 1)月\(comps.day ?? 1)日 · \(weekdays[index])"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                hero

                SectionHeader(title: "快捷服务")
                SectionCard(padding: 12) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                        spacing: 14
                    ) {
                        ForEach(Array(quickLinks.enumerated()), id: \.offset) { index, link in
                            let palette = Tokens.palette(index)
                            NavigationLink(value: link.route) {
                                VStack(spacing: 7) {
                                    IconTile(
                                        icon: link.icon,
                                        tint: palette.color,
                                        bg: palette.bg,
                                        size: 46,
                                        iconSize: 22
                                    )
                                    Text(link.label)
                                        .font(.system(size: 12))
                                        .foregroundColor(Tokens.textPrimary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !AppConfig.registrationUrl.isEmpty {
                    registrationCard
                }

                RemoteContent(
                    loader: { try await env.repository.home() },
                    emptyCheck: { $0.isEmpty },
                    emptyText: "暂无首页内容"
                ) { components in
                    ForEach(components) { component in
                        HomeComponentView(
                            component: component,
                            openExams: { goExams = true },
                            openArticles: { goArticles = true },
                            openTeachers: { goTeachers = true },
                            openClasses: { goClasses = true },
                            openNotifications: { goNotifications = true }
                        )
                    }
                }
            }
            .padding(.horizontal, Tokens.pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .pageBackground()
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goExams) { ExamListView() }
        .navigationDestination(isPresented: $goArticles) { ArticleListView() }
        .navigationDestination(isPresented: $goTeachers) { TeacherView() }
        .navigationDestination(isPresented: $goClasses) { ClassView() }
        .navigationDestination(isPresented: $goNotifications) { NotificationView() }
    }

    private var hero: some View {
        GradientHero {
            HStack {
                Text(dateText)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.9))
                Spacer()
                Text("在线考试平台")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0xFFE3A8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
            }
            Text("\(Formatters.greeting())，\(displayName)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 14)
            Text("今天也要稳稳拿分。考试、练习、错题与班级内容都在这里。")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.88))
                .lineSpacing(4)
                .padding(.top, 6)
            HStack(spacing: 10) {
                NavigationLink(value: Route.examList) {
                    Text("进入我的考试")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Tokens.primary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.practiceList) {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("继续练习")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
        }
    }

    private var registrationCard: some View {
        SectionCard {
            Button {
                var base = AppConfig.registrationUrl
                while base.hasSuffix("/") { base.removeLast() }
                if let url = URL(string: base + "/campaigns") {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 12) {
                    IconTile(icon: "paperplane.fill", tint: Tokens.amber, bg: Tokens.amberSoft)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("考试报名")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Tokens.textPrimary)
                        Text("查看招录公告、岗位与报名进度")
                            .font(.system(size: 12))
                            .foregroundColor(Tokens.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Tokens.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 服务端组件

private struct HomeComponentView: View {
    let component: HomeComponent
    let openExams: () -> Void
    let openArticles: () -> Void
    let openTeachers: () -> Void
    let openClasses: () -> Void
    let openNotifications: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        let type = (component.componentType ?? "").uppercased()
        let items = component.items ?? []
        if !items.isEmpty {
            switch type {
            case "BANNER":
                bannerSection(items)
            case "NAV":
                navSection(items)
            case "NOTICE":
                noticeSection(items)
            case "HOT_EXAM":
                hotExamSection(items)
            case "ARTICLE", "TEACHER", "CLASS_RECOMMEND":
                contentSection(items, type: type)
            default:
                genericSection(items)
            }
        }
    }

    // MARK: Banner

    private func bannerSection(_ items: [HomeItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    BannerCard(item: item)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: Nav

    private func navSection(_ items: [HomeItem]) -> some View {
        let rows = chunked(items, size: 4)
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: component.title ?? "推荐入口")
            SectionCard(padding: 12) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { colIndex, item in
                            let palette = Tokens.palette(rowIndex * 4 + colIndex)
                            navCell(item, palette: palette)
                        }
                        if row.count < 4 {
                            ForEach(0..<(4 - row.count), id: \.self) { _ in
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    @ViewBuilder
    private func navCell(_ item: HomeItem, palette: Tokens.Palette) -> some View {
        if let link = item.linkUrl ?? item.url,
           link.lowercased().hasPrefix("http"),
           let url = URL(string: link) {
            Button { openURL(url) } label: {
                navCellLabel(item, palette: palette)
            }
            .buttonStyle(.plain)
        } else if let route = homeRoute(for: item) {
            NavigationLink(value: route) {
                navCellLabel(item, palette: palette)
            }
            .buttonStyle(.plain)
        } else {
            navCellLabel(item, palette: palette)
        }
    }

    private func navCellLabel(_ item: HomeItem, palette: Tokens.Palette) -> some View {
        let label = item.name ?? item.title ?? "入口"
        return VStack(spacing: 6) {
            IconTile(
                icon: iconFor(label),
                tint: palette.color,
                bg: palette.bg,
                size: 44,
                iconSize: 21
            )
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Tokens.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Notice

    private func noticeSection(_ items: [HomeItem]) -> some View {
        let item = items[0]
        return SectionCard {
            if let link = item.linkUrl ?? item.url,
               link.lowercased().hasPrefix("http"),
               let url = URL(string: link) {
                Button { openURL(url) } label: {
                    noticeContent(item)
                }
                .buttonStyle(.plain)
            } else {
                Button { openNotifications() } label: {
                    noticeContent(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func noticeContent(_ item: HomeItem) -> some View {
        HStack(spacing: 12) {
            IconTile(icon: "bell.fill", tint: Tokens.amber, bg: Tokens.amberSoft, size: 38, iconSize: 18)
            Text(item.title ?? item.name ?? "公告通知")
                .font(.system(size: 13))
                .foregroundColor(Tokens.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text("查看")
                .font(.system(size: 12))
                .foregroundColor(Tokens.amber)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Tokens.amber)
        }
        .contentShape(Rectangle())
    }

    // MARK: Hot exam

    private func hotExamSection(_ items: [HomeItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title: component.title ?? "热门考试",
                actionLabel: "全部考试",
                action: openExams
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        Button { openExams() } label: {
                            HotExamCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 2)
            }
        }
    }

    // MARK: Content

    private func contentSection(_ items: [HomeItem], type: String) -> some View {
        let title = component.title ?? defaultTitle(type)
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: title, actionLabel: "查看更多", action: {
                switch type {
                case "TEACHER": openTeachers()
                case "CLASS_RECOMMEND": openClasses()
                default: openArticles()
                }
            })
            SectionCard(padding: 14) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    contentRow(item, index: index, type: type)
                    if index < items.count - 1 { DividerLine() }
                }
            }
        }
    }

    @ViewBuilder
    private func contentRow(_ item: HomeItem, index: Int, type: String) -> some View {
        if let link = item.linkUrl ?? item.url,
           link.lowercased().hasPrefix("http"),
           let url = URL(string: link) {
            Button { openURL(url) } label: {
                contentRowLabel(item, index: index, type: type)
            }
            .buttonStyle(.plain)
        } else if let route = homeRoute(for: item, type: type) {
            NavigationLink(value: route) {
                contentRowLabel(item, index: index, type: type)
            }
            .buttonStyle(.plain)
        } else {
            contentRowLabel(item, index: index, type: type)
        }
    }

    private func contentRowLabel(_ item: HomeItem, index: Int, type: String) -> some View {
        HStack(spacing: 12) {
            if let cover = item.coverUrl ?? item.avatarUrl, let url = URL(string: cover) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Tokens.surfaceAlt
                }
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                let palette = Tokens.palette(index)
                IconTile(
                    icon: iconFor(item.title ?? item.name ?? component.title ?? ""),
                    tint: palette.color,
                    bg: palette.bg,
                    size: 52,
                    iconSize: 23
                )
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title ?? item.name ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Tokens.textPrimary)
                    .lineLimit(1)
                let sub = item.summary ?? item.intro ?? item.description ?? item.category
                if let sub = sub, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(Tokens.textSecondary)
                        .lineLimit(2)
                }
                if let meta = item.publishAt ?? item.createdAt, !meta.isEmpty {
                    Text(formatHomeTime(meta))
                        .font(.system(size: 11))
                        .foregroundColor(Tokens.textTertiary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Tokens.textTertiary)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    private func defaultTitle(_ type: String) -> String {
        switch type {
        case "TEACHER": return "教师风采"
        case "CLASS_RECOMMEND": return "推荐班级"
        default: return "精选内容"
        }
    }

    // MARK: Generic

    private func genericSection(_ items: [HomeItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: component.title ?? "更多内容")
            SectionCard {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    contentRow(item, index: index, type: "")
                    if index < items.count - 1 { DividerLine() }
                }
            }
        }
    }
}

// MARK: - 子视图

private struct BannerCard: View {
    let item: HomeItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: item.imageUrl ?? item.coverUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Tokens.surfaceAlt
            }
            .frame(width: 300, height: 160)
            .clipped()

            LinearGradient(
                colors: [
                    Color(hex: 0x0B1B2E).opacity(0.80),
                    Color(hex: 0x0B1B2E).opacity(0.33),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 300, height: 160)

            VStack(alignment: .leading, spacing: 7) {
                Text(item.tag ?? "推荐")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Capsule())
                Text(item.title ?? item.name ?? "")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let sub = item.summary ?? item.intro ?? item.description, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.9))
                        .lineLimit(1)
                }
            }
            .padding(16)
        }
        .frame(width: 300, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .cardShadow()
    }
}

private struct HotExamCard: View {
    let item: HomeItem

    var body: some View {
        SectionCard(padding: 14) {
            Text("待参加")
                .font(.system(size: 10))
                .foregroundColor(Tokens.primary)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Tokens.primarySoft)
                .clipShape(Capsule())
            Text(item.title ?? item.name ?? "")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Tokens.textPrimary)
                .lineLimit(2)
                .frame(minHeight: 42, alignment: .topLeading)
                .padding(.top, 9)
            Text(item.summary ?? "点击查看考试详情")
                .font(.system(size: 12))
                .foregroundColor(Tokens.textSecondary)
                .lineLimit(1)
                .padding(.top, 6)
        }
        .frame(width: 220)
    }
}

// MARK: - 工具

private func chunked<T>(_ array: [T], size: Int) -> [[T]] {
    guard size > 0 else { return [array] }
    return stride(from: 0, to: array.count, by: size).map {
        Array(array[$0..<min($0 + size, array.count)])
    }
}

private func iconFor(_ label: String) -> String {
    if label.contains("考试组") { return "checkmark.seal" }
    if label.contains("错题") { return "exclamationmark.triangle" }
    if label.contains("练习") { return "square.and.pencil" }
    if label.contains("班级") { return "person.2" }
    if label.contains("排行") { return "star" }
    if label.contains("文章") || label.contains("内容") { return "doc.text" }
    if label.contains("教师") { return "person.crop.circle" }
    if label.contains("通知") { return "bell.fill" }
    if label.contains("日历") { return "calendar" }
    if label.contains("成绩") { return "star" }
    if label.contains("考试") { return "list.bullet" }
    if label.contains("报名") { return "paperplane.fill" }
    return "arrow.right"
}

private func formatHomeTime(_ value: String) -> String {
    value.replacingOccurrences(of: "T", with: " ").prefix(16).description
}

private func homeRoute(for item: HomeItem, type: String = "") -> Route? {
    let normalizedType = type.uppercased()
    if normalizedType == "TEACHER" { return .teachers }
    if normalizedType == "CLASS_RECOMMEND" { return .classes }
    if normalizedType == "ARTICLE" {
        if let id = item.id, !id.isEmpty { return .article(id) }
        return .articles
    }

    let path = (item.path ?? "").lowercased()
    let label = (item.title ?? item.name ?? item.category ?? "").lowercased()

    if label.contains("考试组") || path.contains("exam-group") || path.contains("exam_group") {
        return .examGroups
    }
    if label.contains("错题") || path.contains("wrong") {
        return .wrong
    }
    if label.contains("排行") || path.contains("ranking") {
        return .ranking
    }
    if label.contains("班级") || path.contains("class") {
        return .classes
    }
    if label.contains("教师") || path.contains("teacher") {
        return .teachers
    }
    if label.contains("通知") || path.contains("notification") {
        return .notifications
    }
    if label.contains("练习") || path.contains("practice") {
        return .practiceList
    }
    if label.contains("文章") || path.contains("article") {
        if let id = item.id, !id.isEmpty { return .article(id) }
        return .articles
    }
    if label.contains("考试") || path.contains("exam") {
        return .examList
    }
    if let id = item.id, !id.isEmpty {
        return .article(id)
    }
    return nil
}
