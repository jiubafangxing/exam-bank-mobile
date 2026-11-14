import Foundation
import SwiftUI

struct ProfileView: View {
    @ObservedObject var session: Session
    @EnvironmentObject var env: AppEnvironment
    @State private var showLogout = false

    private var displayName: String {
        session.user?.displayName ?? "同学"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                GradientHero {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.20))
                            Text(String(displayName.prefix(1)))
                                .font(.system(size: 25, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 64, height: 64)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text(session.user?.username ?? "在线考试学员")
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        Spacer(minLength: 0)
                        Text("学员")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }

                SectionHeader(title: "学习与成绩")
                SectionCard(padding: 14) {
                    rowLink("我的成绩", icon: "star.fill", tint: Tokens.amber, bg: Tokens.amberSoft, route: .scores)
                    DividerLine()
                    rowLink("成绩申诉", icon: "paperplane.fill", tint: Tokens.coral, bg: Tokens.coralSoft, route: .appeals)
                    DividerLine()
                    rowLink("考试日历", icon: "calendar", tint: Tokens.accent, bg: Tokens.accentSoft, route: .calendar)
                    DividerLine()
                    rowLink("消息通知", icon: "bell.fill", tint: Tokens.sky, bg: Tokens.skySoft, route: .notifications)
                    DividerLine()
                    rowLink("考试组进度", icon: "checkmark.seal.fill", tint: Tokens.violet, bg: Tokens.violetSoft, route: .examGroups)
                    DividerLine()
                    rowLink("排行榜", icon: "chart.bar.fill", tint: Tokens.primary, bg: Tokens.primarySoft, route: .ranking)
                }

                SectionHeader(title: "练习与成长")
                SectionCard(padding: 14) {
                    rowLink("在线练习", icon: "square.and.pencil", tint: Tokens.accent, bg: Tokens.accentSoft, route: .practiceList)
                    DividerLine()
                    rowLink("我的错题集", icon: "exclamationmark.triangle.fill", tint: Tokens.danger, bg: Tokens.dangerSoft, route: .wrong)
                    DividerLine()
                    rowLink("练习统计", icon: "chart.bar.doc.horizontal", tint: Tokens.sky, bg: Tokens.skySoft, route: .practiceStats)
                    DividerLine()
                    rowLink("会员中心", icon: "crown.fill", tint: Tokens.amber, bg: Tokens.amberSoft, route: .member)
                    DividerLine()
                    rowLink("个人分析", icon: "chart.line.uptrend.xyaxis", tint: Tokens.violet, bg: Tokens.violetSoft, route: .analysis)
                    DividerLine()
                    rowLink("班级", icon: "person.2.fill", tint: Tokens.coral, bg: Tokens.coralSoft, route: .classes)
                }

                SectionHeader(title: "账号与安全")
                SectionCard(padding: 14) {
                    rowLink("人脸核验", icon: "faceid", tint: Tokens.sky, bg: Tokens.skySoft, route: .face)
                    DividerLine()
                    rowLink("设备管理", icon: "desktopcomputer", tint: Tokens.slate, bg: Tokens.slateSoft, route: .device)
                    DividerLine()
                    rowLink("修改密码", icon: "lock.fill", tint: Tokens.primary, bg: Tokens.primarySoft, route: .resetPassword)
                }

                Button { showLogout = true } label: {
                    Text("退出登录")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Tokens.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Tokens.dangerSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(.horizontal, Tokens.pagePadding)
            .padding(.top, 10)
            .padding(.bottom, 20)
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

    private func rowLink(
        _ title: String,
        icon: String,
        tint: Color,
        bg: Color,
        route: Route
    ) -> some View {
        NavigationLink(value: route) {
            ListRow(
                title: title,
                icon: icon,
                iconTint: tint,
                iconBg: bg,
                action: {}
            )
            .allowsHitTesting(false)
        }
        .buttonStyle(.plain)
    }
}
