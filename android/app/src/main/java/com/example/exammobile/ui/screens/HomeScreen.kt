package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
import com.example.exammobile.core.util.Formatters
import com.example.exammobile.data.CandidateRepository
import com.example.exammobile.ui.components.*
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.navigation.Routes
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.util.rememberRemote
import java.util.Calendar

private data class QuickLink(val label: String, val onClick: (AppNav) -> Unit)

@Composable
fun HomeScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val controller = rememberRemote("home") { repository.home() }
    val greeting = Formatters.greeting(Calendar.getInstance().get(Calendar.HOUR_OF_DAY))

    val quickLinks = listOf(
        QuickLink("我的考试") { it.tab(Routes.EXAMS) },
        QuickLink("在线练习") { it.tab(Routes.PRACTICE) },
        QuickLink("错题集") { it.wrong() },
        QuickLink("班级") { it.classes() },
        QuickLink("考试组") { it.examGroups() },
        QuickLink("排行榜") { it.ranking() },
        QuickLink("文章") { it.articles() },
        QuickLink("教师风采") { it.teachers() }
    )

    PageScaffold(title = "首页", actions = {
        Text(
            "我的考试",
            color = Tokens.Primary,
            fontSize = 13.sp,
            modifier = Modifier.padding(end = 16.dp).clickable { nav.tab(Routes.EXAMS) }
        )
    }) { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = PagePadding, vertical = 8.dp)
        ) {
            Column(Modifier.padding(vertical = 12.dp)) {
                Text("$greeting，同学", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Tokens.TextPrimary)
                Text("考试、练习、班级与学习内容都在这里。", fontSize = 13.sp, color = Tokens.TextSecondary)
            }

            SectionCard {
                quickLinks.chunked(4).forEach { row ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
                        row.forEach { link ->
                            Column(
                                Modifier.weight(1f).clickable { link.onClick(nav) },
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Box(
                                    Modifier.size(42.dp).clip(RoundedCornerShape(12.dp)).background(Tokens.PrimarySoft),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(link.label.take(1), color = Tokens.Primary, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                                }
                                Spacer(Modifier.height(6.dp))
                                Text(link.label, fontSize = 12.sp, color = Tokens.TextPrimary)
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
                        Column(Modifier.weight(1f)) {
                            Text("考试报名", fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = Tokens.TextPrimary)
                            Text("查看招录公告、岗位与报名进度", fontSize = 12.sp, color = Tokens.TextSecondary)
                        }
                        Text("›", fontSize = 20.sp, color = Tokens.TextTertiary)
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
                        "BANNER" -> BannerRow(component)
                        "NAV" -> NavGrid(component, nav)
                        else -> ComponentList(component, nav)
                    }
                }
            }
            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
private fun BannerRow(component: HomeComponent) {
    if (component.items.isEmpty()) return
    LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.padding(vertical = 12.dp)) {
        items(component.items) { item ->
            Column(Modifier.width(280.dp).clip(RoundedCornerShape(14.dp)).background(Tokens.Surface)) {
                AsyncImage(
                    model = item.imageUrl ?: item.coverUrl,
                    contentDescription = item.title,
                    modifier = Modifier.fillMaxWidth().height(130.dp),
                    contentScale = ContentScale.Crop
                )
                Text(
                    item.title ?: item.name ?: "",
                    fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Tokens.TextPrimary,
                    modifier = Modifier.padding(10.dp), maxLines = 1, overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun NavGrid(component: HomeComponent, nav: AppNav) {
    if (component.items.isEmpty()) return
    SectionCard(Modifier.padding(vertical = 8.dp)) {
        Row(Modifier.fillMaxWidth()) {
            component.items.take(4).forEach { item ->
                Column(Modifier.weight(1f).clickable { openHomeItem(item, nav) }, horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        Modifier.size(40.dp).clip(RoundedCornerShape(12.dp)).background(Tokens.PrimarySoft),
                        contentAlignment = Alignment.Center
                    ) { Text((item.name ?: item.title ?: "·").take(1), color = Tokens.Primary, fontWeight = FontWeight.Bold) }
                    Spacer(Modifier.height(6.dp))
                    Text(item.name ?: item.title ?: "", fontSize = 12.sp, color = Tokens.TextPrimary)
                }
            }
        }
    }
}

@Composable
private fun ComponentList(component: HomeComponent, nav: AppNav) {
    if (component.items.isEmpty()) return
    SectionTitle(component.title ?: "")
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
                        modifier = Modifier.size(48.dp).clip(RoundedCornerShape(10.dp)),
                        contentScale = ContentScale.Crop
                    )
                    Spacer(Modifier.width(12.dp))
                }
                Column(Modifier.weight(1f)) {
                    Text(item.title ?: item.name ?: "", fontSize = 15.sp, fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    val sub = item.summary ?: item.intro ?: item.description ?: item.category
                    if (!sub.isNullOrBlank()) Text(sub, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
            if (index < component.items.size - 1) DividerLine()
        }
    }
}

private fun openHomeItem(item: HomeItem, nav: AppNav) {
    val path = item.path.orEmpty()
    when {
        path.contains("exam") -> nav.tab(Routes.EXAMS)
        path.contains("class") -> nav.classes()
        path.contains("teacher") -> nav.teachers()
        path.contains("notification") -> nav.notifications()
        else -> item.id?.let { nav.articleDetail(it) }
    }
}
