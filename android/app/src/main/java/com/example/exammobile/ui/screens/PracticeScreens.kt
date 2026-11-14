package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.exammobile.core.model.PracticeAnswerRequest
import com.example.exammobile.core.model.PracticeVerdict
import com.example.exammobile.core.model.PracticeRecord
import com.example.exammobile.core.model.PracticeSet
import com.example.exammobile.core.model.PracticeStatistics
import com.example.exammobile.core.model.Question
import com.example.exammobile.core.model.WrongQuestion
import com.example.exammobile.core.util.Formatters
import com.example.exammobile.core.util.UiState
import com.example.exammobile.data.CandidateRepository
import com.example.exammobile.ui.components.*
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.util.rememberRemote
import com.example.exammobile.ui.util.toast
import com.example.exammobile.ui.util.userMessage
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive

@Composable
fun PracticeListScreen(repository: CandidateRepository, nav: AppNav) {
    val setsController = rememberRemote("sets") { repository.practiceSets() }
    val statsController = rememberRemote("stats") { repository.practiceStatistics() }

    PageScaffold(title = "在线练习", actions = {
        Text("统计", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.padding(end = 16.dp).clickable { nav.practiceStats() })
    }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
            val stats = (statsController.state as? UiState.Success)?.data
            if (stats != null) {
                SectionCard {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
                        StatCell("练习次数", "${stats.totalRecords}")
                        StatCell("完成", "${stats.finishedRecords}")
                        StatCell("正确率", "${(stats.averageAccuracy * 100).toInt()}%")
                        StatCell("题量", "${stats.totalQuestions}")
                    }
                }
                Spacer(Modifier.height(12.dp))
            }
            AsyncContent(
                state = setsController.state,
                onRetry = { setsController.reload() },
                emptyCheck = { it.isEmpty() },
                emptyText = "暂无练习题集"
            ) { sets ->
                sets.forEach { set -> PracticeSetCard(set) { nav.practiceTaking(set.id) } }
            }
        }
    }
}

@Composable
private fun StatCell(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Tokens.Primary)
        Text(label, fontSize = 12.sp, color = Tokens.TextSecondary)
    }
}

@Composable
private fun PracticeSetCard(set: PracticeSet, onClick: () -> Unit) {
    SectionCard(Modifier.padding(vertical = 6.dp)) {
        Row(Modifier.clickable(onClick = onClick), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(set.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                if (!set.description.isNullOrBlank()) {
                    Text(set.description, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                Spacer(Modifier.height(6.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("${set.questionCount} 题", fontSize = 12.sp, color = Tokens.TextSecondary)
                    set.totalScore?.let { Text("${Formatters.scoreText(it)} 分", fontSize = 12.sp, color = Tokens.TextSecondary) }
                }
            }
            TagPill("开始练习", Tokens.Primary, Tokens.PrimarySoft)
        }
    }
}

@Composable
fun PracticeStatsScreen(repository: CandidateRepository, nav: AppNav) {
    val controller = rememberRemote("practice-stats") { repository.practiceStatistics() }
    PageScaffold(title = "练习统计", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }) { stats: PracticeStatistics ->
            Column(Modifier.padding(padding).fillMaxSize().padding(16.dp)) {
                SectionCard {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
                        StatCell("练习次数", "${stats.totalRecords}")
                        StatCell("完成", "${stats.finishedRecords}")
                        StatCell("正确率", "${(stats.averageAccuracy * 100).toInt()}%")
                    }
                    Spacer(Modifier.height(16.dp))
                    KeyValueRow("累计做题", "${stats.totalQuestions}")
                    KeyValueRow("答对", "${stats.correctQuestions}")
                }
            }
        }
    }
}

