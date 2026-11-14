package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Create
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.exammobile.core.config.AppConfig
import com.example.exammobile.core.model.HomeComponent
import com.example.exammobile.core.model.HomeItem
import com.example.exammobile.core.model.User
import com.example.exammobile.core.util.Formatters
import com.example.exammobile.data.CandidateRepository
import com.example.exammobile.ui.components.*
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.navigation.Routes
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.util.rememberRemote
import java.util.Calendar

private data class QuickLink(
    val label: String,
    val icon: ImageVector,
    val onClick: (AppNav) -> Unit
)

@Composable
fun HomeScreen(repository: CandidateRepository, nav: AppNav, user: User? = null) {
    val context = LocalContext.current
    val controller = rememberRemote("home") { repository.home() }
    val now = Calendar.getInstance()
    val greeting = Formatters.greeting(now.get(Calendar.HOUR_OF_DAY))
    val displayName = user?.realName?.takeIf { it.isNotBlank() } ?: user?.username?.takeIf { it.isNotBlank() } ?: "同学"
    val dateText = "${now.get(Calendar.MONTH) + 1}月${now.get(Calendar.DAY_OF_MONTH)}日 · ${
        listOf("周日", "周一", "周二", "周三", "周四", "周五", "周六")[now.get(Calendar.DAY_OF_WEEK) - 1]
    }"

    val quickLinks = listOf(
        QuickLink("我的考试", Icons.Filled.List) { it.tab(Routes.EXAMS) },
        QuickLink("在线练习", Icons.Filled.Edit) { it.tab(Routes.PRACTICE) },
        QuickLink("错题集", Icons.Filled.Warning) { it.wrong() },
        QuickLink("班级", Icons.Filled.Person) { it.classes() },
        QuickLink("考试组", Icons.Filled.CheckCircle) { it.examGroups() },
        QuickLink("排行榜", Icons.Filled.Star) { it.ranking() },
        QuickLink("文章", Icons.Filled.Create) { it.articles() },
        QuickLink("教师风采", Icons.Filled.AccountCircle) { it.teachers() }
    )

    PageScaffold(title = "首页", actions = {
        Text(
            "我的考试",
            color = Tokens.Primary,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(end = 16.dp).clickable { nav.tab(Routes.EXAMS) }
        )
    }) { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = PagePadding, vertical = 10.dp)
        ) {
            GradientHero {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text(dateText, fontSize = 12.sp, color = Color.White.copy(alpha = 0.9f))
                    Spacer(Modifier.weight(1f))
                    Box(
                        Modifier
                            .clip(RoundedCornerShape(999.dp))
                            .background(Color.White.copy(alpha = 0.18f))
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("在线考试平台", fontSize = 11.sp, color = Color(0xFFFFE3A8))
                    }
                }
                Spacer(Modifier.height(14.dp))
                Text("$greeting，$displayName", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color.White)
                Spacer(Modifier.height(6.dp))
                Text(
                    "今天也要稳稳拿分。考试、练习、错题与班级内容都在这里。",
                    fontSize = 13.sp,
                    color = Color.White.copy(alpha = 0.88f),
                    lineHeight = 20.sp
                )
                Spacer(Modifier.height(16.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(
                        Modifier
                            .clip(RoundedCornerShape(999.dp))
                            .background(Color.White)
                            .clickable { nav.tab(Routes.EXAMS) }
                            .padding(horizontal = 18.dp, vertical = 9.dp)
                    ) {
                        Text("进入我的考试", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Tokens.Primary)
                    }
                    Box(
                        Modifier
                            .clip(RoundedCornerShape(999.dp))
                            .background(Color.White.copy(alpha = 0.14f))
                            .clickable { nav.tab(Routes.PRACTICE) }
                            .padding(horizontal = 18.dp, vertical = 9.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.PlayArrow, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
                            Spacer(Modifier.width(3.dp))
                            Text("继续练习", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color.White)
                        }
                    }
                }
            }

            SectionHeader(title = "快捷服务")
            SectionCard(padding = 12.dp) {
                quickLinks.chunked(4).forEachIndexed { rowIndex, row ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                        row.forEachIndexed { colIndex, link ->
                            val palette = Tokens.palette(rowIndex * 4 + colIndex)
                            Column(
                                Modifier.weight(1f).clip(RoundedCornerShape(16.dp))
                                    .clickable { link.onClick(nav) }
                                    .padding(vertical = 4.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                IconTile(link.icon, palette.color, palette.bg, size = 46.dp, iconSize = 22.dp)
                                Spacer(Modifier.height(7.dp))
                                Text(link.label, fontSize = 12.sp, color = Tokens.TextPrimary, maxLines = 1)
                            }
                        }
                        repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }

            if (AppConfig.registrationUrl.isNotBlank()) {
                SectionCard(Modifier.padding(top = 12.dp)) {
                    Row(
                        Modifier.fillMaxWidth().clickable {
                            val url = AppConfig.registrationUrl.trimEnd('/') + "/campaigns"
                            runCatching {
                                context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url)))
                            }
                        },
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconTile(Icons.Filled.Send, Tokens.Amber, Tokens.AmberSoft)
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text("考试报名", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Tokens.TextPrimary)
                            Text("查看招录公告、岗位与报名进度", fontSize = 12.sp, color = Tokens.TextSecondary)
                        }
                        Icon(Icons.Filled.KeyboardArrowRight, contentDescription = null, tint = Tokens.TextTertiary)
                    }
                }
            }

            AsyncContent(
                state = controller.state,
                onRetry = { controller.reload() },
                emptyCheck = { it.isEmpty() },
                emptyText = "暂无首页内容"
            ) { components ->
                components.forEach { component ->
                    when (component.componentType.uppercase()) {
                        "BANNER" -> BannerSection(component)
                        "NAV" -> NavSection(component, nav)
                        "NOTICE" -> NoticeSection(component, nav, context)
                        "HOT_EXAM" -> HotExamSection(component, nav)
                        "ARTICLE", "TEACHER", "CLASS_RECOMMEND" -> ContentSection(component, nav)
                        else -> GenericSection(component, nav)
                    }
                }
            }
            Spacer(Modifier.height(20.dp))
        }
    }
}

