package com.example.exammobile.ui.navigation

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.navArgument
import com.example.exammobile.di.AppContainer
import com.example.exammobile.ui.screens.*
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.viewmodel.AuthViewModel

object Routes {
    const val LOGIN = "login"
    const val SMS_LOGIN = "sms_login"
    const val REGISTER = "register"
    const val RESET_PASSWORD = "reset_password"
    const val TENANT = "tenant"

    const val HOME = "home"
    const val EXAMS = "exams"
    const val PRACTICE = "practice"
    const val PROFILE = "profile"

    const val EXAM_TAKING = "exam/{examId}"
    const val RESULT = "result/{attemptId}"
    const val REVIEW = "review/{attemptId}"
    const val SCORES = "scores"
    const val ANALYSIS = "analysis"
    const val RANKING = "ranking"
    const val CLASSES = "classes"
    const val EXAM_GROUPS = "exam_groups"
    const val MEMBER = "member"
    const val ARTICLES = "articles"
    const val ARTICLE_DETAIL = "article/{articleId}"
    const val TEACHERS = "teachers"
    const val NOTIFICATIONS = "notifications"
    const val CALENDAR = "calendar"
    const val APPEALS = "appeals"
    const val FACE = "face"
    const val DEVICE = "device"
    const val WRONG = "wrong"
    const val PRACTICE_STATS = "practice_stats"
    const val PRACTICE_TAKING = "practice_taking/{setId}"

    fun examTaking(examId: String) = "exam/$examId"
    fun result(attemptId: String) = "result/$attemptId"
    fun review(attemptId: String) = "review/$attemptId"
    fun articleDetail(id: String) = "article/$id"
    fun practiceTaking(setId: String) = "practice_taking/$setId"
}

class AppNav(private val controller: NavHostController) {
    fun login() = controller.navigate(Routes.LOGIN) { popUpTo(0) { inclusive = true }; launchSingleTop = true }
    fun smsLogin() = controller.navigate(Routes.SMS_LOGIN)
    fun register() = controller.navigate(Routes.REGISTER)
    fun resetPassword() = controller.navigate(Routes.RESET_PASSWORD)
    fun tenant() = controller.navigate(Routes.TENANT)
    fun home() = controller.navigate(Routes.HOME) { popUpTo(0) { inclusive = true }; launchSingleTop = true }
    fun back() = controller.popBackStack()

    fun tab(route: String) = controller.navigate(route) {
        popUpTo(Routes.HOME) { saveState = true }
        launchSingleTop = true
        restoreState = true
    }

    fun examTaking(examId: String) = controller.navigate(Routes.examTaking(examId))
    fun result(attemptId: String) = controller.navigate(Routes.result(attemptId)) {
        popUpTo(Routes.HOME)
    }
    fun review(attemptId: String) = controller.navigate(Routes.review(attemptId))
    fun scores() = controller.navigate(Routes.SCORES)
    fun analysis() = controller.navigate(Routes.ANALYSIS)
    fun ranking() = controller.navigate(Routes.RANKING)
    fun classes() = controller.navigate(Routes.CLASSES)
    fun examGroups() = controller.navigate(Routes.EXAM_GROUPS)
    fun member() = controller.navigate(Routes.MEMBER)
    fun articles() = controller.navigate(Routes.ARTICLES)
    fun articleDetail(id: String) = controller.navigate(Routes.articleDetail(id))
    fun teachers() = controller.navigate(Routes.TEACHERS)
    fun notifications() = controller.navigate(Routes.NOTIFICATIONS)
    fun calendar() = controller.navigate(Routes.CALENDAR)
    fun appeals() = controller.navigate(Routes.APPEALS)
    fun face() = controller.navigate(Routes.FACE)
    fun device() = controller.navigate(Routes.DEVICE)
    fun wrong() = controller.navigate(Routes.WRONG)
    fun practiceStats() = controller.navigate(Routes.PRACTICE_STATS)
    fun practiceTaking(setId: String) = controller.navigate(Routes.practiceTaking(setId))
}

private data class TabItem(val route: String, val title: String, val icon: ImageVector)

private val tabs = listOf(
    TabItem(Routes.HOME, "首页", Icons.Filled.Home),
    TabItem(Routes.EXAMS, "考试", Icons.Filled.List),
    TabItem(Routes.PRACTICE, "练习", Icons.Filled.Edit),
    TabItem(Routes.PROFILE, "我的", Icons.Filled.Person)
)