@Composable
fun PracticeTakingScreen(repository: CandidateRepository, setId: String, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var record by remember { mutableStateOf<PracticeRecord?>(null) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var index by remember { mutableIntStateOf(0) }
    var selected by remember { mutableStateOf<List<String>>(emptyList()) }
    var verdict by remember { mutableStateOf<PracticeVerdict?>(null) }
    var submitting by remember { mutableStateOf(false) }

    LaunchedEffect(setId) {
        loading = true
        runCatching { repository.practiceStart(setId) }
            .onSuccess { record = it; loading = false }
            .onFailure { error = it.userMessage(); loading = false }
    }

    PageScaffold(title = "在线练习", onBack = { nav.back() }) { padding ->
        when {
            loading -> LoadingState(Modifier.padding(padding))
            error != null -> Column(Modifier.padding(padding).padding(16.dp)) { ErrorBanner(error!!) }
            record != null -> {
                val rec = record!!
                val questions = if (rec.questions.isNotEmpty()) rec.questions else listOfNotNull(rec.question)
                val current = questions.getOrNull(index)

                fun submitCurrent() {
                    if (current == null || submitting || verdict != null) return
                    val answerJson = JsonArray(selected.map { JsonPrimitive(it) }).toString()
                    scope.launch {
                        submitting = true
                        runCatching {
                            repository.practiceAnswer(rec.recordId, PracticeAnswerRequest(current.questionId, answerJson))
                        }.onSuccess { verdict = it }
                            .onFailure { context.toast(it.userMessage()) }
                        submitting = false
                    }
                }

                fun next() {
                    if (verdict == null) return
                    if (index < questions.size - 1) {
                        index += 1
                        selected = emptyList()
                        verdict = null
                    } else {
                        scope.launch {
                            runCatching { repository.practiceFinish(rec.recordId) }
                                .onSuccess { context.toast("练习完成"); nav.back() }
                                .onFailure { context.toast(it.userMessage()) }
                        }
                    }
                }

                Column(Modifier.padding(padding).fillMaxSize()) {
                    Row(
                        Modifier.fillMaxWidth().background(Tokens.PrimarySoft).padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("${rec.title ?: rec.setName.ifBlank { "练习" }} · 第 ${rec.attemptNo ?: 1} 次", fontSize = 13.sp, color = Tokens.TextSecondary)
                        Text(
                            "${rec.answeredCount ?: (index + 1)}/${rec.questionCount ?: questions.size} · 对 ${rec.correctCount ?: 0} / 错 ${rec.wrongCount ?: 0}",
                            fontSize = 12.sp, color = Tokens.TextSecondary
                        )
                    }
                    if (current != null) {
                        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(16.dp)) {
                            PracticeQuestionCard(current, selected, verdict != null) { key ->
                                if (verdict == null) {
                                    selected = if (current.type.ifBlank { current.typeCode ?: "" } == "MULTIPLE") {
                                        if (selected.contains(key)) selected - key else selected + key
                                    } else listOf(key)
                                }
                            }
                            verdict?.let { v ->
                                Spacer(Modifier.height(12.dp))
                                SectionCard {
                                    Text(
                                        if (v.correct == true) "回答正确" else "回答错误",
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = if (v.correct == true) Tokens.Success else Tokens.Danger
                                    )
                                    if (!v.expectedText.isNullOrBlank()) {
                                        Spacer(Modifier.height(6.dp))
                                        Text("正确答案：${v.expectedText}", fontSize = 13.sp, color = Tokens.Success)
                                    }
                                    if (!v.analysis.isNullOrBlank()) {
                                        Spacer(Modifier.height(8.dp))
                                        Box(
                                            Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
                                                .background(Tokens.SurfaceAlt).padding(10.dp)
                                        ) {
                                            Column {
                                                Text("解析", fontSize = 12.sp, color = Tokens.TextSecondary)
                                                Spacer(Modifier.height(4.dp))
                                                RichContentView(v.analysis, fontSizeSp = 13)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Row(
                            Modifier.fillMaxWidth().background(Tokens.Surface).padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            SecondaryButton(
                                "上一题",
                                onClick = { if (index > 0) { index--; selected = emptyList(); verdict = null } },
                                enabled = index > 0 && verdict == null
                            )
                            if (verdict == null) {
                                Button(
                                    onClick = { submitCurrent() },
                                    enabled = !submitting && selected.isNotEmpty(),
                                    shape = RoundedCornerShape(999.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = Tokens.Primary)
                                ) { Text(if (submitting) "提交中…" else "提交本题") }
                            } else {
                                Button(
                                    onClick = { next() },
                                    shape = RoundedCornerShape(999.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = if (index < questions.size - 1) Tokens.Primary else Tokens.Success)
                                ) { Text(if (index < questions.size - 1) "下一题" else "完成") }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PracticeQuestionCard(question: Question, selected: List<String>, verdictShown: Boolean, onChoose: (String) -> Unit) {
    val type = question.type.ifBlank { question.typeCode ?: "" }
    val (fg, bg) = Tokens.typeColor(type)
    SectionCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TagPill(Formatters.questionTypeLabel(type), fg, bg)
            Spacer(Modifier.width(8.dp))
            Text("${Formatters.scoreText(question.score)} 分", fontSize = 12.sp, color = Tokens.TextSecondary)
        }
        Spacer(Modifier.height(12.dp))
        RichContentView(question.stem, fontSizeSp = 16)
        Spacer(Modifier.height(14.dp))
        question.options.forEach { option ->
            val isSel = selected.contains(option.key)
            Row(
                Modifier.fillMaxWidth().padding(vertical = 5.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(if (isSel) Tokens.PrimarySoft else Tokens.SurfaceAlt)
                    .clickable { onChoose(option.key) }
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(option.key, fontWeight = FontWeight.Bold, color = if (isSel) Tokens.Primary else Tokens.TextPrimary)
                Spacer(Modifier.width(10.dp))
                HtmlText(option.text ?: option.content, fontSizeSp = 15)
            }
        }
    }
}

@Composable
fun WrongScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var includeMastered by remember { mutableStateOf(false) }
    val controller = rememberRemote(includeMastered) { repository.wrongQuestions(includeMastered = includeMastered) }

    PageScaffold(title = "我的错题集", onBack = { nav.back() }, actions = {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(end = 12.dp)) {
            Text("含已掌握", fontSize = 12.sp, color = Tokens.TextSecondary)
            Switch(checked = includeMastered, onCheckedChange = { includeMastered = it })
        }
    }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无错题") { list ->
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                list.forEach { wrong ->
                    WrongCard(wrong) {
                        scope.launch {
                            runCatching {
                                if (wrong.mastered) repository.unmasterWrong(wrong.id) else repository.masterWrong(wrong.id)
                            }.onSuccess { controller.reload() }.onFailure { context.toast(it.userMessage()) }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun WrongCard(wrong: WrongQuestion, onToggleMaster: () -> Unit) {
    SectionCard(Modifier.padding(vertical = 6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TagPill(wrong.questionType?.let { Formatters.questionTypeLabel(it) } ?: "题目", Tokens.Primary, Tokens.PrimarySoft)
            Spacer(Modifier.width(8.dp))
            Text("错 ${wrong.wrongCount} 次", fontSize = 12.sp, color = Tokens.TextSecondary)
            Spacer(Modifier.weight(1f))
            Text(
                if (wrong.mastered) "取消掌握" else "标记掌握",
                fontSize = 12.sp,
                color = if (wrong.mastered) Tokens.TextSecondary else Tokens.Primary,
                modifier = Modifier.clickable(onClick = onToggleMaster)
            )
        }
        Spacer(Modifier.height(8.dp))
        Text(wrong.stem ?: "题目内容", fontSize = 15.sp, maxLines = 3, overflow = TextOverflow.Ellipsis)
        if (wrong.mastered) {
            Spacer(Modifier.height(6.dp))
            TagPill("已掌握", Tokens.Success, Tokens.SuccessSoft)
        }
    }
}