private fun iconFor(label: String): ImageVector = when {
    label.contains("考试组") -> Icons.Filled.CheckCircle
    label.contains("错题") -> Icons.Filled.Warning
    label.contains("练习") -> Icons.Filled.Edit
    label.contains("班级") -> Icons.Filled.Person
    label.contains("排行") -> Icons.Filled.Star
    label.contains("文章") || label.contains("内容") -> Icons.Filled.Create
    label.contains("教师") -> Icons.Filled.AccountCircle
    label.contains("通知") -> Icons.Filled.Notifications
    label.contains("日历") -> Icons.Filled.DateRange
    label.contains("成绩") -> Icons.Filled.Star
    label.contains("考试") -> Icons.Filled.List
    else -> Icons.Filled.ArrowForward
}

@Composable
private fun BannerSection(component: HomeComponent) {
    if (component.items.isEmpty()) return
    Spacer(Modifier.height(6.dp))
    LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.padding(vertical = 8.dp)) {
        items(component.items) { item ->
            Box(
                Modifier
                    .width(300.dp)
                    .height(160.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(Tokens.SurfaceAlt)
            ) {
                AsyncImage(
                    model = item.imageUrl ?: item.coverUrl,
                    contentDescription = item.title ?: item.name,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
                Box(
                    Modifier.fillMaxSize().background(
                        Brush.horizontalGradient(
                            listOf(Color(0xCC0B1B2E), Color(0x550B1B2E), Color.Transparent)
                        )
                    )
                )
                Column(
                    Modifier.align(Alignment.BottomStart).padding(16.dp)
                ) {
                    val tag = item.tag ?: "推荐"
                    Box(
                        Modifier
                            .clip(RoundedCornerShape(999.dp))
                            .background(Color.White.copy(alpha = 0.22f))
                            .padding(horizontal = 9.dp, vertical = 3.dp)
                    ) {
                        Text(tag, fontSize = 10.sp, color = Color.White)
                    }
                    Spacer(Modifier.height(7.dp))
                    Text(
                        item.title ?: item.name ?: "",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    val sub = item.summary ?: item.intro ?: item.description
                    if (!sub.isNullOrBlank()) {
                        Spacer(Modifier.height(4.dp))
                        Text(sub, fontSize = 12.sp, color = Color.White.copy(alpha = 0.9f), maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
        }
    }
}

@Composable
private fun NavSection(component: HomeComponent, nav: AppNav) {
    if (component.items.isEmpty()) return
    SectionHeader(title = component.title ?: "推荐入口")
    SectionCard(padding = 12.dp) {
        component.items.chunked(4).forEachIndexed { rowIndex, row ->
            Row(Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
                row.forEachIndexed { colIndex, item ->
                    val palette = Tokens.palette(rowIndex * 4 + colIndex)
                    val label = item.name ?: item.title ?: "入口"
                    Column(
                        Modifier.weight(1f).clip(RoundedCornerShape(16.dp))
                            .clickable { openHomeItem(item, nav) }
                            .padding(vertical = 4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        IconTile(iconFor(label), palette.color, palette.bg, size = 44.dp, iconSize = 21.dp)
                        Spacer(Modifier.height(6.dp))
                        Text(label, fontSize = 12.sp, color = Tokens.TextPrimary, maxLines = 1)
                    }
                }
                repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}

@Composable
private fun NoticeSection(component: HomeComponent, nav: AppNav, context: android.content.Context) {
    val item = component.items.firstOrNull() ?: return
    SectionCard(Modifier.padding(top = 12.dp)) {
        Row(
            Modifier.fillMaxWidth().clickable {
                val link = item.linkUrl ?: item.url
                if (!link.isNullOrBlank()) {
                    if (link.startsWith("http", true)) {
                        runCatching { context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(link))) }
                    } else {
                        nav.notifications()
                    }
                } else {
                    nav.notifications()
                }
            },
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconTile(Icons.Filled.Notifications, Tokens.Amber, Tokens.AmberSoft, size = 38.dp, iconSize = 19.dp)
            Spacer(Modifier.width(12.dp))
            Text(
                item.title ?: item.name ?: "公告通知",
                fontSize = 13.sp,
                color = Tokens.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )
            Text("查看", fontSize = 12.sp, color = Tokens.Amber)
            Icon(Icons.Filled.KeyboardArrowRight, contentDescription = null, tint = Tokens.Amber, modifier = Modifier.size(18.dp))
        }
    }
}

@Composable
private fun HotExamSection(component: HomeComponent, nav: AppNav) {
    if (component.items.isEmpty()) return
    SectionHeader(title = component.title ?: "热门考试", actionLabel = "全部考试") { nav.tab(Routes.EXAMS) }
    LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.padding(bottom = 2.dp)) {
        items(component.items) { item ->
            Column(
                Modifier
                    .width(220.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(Tokens.Surface)
                    .clickable { nav.tab(Routes.EXAMS) }
                    .padding(14.dp)
            ) {
                Box(
                    Modifier.clip(RoundedCornerShape(999.dp)).background(Tokens.PrimarySoft)
                        .padding(horizontal = 9.dp, vertical = 3.dp)
                ) {
                    Text("待参加", fontSize = 10.sp, color = Tokens.Primary)
                }
                Spacer(Modifier.height(9.dp))
                Text(
                    item.title ?: item.name ?: "",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Tokens.TextPrimary,
                    minLines = 2,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(Modifier.height(6.dp))
                Text(item.summary ?: "点击查看考试详情", fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

@Composable
private fun ContentSection(component: HomeComponent, nav: AppNav) {
    if (component.items.isEmpty()) return
    val type = component.componentType.uppercase()
    SectionHeader(
        title = component.title ?: when (type) {
            "TEACHER" -> "教师风采"
            "CLASS_RECOMMEND" -> "推荐班级"
            else -> "精选内容"
        },
        actionLabel = "查看更多"
    ) {
        when (type) {
            "TEACHER" -> nav.teachers()
            "CLASS_RECOMMEND" -> nav.classes()
            else -> nav.articles()
        }
    }
    SectionCard(padding = 14.dp) {
        component.items.forEachIndexed { index, item ->
            Row(
                Modifier.fillMaxWidth().clickable { openHomeItem(item, nav) }.padding(vertical = 9.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (!item.coverUrl.isNullOrBlank() || !item.avatarUrl.isNullOrBlank()) {
                    AsyncImage(
                        model = item.coverUrl ?: item.avatarUrl,
                        contentDescription = null,
                        modifier = Modifier.size(58.dp).clip(RoundedCornerShape(14.dp)),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    val palette = Tokens.palette(index)
                    IconTile(iconFor(item.title ?: item.name ?: component.title ?: ""), palette.color, palette.bg, size = 52.dp, iconSize = 23.dp)
                }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(
                        item.title ?: item.name ?: "",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Tokens.TextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    val sub = item.summary ?: item.intro ?: item.description ?: item.category
                    if (!sub.isNullOrBlank()) {
                        Spacer(Modifier.height(3.dp))
                        Text(sub, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                }
                Icon(Icons.Filled.KeyboardArrowRight, contentDescription = null, tint = Tokens.TextTertiary)
            }
            if (index < component.items.size - 1) DividerLine()
        }
    }
}

@Composable
private fun GenericSection(component: HomeComponent, nav: AppNav) {
    if (component.items.isEmpty()) return
    SectionHeader(title = component.title ?: "更多内容")
    SectionCard {
        component.items.forEachIndexed { index, item ->
            Row(
                Modifier.fillMaxWidth().clickable { openHomeItem(item, nav) }.padding(vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (!item.coverUrl.isNullOrBlank() || !item.avatarUrl.isNullOrBlank()) {
                    AsyncImage(
                        model = item.coverUrl ?: item.avatarUrl,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp).clip(RoundedCornerShape(12.dp)),
                        contentScale = ContentScale.Crop
                    )
                    Spacer(Modifier.width(12.dp))
                }
                Column(Modifier.weight(1f)) {
                    Text(item.title ?: item.name ?: "", fontSize = 15.sp, fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    val sub = item.summary ?: item.intro ?: item.description ?: item.category
                    if (!sub.isNullOrBlank()) Text(sub, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                Icon(Icons.Filled.KeyboardArrowRight, contentDescription = null, tint = Tokens.TextTertiary)
            }
            if (index < component.items.size - 1) DividerLine()
        }
    }
}

private fun openHomeItem(item: HomeItem, nav: AppNav) {
    val path = item.path.orEmpty().lowercase()
    val label = (item.title ?: item.name ?: item.category ?: "").lowercase()
    when {
        path.contains("exam") || label.contains("考试") -> nav.tab(Routes.EXAMS)
        path.contains("practice") || label.contains("练习") -> nav.tab(Routes.PRACTICE)
        path.contains("class") || label.contains("班级") -> nav.classes()
        path.contains("teacher") || label.contains("教师") -> nav.teachers()
        path.contains("notification") || label.contains("通知") -> nav.notifications()
        path.contains("article") || label.contains("文章") -> item.id?.let { nav.articleDetail(it) } ?: nav.articles()
        else -> item.id?.let { nav.articleDetail(it) }
    }
}
