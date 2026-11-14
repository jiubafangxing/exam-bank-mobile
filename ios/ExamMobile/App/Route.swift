import SwiftUI

enum Route: Hashable {
    case examList
    case practiceList
    case examTaking(String)
    case result(String)
    case review(String)
    case scores
    case analysis
    case ranking
    case classes
    case examGroups
    case member
    case articles
    case article(String)
    case teachers
    case notifications
    case calendar
    case appeals
    case face
    case device
    case wrong
    case practiceStats
    case practiceTaking(String)
    case resetPassword
}

struct RouteView: View {
    @EnvironmentObject var env: AppEnvironment
    let route: Route

    var body: some View {
        switch route {
        case .examList: ExamListView()
        case .practiceList: PracticeListView()
        case .examTaking(let id): ExamTakingView(examId: id, repository: env.repository)
        case .result(let id): ResultView(attemptId: id, repository: env.repository)
        case .review(let id): ReviewView(attemptId: id, repository: env.repository)
        case .scores: ScoreView()
        case .analysis: AnalysisView()
        case .ranking: RankingView()
        case .classes: ClassView()
        case .examGroups: ExamGroupView()
        case .member: MemberView()
        case .articles: ArticleListView()
        case .article(let id): ArticleDetailView(articleId: id)
        case .teachers: TeacherView()
        case .notifications: NotificationView()
        case .calendar: CalendarView()
        case .appeals: AppealView()
        case .face: FaceView()
        case .device: DeviceView()
        case .wrong: WrongView()
        case .practiceStats: PracticeStatsView()
        case .practiceTaking(let id): PracticeTakingView(setId: id)
        case .resetPassword: ResetPasswordView(session: env.session, repository: env.repository)
        }
    }
}

extension View {
    func appRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            RouteView(route: route)
        }
    }
}
