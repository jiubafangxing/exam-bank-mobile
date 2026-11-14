import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var env: AppEnvironment

    private let quickLinks: [(String, Route)] = [
        ("我的考试", .examList),
        ("在线练习", .practiceList),
        ("错题集", .wrong),
        ("班级", .classes),
        ("考试组", .examGroups),
        ("排行榜", .ranking),
        ("文章", .articles),
        ("教师风采", .teachers)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Formatters.greeting())，同学")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Tokens.textPrimary)
                    Text("考试、练习、班级与学习内容都在这里。")
                        .font(.system(size: 13))
                        .foregroundColor(Tokens.textSecondary)
                }
                .padding(.top, 8)

                SectionCard {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 14) {
                        ForEach(quickLinks.indices, id: \.self) { i in
                            QuickLinkCell(title: quickLinks[i].0, route: quickLinks[i].1)
                        }
                    }
                }

                if !AppConfig.registrationUrl.isEmpty {
                    SectionCard {
                        Button {
                            let base = AppConfig.registrationUrl.hasSuffix("/") ? AppConfig.registrationUrl : AppConfig.registrationUrl + "/"
                            if let url = URL(string: base + "campaigns") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("考试报名").font(.system(size: 16, weight: .semibold)).foregroundColor(Tokens.textPrimary)
                                    Text("查看招录公告、岗位与报名进度").font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(Tokens.textTertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                RemoteContent(
                    loader: { try await env.repository.home() },
                    emptyCheck: { $0.isEmpty }
                ) { components in
                    ForEach(components) { component in
                        HomeComponentView(component: component)
                    }
                }
            }
            .padding(.horizontal, Tokens.pagePadding)
            .padding(.bottom, 16)
        }
        .pageBackground()
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct QuickLinkCell: View {
    let title: String
    let route: Route

    var body: some View {
        NavigationLink(value: route) {
            VStack(spacing: 6) {
                Text(String(title.prefix(1)))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Tokens.primary)
                    .frame(width: 42, height: 42)
                    .background(Tokens.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(title).font(.system(size: 12)).foregroundColor(Tokens.textPrimary).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HomeComponentView: View {
    let component: HomeComponent

    var body: some View {
        let type = (component.componentType ?? "").uppercased()
        let items = component.items ?? []
        if !items.isEmpty {
            switch type {
            case "BANNER":
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 0) {
                                AsyncImage(url: URL(string: item.imageUrl ?? item.coverUrl ?? "")) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Tokens.surfaceAlt
                                }
                                .frame(width: 280, height: 130)
                                .clipped()
                                Text(item.title ?? item.name ?? "")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Tokens.textPrimary)
                                    .padding(10)
                            }
                            .frame(width: 280)
                            .background(Tokens.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            case "NAV":
                SectionCard {
                    HStack {
                        ForEach(items.prefix(4)) { item in
                            VStack(spacing: 6) {
                                Text(String((item.name ?? item.title ?? "·").prefix(1)))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Tokens.primary)
                                    .frame(width: 40, height: 40)
                                    .background(Tokens.primarySoft)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text(item.name ?? item.title ?? "").font(.system(size: 12)).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            default:
                SectionTitle(component.title ?? "")
                SectionCard {
                    ForEach(Array(items.indices), id: \.self) { index in
                        let item = items[index]
                        HStack(spacing: 12) {
                            if let cover = item.coverUrl ?? item.avatarUrl, let url = URL(string: cover) {
                                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Tokens.surfaceAlt }
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title ?? item.name ?? "")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Tokens.textPrimary)
                                    .lineLimit(1)
                                if let sub = item.summary ?? item.intro ?? item.description ?? item.category, !sub.isEmpty {
                                    Text(sub).font(.system(size: 12)).foregroundColor(Tokens.textSecondary).lineLimit(1)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 10)
                        if index < items.count - 1 { DividerLine() }
                    }
                }
            }
        }
    }
}