@Composable
fun AppNavHost(
    container: AppContainer,
    authVm: AuthViewModel,
    startLoggedIn: Boolean,
    navController: NavHostController
) {
    val nav = AppNav(navController)
    val backStack by navController.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route
    val showBottomBar = currentRoute in tabs.map { it.route }

    Scaffold(
        containerColor = Tokens.Background,
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            if (showBottomBar) {
                NavigationBar(containerColor = Tokens.Surface) {
                    tabs.forEach { tab ->
                        NavigationBarItem(
                            selected = currentRoute == tab.route,
                            onClick = { if (currentRoute != tab.route) nav.tab(tab.route) },
                            icon = { Icon(tab.icon, contentDescription = tab.title) },
                            label = { Text(tab.title) },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = Tokens.Primary,
                                selectedTextColor = Tokens.Primary,
                                unselectedIconColor = Tokens.TextSecondary,
                                unselectedTextColor = Tokens.TextSecondary,
                                indicatorColor = Tokens.PrimarySoft
                            )
                        )
                    }
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = if (startLoggedIn) Routes.HOME else Routes.LOGIN,
            modifier = Modifier.padding(padding)
        ) {
            // ---- 认证 ----
            composable(Routes.LOGIN) { LoginScreen(authVm, nav) }
            composable(Routes.SMS_LOGIN) { SmsLoginScreen(authVm, nav) }
            composable(Routes.REGISTER) { RegisterScreen(authVm, nav) }
            composable(Routes.RESET_PASSWORD) { ResetPasswordScreen(authVm, nav) }
            composable(Routes.TENANT) { TenantScreen(authVm, nav) }

            // ---- 主 Tab ----
            composable(Routes.HOME) { HomeScreen(container.repository, nav) }
            composable(Routes.EXAMS) { ExamListScreen(container.repository, nav) }
            composable(Routes.PRACTICE) { PracticeListScreen(container.repository, nav) }
            composable(Routes.PROFILE) { ProfileScreen(authVm, nav) }

            // ---- 作答与成绩 ----
            composable(Routes.EXAM_TAKING, arguments = listOf(navArgument("examId") { type = NavType.StringType })) {
                ExamTakingScreen(container.repository, it.arguments?.getString("examId").orEmpty(), nav)
            }
            composable(Routes.RESULT, arguments = listOf(navArgument("attemptId") { type = NavType.StringType })) {
                ResultScreen(container.repository, it.arguments?.getString("attemptId").orEmpty(), nav)
            }
            composable(Routes.REVIEW, arguments = listOf(navArgument("attemptId") { type = NavType.StringType })) {
                ReviewScreen(container.repository, it.arguments?.getString("attemptId").orEmpty(), nav)
            }

            // ---- 二级页面 ----
            composable(Routes.SCORES) { ScoreScreen(container.repository, nav) }
            composable(Routes.ANALYSIS) { AnalysisScreen(container.repository, nav) }
            composable(Routes.RANKING) { RankingScreen(container.repository, nav) }
            composable(Routes.CLASSES) { ClassScreen(container.repository, nav) }
            composable(Routes.EXAM_GROUPS) { ExamGroupScreen(container.repository, nav) }
            composable(Routes.MEMBER) { MemberScreen(container.repository, nav) }
            composable(Routes.ARTICLES) { ArticleListScreen(container.repository, nav) }
            composable(Routes.ARTICLE_DETAIL, arguments = listOf(navArgument("articleId") { type = NavType.StringType })) {
                ArticleDetailScreen(container.repository, it.arguments?.getString("articleId").orEmpty(), nav)
            }
            composable(Routes.TEACHERS) { TeacherScreen(container.repository, nav) }
            composable(Routes.NOTIFICATIONS) { NotificationScreen(container.repository, nav) }
            composable(Routes.CALENDAR) { CalendarScreen(container.repository, nav) }
            composable(Routes.APPEALS) { AppealScreen(container.repository, nav) }
            composable(Routes.FACE) { FaceScreen(container.repository, nav) }
            composable(Routes.DEVICE) { DeviceScreen(container.repository, nav) }
            composable(Routes.WRONG) { WrongScreen(container.repository, nav) }
            composable(Routes.PRACTICE_STATS) { PracticeStatsScreen(container.repository, nav) }
            composable(Routes.PRACTICE_TAKING, arguments = listOf(navArgument("setId") { type = NavType.StringType })) {
                PracticeTakingScreen(container.repository, it.arguments?.getString("setId").orEmpty(), nav)
            }
        }
    }
}
