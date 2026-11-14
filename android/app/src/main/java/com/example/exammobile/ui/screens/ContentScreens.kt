package com.example.exammobile.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.exammobile.data.CandidateRepository
import com.example.exammobile.ui.components.*
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.util.rememberRemote

@Composable
fun ArticleListScreen(repository: CandidateRepository, nav: AppNav) {
    val controller = rememberRemote("articles") { repository.articles() }
    PageScaffold(title = "内容", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无文章") { list ->
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                list.forEach { article ->
                    SectionCard(Modifier.padding(vertical = 6.dp)) {
                        Row(Modifier.clickable { nav.articleDetail(article.id) }, verticalAlignment = Alignment.CenterVertically) {
                            if (!article.coverUrl.isNullOrBlank()) {
                                AsyncImage(
                                    model = article.coverUrl,
                                    contentDescription = null,
                                    modifier = Modifier.size(64.dp).clip(RoundedCornerShape(10.dp)),
                                    contentScale = ContentScale.Crop
                                )
                                Spacer(Modifier.width(12.dp))
                            }
                            Column(Modifier.weight(1f)) {
                                Text(article.title, fontSize = 15.sp, fontWeight = FontWeight.Medium, maxLines = 2, overflow = TextOverflow.Ellipsis)
                                val sub = article.summary ?: article.category
                                if (!sub.isNullOrBlank()) {
                                    Spacer(Modifier.height(4.dp))
                                    Text(sub, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 2, overflow = TextOverflow.Ellipsis)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ArticleDetailScreen(repository: CandidateRepository, articleId: String, nav: AppNav) {
    val controller = rememberRemote(articleId) { repository.article(articleId) }
    PageScaffold(title = "详情", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }) { article ->
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                Text(article.title, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Tokens.TextPrimary)
                if (!article.createdAt.isNullOrBlank()) {
                    Spacer(Modifier.height(6.dp))
                    Text(article.createdAt, fontSize = 12.sp, color = Tokens.TextSecondary)
                }
                Spacer(Modifier.height(16.dp))
                SectionCard {
                    RichContentView(article.content ?: article.summary ?: "暂无内容", fontSizeSp = 15)
                }
            }
        }
    }
}

@Composable
fun TeacherScreen(repository: CandidateRepository, nav: AppNav) {
    val controller = rememberRemote("teachers") { repository.showcaseTeachers() }
    PageScaffold(title = "教师风采", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无教师信息") { list ->
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                list.forEach { teacher ->
                    SectionCard(Modifier.padding(vertical = 6.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            AsyncImage(
                                model = teacher.avatarUrl,
                                contentDescription = teacher.name,
                                modifier = Modifier.size(56.dp).clip(RoundedCornerShape(28.dp)),
                                contentScale = ContentScale.Crop
                            )
                            Spacer(Modifier.width(14.dp))
                            Column(Modifier.weight(1f)) {
                                Text(teacher.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                                if (!teacher.title.isNullOrBlank()) Text(teacher.title, fontSize = 12.sp, color = Tokens.Primary)
                                if (!teacher.intro.isNullOrBlank()) {
                                    Spacer(Modifier.height(4.dp))
                                    Text(teacher.intro, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 3, overflow = TextOverflow.Ellipsis)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
