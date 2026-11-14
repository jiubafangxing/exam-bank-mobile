import SwiftUI

struct ProfileView: View {
    @ObservedObject var session: Session
    @EnvironmentObject var env: AppEnvironment
    @State private var showLogout = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionCard {
                    HStack(spacing: 16) {
                        Text(String(session.user?.displayName.prefix(1) ?? "?"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Tokens.primary)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.user?.displayName ?? "同学")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Tokens.textPrimary)
                            Text(session.user?.username ?? "")
                                .font(.system(size: 13))
                                .foregroundColor(Tokens.textSecondary)
                        }
                        Spacer()
                    }
                }

                SectionCard {
                    ProfileLink(title: "我的成绩", route: .scores)
                    DividerLine()
                    ProfileLink(title: "成绩申诉", route: .appeals)
                    DividerLine()
                    ProfileLink(title: "考试日历", route: .calendar)
                    DividerLine()
                    ProfileLink(title: "消息通知", route: .notifications)
                    DividerLine()
                    ProfileLink(title: "考试组进度", route: .examGroups)
                    DividerLine()
                    ProfileLink(title: "排行榜", route: .ranking)
                }

                SectionCard {
                    ProfileLink(title: "在线练习", route: .practiceList)
                    DividerLine()
                    ProfileLink(title: "我的错题集", route: .wrong)
                    DividerLine()
                    ProfileLink(title: "练习统计", route: .practiceStats)
                    DividerLine()
                    ProfileLink(title: "会员中心", route: .member)
                    DividerLine()
                    ProfileLink(title: "个人分析", route: .analysis)
                    DividerLine()
                    ProfileLink(title: "班级", route: .classes)
                    DividerLine()
                    ProfileLink(title: "人脸核验", route: .face)
                    DividerLine()
                    ProfileLink(title: "设备管理", route: .device)
                    DividerLine()
                    ProfileLink(title: "修改密码", route: .resetPassword)
                }

                Button { showLogout = true } label: {
                    Text("退出登录").font(.system(size: 16)).foregroundColor(Tokens.danger)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
            .padding(16)
        }
        .pageBackground()
        .navigationTitle("个人中心")
        .navigationBarTitleDisplayMode(.inline)
        .alert("退出登录", isPresented: $showLogout) {
            Button("退出", role: .destructive) { session.clear() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确认退出当前账号？")
        }
    }
}

private struct ProfileLink: View {
    let title: String
    let route: Route
    var body: some View {
        NavigationLink(value: route) {
            HStack {
                Text(title).font(.system(size: 15)).foregroundColor(Tokens.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Tokens.textTertiary)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
