package com.example.exammobile.ui.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
    const val MEMBER_ORDER = "member/{bizType}/{bizId}"
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
    const val PRACTICE_TAKING = "practice_record/{recordId}"

    fun examTaking(examId: String) = "exam/$examId"
    fun result(attemptId: String) = "result/$attemptId"
    fun review(attemptId: String) = "review/$attemptId"
    fun articleDetail(id: String) = "article/$id"
    fun practiceTaking(recordId: String) = "practice_record/$recordId"
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
    fun memberOrder(bizType: String, bizId: String) = controller.navigate("member/$bizType/$bizId")
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
    fun practiceTaking(recordId: String) = controller.navigate(Routes.practiceTaking(recordId))
}

private data class TabItem(val route: String, val title: String, val icon: ImageVector)

private val tabs = listOf(
    TabItem(Routes.HOME, "首页", Icons.Filled.Home),
    TabItem(Routes.EXAMS, "考试", Icons.Filled.List),
    TabItem(Routes.PRACTICE, "练习", Icons.Filled.Edit),
    TabItem(Routes.PROFILE, "我的", Icons.Filled.Person)
)

@Composable
private fun FloatingTabBar(currentRoute: String?, onSelect: (String) -> Unit) {
    Box(
        Modifier
            .fillMaxWidth()
            .background(Tokens.Background)
            .padding(horizontal = 14.dp, vertical = 8.dp)
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .shadow(18.dp, RoundedCornerShape(24.dp), spotColor = Color(0x260F172A))
                .clip(RoundedCornerShape(24.dp))
                .background(Tokens.Surface.copy(alpha = 0.98f))
                .border(1.dp, Tokens.Border, RoundedCornerShape(24.dp))
                .padding(horizontal = 6.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            tabs.forEach { tab ->
                val selected = currentRoute == tab.route
                Column(
                    Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(18.dp))
                        .background(if (selected) Tokens.PrimarySoft else Color.Transparent)
                        .clickable { onSelect(tab.route) }
                        .padding(vertical = 7.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        tab.icon,
                        contentDescription = tab.title,
                        tint = if (selected) Tokens.Primary else Tokens.TextSecondary,
                        modifier = Modifier.size(21.dp)
                    )
                    Spacer(Modifier.height(2.dp))
                    Text(
                        tab.title,
                        fontSize = 11.sp,
                        fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                        color = if (selected) Tokens.Primary else Tokens.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
fun AppNavHost(
    container: AppContainer,
    authVm: AuthViewModel,
    startLoggedIn: Boolean,
    navController: NavHostController
) {
    val nav = AppNav(navController)
    val user by authVm.user.collectAsState()
    val backStack by navController.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route
    val showBottomBar = currentRoute in tabs.map { it.route }

    Scaffold(
        containerColor = Tokens.Background,
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            if (showBottomBar) {
                FloatingTabBar(
                    currentRoute = currentRoute,
                    onSelect = { route -> if (currentRoute != route) nav.tab(route) }
                )
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
            composable(Routes.HOME) { HomeScreen(container.repository, nav, user) }
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
            composable(
                Routes.MEMBER_ORDER,
                arguments = listOf(
                    navArgument("bizType") { type = NavType.StringType },
                    navArgument("bizId") { type = NavType.StringType }
                )
            ) {
                MemberScreen(
                    container.repository,
                    nav,
                    pendingBizType = it.arguments?.getString("bizType"),
                    pendingBizId = it.arguments?.getString("bizId")
                )
            }
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
            composable(Routes.PRACTICE_TAKING, arguments = listOf(navArgument("recordId") { type = NavType.StringType })) {
                PracticeTakingScreen(container.repository, it.arguments?.getString("recordId").orEmpty(), nav)
            }
        }
    }
}
