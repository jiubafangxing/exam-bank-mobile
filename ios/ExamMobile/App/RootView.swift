import SwiftUI

struct RootView: View {
    @StateObject private var env = AppEnvironment()

    var body: some View {
        RootGate(session: env.session)
            .environmentObject(env)
    }
}

/// 观察 Session，登录态变化时在登录页与主界面间切换。
private struct RootGate: View {
    @ObservedObject var session: Session

    var body: some View {
        Group {
            if session.loggedIn {
                MainTabView()
            } else {
                AuthFlowView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        TabView {
            NavigationStack { HomeView().appRoutes() }
                .tabItem { Label("首页", systemImage: "house.fill") }
            NavigationStack { ExamListView().appRoutes() }
                .tabItem { Label("考试", systemImage: "list.bullet") }
            NavigationStack { PracticeListView().appRoutes() }
                .tabItem { Label("练习", systemImage: "square.and.pencil") }
            NavigationStack { ProfileView(session: env.session).appRoutes() }
                .tabItem { Label("我的", systemImage: "person.fill") }
        }
        .tint(Tokens.primary)
    }
}
