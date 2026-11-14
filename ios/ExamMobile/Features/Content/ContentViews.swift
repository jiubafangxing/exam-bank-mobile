import SwiftUI

struct ArticleListView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        RemoteContent(loader: { try await env.repository.articles() }, emptyCheck: { $0.isEmpty }) { list in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(list) { article in
                        NavigationLink(value: Route.article(article.id ?? "")) {
                            SectionCard {
                                HStack(spacing: 12) {
                                    if let cover = article.coverUrl, let url = URL(string: cover) {
                                        AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Tokens.surfaceAlt }
                                            .frame(width: 64, height: 64)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(article.title ?? "").font(.system(size: 15, weight: .medium)).lineLimit(2)
                                        if let sub = article.summary ?? article.category, !sub.isEmpty {
                                            Text(sub).font(.system(size: 12)).foregroundColor(Tokens.textSecondary).lineLimit(2)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .pageBackground()
        .navigationTitle("内容")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ArticleDetailView: View {
    @EnvironmentObject var env: AppEnvironment
    let articleId: String

    var body: some View {
        RemoteContent(loader: { try await env.repository.article(articleId) }) { article in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(article.title ?? "").font(.system(size: 20, weight: .bold)).foregroundColor(Tokens.textPrimary)
                    if let created = article.createdAt, !created.isEmpty {
                        Text(created).font(.system(size: 12)).foregroundColor(Tokens.textSecondary)
                    }
                    SectionCard {
                        RichText(content: article.content ?? article.summary ?? "暂无内容", fontSize: 15)
                    }
                }
                .padding(16)
            }
        }
        .pageBackground()
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TeacherView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        RemoteContent(loader: { try await env.repository.showcaseTeachers() }, emptyCheck: { $0.isEmpty }) { list in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(list) { teacher in
                        SectionCard {
                            HStack(spacing: 14) {
                                if let avatar = teacher.avatarUrl, let url = URL(string: avatar) {
                                    AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Tokens.primarySoft }
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                } else {
                                    Text(String((teacher.name ?? "?").prefix(1)))
                                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                        .frame(width: 56, height: 56).background(Tokens.primary).clipShape(Circle())
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(teacher.name ?? "").font(.system(size: 16, weight: .semibold))
                                    if let title = teacher.title, !title.isEmpty {
                                        Text(title).font(.system(size: 12)).foregroundColor(Tokens.primary)
                                    }
                                    if let intro = teacher.intro, !intro.isEmpty {
                                        Text(intro).font(.system(size: 12)).foregroundColor(Tokens.textSecondary).lineLimit(3)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .pageBackground()
        .navigationTitle("教师风采")
        .navigationBarTitleDisplayMode(.inline)
    }
}
