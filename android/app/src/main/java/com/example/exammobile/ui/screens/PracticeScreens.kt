package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
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
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var reload by remember { mutableIntStateOf(0) }
    var passwordDialog by remember { mutableStateOf(false) }
    var passwordValue by remember { mutableStateOf("") }
    var pendingSet by remember { mutableStateOf<PracticeSet?>(null) }
    val setsController = rememberRemote("sets-$reload") { repository.practiceSets() }
    val statsController = rememberRemote("stats-$reload") { repository.practiceStatistics() }

    fun start(set: PracticeSet, password: String? = null) {
        scope.launch {
            runCatching { repository.practiceStart(set.id, password) }
                .onSuccess { record ->
                    context.toast("已进入练习")
                    nav.practiceTaking(record.recordId.ifBlank { record.setId })
                }
                .onFailure { context.toast(it.userMessage()) }
        }
    }

    fun open(set: PracticeSet) {
        if (!set.unlocked) {
            val reason = set.lockReason.orEmpty()
            if (reason.contains("密码")) {
                pendingSet = set
                passwordValue = ""
                passwordDialog = true
                return
            }
            context.toast(reason.ifBlank { "该练习需要先满足进入条件" })
            if (reason.contains("购买")) {
                nav.memberOrder("PRACTICE", set.id)
            }
            return
        }
        if (set.accessMode == "POINTS") {
            context.toast("将消耗 ${set.pointsCost ?: 0} 积分进入")
        }
        start(set)
    }

    PageScaffold(title = "在线练习", onBack = { nav.back() }, actions = {
        Text(
            "统计",
            color = Tokens.Primary,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(end = 16.dp).clickable { nav.practiceStats() }
        )
    }) { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = PagePadding, vertical = 10.dp)
        ) {
            GradientHero(gradient = Tokens.AccentGradient) {
                Text("在线练习", fontSize = 21.sp, fontWeight = FontWeight.Bold, color = Color.White)
                Spacer(Modifier.height(5.dp))
                Text("逐题判定、自动收录错题，坚持每天进步一点。", fontSize = 13.sp, color = Color.White.copy(alpha = 0.88f))
            }

            val stats = (statsController.state as? UiState.Success)?.data
            if (stats != null) {
                SectionHeader(title = "练习概览", actionLabel = "详细统计") { nav.practiceStats() }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    StatTile("练习次数", "${stats.totalRecords}", Modifier.weight(1f), Tokens.Primary, Tokens.PrimarySoft)
                    StatTile("完成", "${stats.finishedRecords}", Modifier.weight(1f), Tokens.Accent, Tokens.AccentSoft)
                    StatTile("正确率", "${(stats.averageAccuracy * 100).toInt()}%", Modifier.weight(1f), Tokens.Success, Tokens.SuccessSoft)
                    StatTile("题量", "${stats.totalQuestions}", Modifier.weight(1f), Tokens.Violet, Tokens.VioletSoft)
                }
            }

            SectionHeader(title = "练习题库")
            AsyncContent(
                state = setsController.state,
                onRetry = { setsController.reload() },
                emptyCheck = { it.isEmpty() },
                emptyText = "暂无练习题集"
            ) { sets ->
                sets.forEach { set -> PracticeSetCard(set) { open(set) } }
            }
            Spacer(Modifier.height(20.dp))
        }
    }

    if (passwordDialog && pendingSet != null) {
        AlertDialog(
            onDismissRequest = { passwordDialog = false },
            title = { Text("请输入练习密码") },
            text = {
                OutlinedTextField(
                    value = passwordValue,
                    onValueChange = { passwordValue = it },
                    placeholder = { Text("练习密码") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    val target = pendingSet
                    passwordDialog = false
                    if (target != null) start(target, passwordValue.trim())
                }) { Text("进入练习") }
            },
            dismissButton = { TextButton(onClick = { passwordDialog = false }) { Text("取消") } }
        )
    }
}

private fun practiceModeText(mode: String?): String = when (mode) {
    "FIXED" -> "固定试题"
    "RANDOM" -> "随机抽题"
    "SHUFFLE" -> "顺序随机"
    else -> "在线练习"
}

@Composable
private fun PracticeSetCard(set: PracticeSet, onClick: () -> Unit) {
    SectionCard(Modifier.padding(vertical = 6.dp)) {
        Row(Modifier.clickable(onClick = onClick), verticalAlignment = Alignment.CenterVertically) {
            IconTile(Icons.Filled.Edit, Tokens.Accent, Tokens.AccentSoft, size = 46.dp)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(set.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = Tokens.TextPrimary, maxLines = 2, overflow = TextOverflow.Ellipsis)
                if (!set.description.isNullOrBlank()) {
                    Spacer(Modifier.height(3.dp))
                    Text(set.description, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                Spacer(Modifier.height(7.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    TagPill(practiceModeText(set.mode), Tokens.Accent, Tokens.AccentSoft)
                    Text("${set.questionCount} 题", fontSize = 11.sp, color = Tokens.TextSecondary)
                    set.durationSeconds?.takeIf { it > 0 }?.let {
                        Text("限时 ${(it + 59) / 60} 分钟", fontSize = 11.sp, color = Tokens.TextSecondary)
                    }
                    set.pointsCost?.takeIf { it > 0 }?.let {
                        Text("${it} 积分", fontSize = 11.sp, color = Tokens.Amber)
                    }
                    set.price?.takeIf { it > 0 }?.let {
                        Text("¥${Formatters.scoreText(it)}", fontSize = 11.sp, color = Tokens.Danger)
                    }
                }
            }
            Spacer(Modifier.width(8.dp))
            val (label, fg, bg) = when {
                !set.unlocked -> Triple(set.lockReason?.take(6) ?: "未开放", Tokens.Warning, Tokens.WarningSoft)
                set.joined -> Triple("继续练习", Tokens.Success, Tokens.SuccessSoft)
                else -> Triple("开始练习", Tokens.Primary, Tokens.PrimarySoft)
            }
            TagPill(label, fg, bg)
        }
    }
}

@Composable
fun PracticeStatsScreen(repository: CandidateRepository, nav: AppNav) {
    val controller = rememberRemote("practice-stats") { repository.practiceStatistics() }
    PageScaffold(title = "练习统计", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }) { stats: PracticeStatistics ->
            Column(
                Modifier.padding(padding).fillMaxSize()
                    .verticalScroll(rememberScrollState()).padding(16.dp)
            ) {
                GradientHero(gradient = Tokens.AccentGradient) {
                    Text("练习数据", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
                    Spacer(Modifier.height(5.dp))
                    Text("每一次练习都在积累底气", fontSize = 13.sp, color = Color.White.copy(alpha = 0.88f))
                }
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    StatTile("练习次数", "${stats.totalRecords}", Modifier.weight(1f), Tokens.Primary, Tokens.PrimarySoft)
                    StatTile("完成", "${stats.finishedRecords}", Modifier.weight(1f), Tokens.Accent, Tokens.AccentSoft)
                    StatTile("正确率", "${(stats.averageAccuracy * 100).toInt()}%", Modifier.weight(1f), Tokens.Success, Tokens.SuccessSoft)
                }
                Spacer(Modifier.height(12.dp))
                SectionCard {
                    KeyValueRow("累计做题", "${stats.totalQuestions}")
                    KeyValueRow("答对", "${stats.correctQuestions}")
                    KeyValueRow("答错", "${(stats.totalQuestions - stats.correctQuestions).coerceAtLeast(0)}")
                }
            }
        }
    }
}

@Composable
fun PracticeTakingScreen(repository: CandidateRepository, recordId: String, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var record by remember { mutableStateOf<PracticeRecord?>(null) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var index by remember { mutableIntStateOf(0) }
    var selected by remember { mutableStateOf<List<String>>(emptyList()) }
    var fillInputs by remember { mutableStateOf<List<String>>(emptyList()) }
    var essayText by remember { mutableStateOf("") }
    var verdict by remember { mutableStateOf<PracticeVerdict?>(null) }
    var submitting by remember { mutableStateOf(false) }
    var showDone by remember { mutableStateOf(false) }
    var answeredCount by remember { mutableIntStateOf(0) }
    var correctCount by remember { mutableIntStateOf(0) }
    var wrongCount by remember { mutableIntStateOf(0) }

    LaunchedEffect(recordId) {
        loading = true
        runCatching { repository.practiceState(recordId) }
            .onSuccess {
                record = it
                answeredCount = it.answeredCount ?: 0
                correctCount = it.correctCount
                wrongCount = it.wrongCount
                index = it.currentIndex.coerceAtLeast(0)
                loading = false
            }
            .onFailure { error = it.userMessage(); loading = false }
    }

    PageScaffold(title = "在线练习", onBack = { nav.back() }) { padding ->
        when {
            loading -> LoadingState(Modifier.padding(padding))
            error != null -> Column(Modifier.padding(padding).padding(16.dp)) {
                ErrorBanner(error!!)
                Spacer(Modifier.height(12.dp))
                SecondaryButton("重试", onClick = {
                    error = null
                    loading = true
                    scope.launch {
                        runCatching { repository.practiceState(recordId) }
                            .onSuccess { record = it; loading = false }
                            .onFailure { error = it.userMessage(); loading = false }
                    }
                })
            }
            record != null -> {
                val rec = record!!
                val questions = if (rec.questions.isNotEmpty()) rec.questions else listOfNotNull(rec.question)
                val current = questions.getOrNull(index)
                val type = current?.let { it.type.ifBlank { it.typeCode ?: "" } }.orEmpty()
                val blanks = current?.blanks?.coerceAtLeast(1) ?: 1

                fun submitCurrent() {
                    val question = current ?: return
                    if (submitting || verdict != null) return
                    val payloadJson = when {
                        question.options.isNotEmpty() -> JsonArray(selected.map { JsonPrimitive(it) }).toString()
                        type == "FILL" -> JsonArray(fillInputs.map { JsonPrimitive(it) }).toString()
                        else -> null
                    }
                    val payloadText = if (type == "ESSAY") essayText else null
                    if (payloadJson == null && payloadText.isNullOrBlank()) {
                        context.toast("请先作答本题")
                        return
                    }
                    scope.launch {
                        submitting = true
                        runCatching {
                            repository.practiceAnswer(
                                rec.recordId,
                                PracticeAnswerRequest(
                                    questionId = question.questionId.ifBlank { question.paperQuestionId },
                                    answerJson = payloadJson,
                                    answerText = payloadText
                                )
                            )
                        }.onSuccess { v ->
                            verdict = v
                            answeredCount = v.answeredCount ?: (answeredCount + 1)
                            correctCount = v.correctCount ?: (correctCount + if (v.correct == true) 1 else 0)
                            wrongCount = v.wrongCount ?: (wrongCount + if (v.correct == false) 1 else 0)
                        }.onFailure { context.toast(it.userMessage()) }
                        submitting = false
                    }
                }

                fun next() {
                    if (verdict == null) return
                    if (index < questions.size - 1) {
                        index += 1
                        selected = emptyList()
                        fillInputs = List(blanks) { "" }
                        essayText = ""
                        verdict = null
                    } else {
                        showDone = true
                    }
                }

                fun finishAndExit() {
                    scope.launch {
                        runCatching { repository.practiceFinish(rec.recordId) }
                            .onSuccess { context.toast("练习完成"); nav.back() }
                            .onFailure { context.toast(it.userMessage()) }
                    }
                }

                LaunchedEffect(current?.paperQuestionId, current?.questionId) {
                    if (verdict == null) {
                        fillInputs = List(blanks) { "" }
                        selected = emptyList()
                        essayText = ""
                    }
                }

                Column(Modifier.padding(padding).fillMaxSize()) {
                    Box(
                        Modifier.fillMaxWidth().background(Tokens.Surface).padding(horizontal = 16.dp, vertical = 10.dp)
                    ) {
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    rec.title ?: rec.setName.ifBlank { "练习" },
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Tokens.TextPrimary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text("第 ${rec.attemptNo ?: 1} 次练习", fontSize = 11.sp, color = Tokens.TextSecondary)
                            }
                            TagPill("已答 $answeredCount/${rec.questionCount ?: questions.size}", Tokens.Primary, Tokens.PrimarySoft)
                            Spacer(Modifier.width(6.dp))
                            TagPill("对 $correctCount", Tokens.Success, Tokens.SuccessSoft)
                            Spacer(Modifier.width(6.dp))
                            TagPill("错 $wrongCount", Tokens.Danger, Tokens.DangerSoft)
                        }
                    }
                    if (current != null) {
                        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(16.dp)) {
                            SectionCard {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    val (fg, bg) = Tokens.typeColor(type)
                                    TagPill(Formatters.questionTypeLabel(type), fg, bg)
                                    Spacer(Modifier.width(8.dp))
                                    Text("第 ${index + 1} / ${questions.size} 题", fontSize = 12.sp, color = Tokens.TextSecondary)
                                    Spacer(Modifier.weight(1f))
                                    Text("${Formatters.scoreText(current.score)} 分", fontSize = 12.sp, color = Tokens.TextSecondary)
                                }
                                Spacer(Modifier.height(14.dp))
                                RichContentView(current.stem, fontSizeSp = 16)
                                Spacer(Modifier.height(14.dp))

                                if (current.options.isNotEmpty()) {
                                    val expectedKeys = verdict?.expectedKeys.orEmpty().map { it.uppercase() }
                                    current.options.forEach { option ->
                                        val isSel = selected.contains(option.key)
                                        val showCorrect = verdict != null && expectedKeys.contains(option.key.uppercase())
                                        Row(
                                            Modifier.fillMaxWidth().padding(vertical = 5.dp)
                                                .clip(RoundedCornerShape(12.dp))
                                                .background(
                                                    when {
                                                        showCorrect -> Tokens.SuccessSoft
                                                        isSel -> Tokens.PrimarySoft
                                                        else -> Tokens.SurfaceAlt.copy(alpha = 0.55f)
                                                    }
                                                )
                                                .clickable(enabled = verdict == null) {
                                                    selected = if (type == "MULTIPLE") {
                                                        if (selected.contains(option.key)) selected - option.key else selected + option.key
                                                    } else {
                                                        listOf(option.key)
                                                    }
                                                }
                                                .padding(12.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Box(
                                                Modifier.size(26.dp).clip(RoundedCornerShape(13.dp))
                                                    .background(
                                                        when {
                                                            showCorrect -> Tokens.Success
                                                            isSel -> Tokens.Primary
                                                            else -> Tokens.Surface
                                                        }
                                                    ),
                                                contentAlignment = Alignment.Center
                                            ) {
                                                Text(
                                                    option.key,
                                                    fontSize = 12.sp,
                                                    fontWeight = FontWeight.SemiBold,
                                                    color = if (showCorrect || isSel) Color.White else Tokens.TextSecondary
                                                )
                                            }
                                            Spacer(Modifier.width(10.dp))
                                            HtmlText(option.text ?: option.content, fontSizeSp = 15)
                                        }
                                    }
                                } else if (type == "FILL") {
                                    List(blanks) { i ->
                                        OutlinedTextField(
                                            value = fillInputs.getOrElse(i) { "" },
                                            onValueChange = { v ->
                                                val next = fillInputs.toMutableList()
                                                while (next.size <= i) next.add("")
                                                next[i] = v
                                                fillInputs = next
                                            },
                                            label = { Text("第 ${i + 1} 空") },
                                            singleLine = true,
                                            enabled = verdict == null,
                                            modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp),
                                            shape = RoundedCornerShape(12.dp),
                                            colors = OutlinedTextFieldDefaults.colors(
                                                focusedBorderColor = Tokens.Primary,
                                                unfocusedBorderColor = Tokens.Border
                                            )
                                        )
                                    }
                                } else {
                                    OutlinedTextField(
                                        value = essayText,
                                        onValueChange = { essayText = it },
                                        placeholder = { Text("请输入作答内容") },
                                        minLines = 6,
                                        enabled = verdict == null,
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(12.dp),
                                        colors = OutlinedTextFieldDefaults.colors(
                                            focusedBorderColor = Tokens.Primary,
                                            unfocusedBorderColor = Tokens.Border
                                        )
                                    )
                                }

                                verdict?.let { v ->
                                    Spacer(Modifier.height(14.dp))
                                    Box(
                                        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp))
                                            .background(if (v.correct == true) Tokens.SuccessSoft else Tokens.DangerSoft)
                                            .padding(14.dp)
                                    ) {
                                        Column {
                                            Text(
                                                if (v.correct == true) "回答正确" else "回答错误",
                                                fontSize = 15.sp,
                                                fontWeight = FontWeight.SemiBold,
                                                color = if (v.correct == true) Tokens.Success else Tokens.Danger
                                            )
                                            val answerText = v.expectedText ?: v.expected.joinToString(" / ")
                                            if (v.correct != true && answerText.isNotBlank()) {
                                                Spacer(Modifier.height(6.dp))
                                                Text("正确答案：$answerText", fontSize = 13.sp, color = Tokens.Success)
                                            }
                                            if (!v.analysis.isNullOrBlank()) {
                                                Spacer(Modifier.height(10.dp))
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
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            SecondaryButton(
                                "上一题",
                                onClick = { if (index > 0) { index--; selected = emptyList(); fillInputs = List(blanks) { "" }; verdict = null } },
                                enabled = index > 0 && verdict == null
                            )
                            Box(Modifier.weight(1f)) {
                                if (verdict == null) {
                                    PrimaryButton(
                                        if (submitting) "提交中…" else "提交本题",
                                        onClick = ::submitCurrent,
                                        enabled = !submitting
                                    )
                                } else {
                                    PrimaryButton(
                                        if (index < questions.size - 1) "下一题" else "完成练习",
                                        onClick = { if (index < questions.size - 1) next() else { showDone = true } }
                                    )
                                }
                            }
                        }
                    }
                }

                if (showDone) {
                    AlertDialog(
                        onDismissRequest = { showDone = false },
                        title = { Text("练习完成") },
                        text = {
                            Column {
                                Text("已完成 $answeredCount/${rec.questionCount ?: questions.size} 题")
                                Spacer(Modifier.height(4.dp))
                                Text("正确 $correctCount 题 · 错误 $wrongCount 题", fontSize = 13.sp, color = Tokens.TextSecondary)
                            }
                        },
                        confirmButton = { TextButton(onClick = { showDone = false; finishAndExit() }) { Text("结束并退出") } },
                        dismissButton = { TextButton(onClick = { showDone = false }) { Text("留在当前") } }
                    )
                }
            }
        }
    }
}

@Composable
fun WrongScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var source by remember { mutableStateOf("") }
    var reviewOnly by remember { mutableStateOf(false) }
    val expanded = remember { mutableStateMapOf<String, Boolean>() }
    val controller = rememberRemote("wrong-$source-$reviewOnly") {
        repository.wrongQuestions(
            sourceType = source.takeIf { it.isNotBlank() },
            includeMastered = if (reviewOnly) false else null
        )
    }

    PageScaffold(title = "我的错题集", onBack = { nav.back() }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                listOf("" to "全部", "EXAM" to "考试", "PRACTICE" to "练习").forEach { (value, label) ->
                    FilterChip(
                        selected = source == value,
                        onClick = { source = value },
                        label = { Text(label, fontSize = 12.sp) }
                    )
                }
                Spacer(Modifier.weight(1f))
                SmallAction(if (reviewOnly) "看全部" else "只看待复习", onClick = { reviewOnly = !reviewOnly })
            }
            AsyncContent(
                controller.state,
                onRetry = { controller.reload() },
                emptyCheck = { it.isEmpty() },
                emptyText = "太棒了，暂无错题"
            ) { list ->
                Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 4.dp)) {
                    list.forEach { wrong ->
                        WrongCard(
                            wrong = wrong,
                            expanded = expanded[wrong.id] == true,
                            onToggle = { expanded[wrong.id] = !(expanded[wrong.id] ?: false) },
                            onToggleMaster = {
                                scope.launch {
                                    runCatching {
                                        if (wrong.mastered) repository.unmasterWrong(wrong.id) else repository.masterWrong(wrong.id)
                                    }.onSuccess {
                                        context.toast(if (wrong.mastered) "已标记待复习" else "已标记掌握")
                                        controller.reload()
                                    }.onFailure { context.toast(it.userMessage()) }
                                }
                            }
                        )
                    }
                    Spacer(Modifier.height(20.dp))
                }
            }
        }
    }
}

@Composable
private fun WrongCard(wrong: WrongQuestion, expanded: Boolean, onToggle: () -> Unit, onToggleMaster: () -> Unit) {
    val type = wrong.typeCode ?: wrong.questionType
    SectionCard(Modifier.padding(vertical = 6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TagPill(type?.let { Formatters.questionTypeLabel(it) } ?: "题目", Tokens.Primary, Tokens.PrimarySoft)
            Spacer(Modifier.width(6.dp))
            TagPill("错 ${wrong.wrongCount} 次", Tokens.Danger, Tokens.DangerSoft)
            Spacer(Modifier.weight(1f))
            TagPill(
                if (wrong.mastered) "已掌握" else "待复习",
                if (wrong.mastered) Tokens.Success else Tokens.Warning,
                if (wrong.mastered) Tokens.SuccessSoft else Tokens.WarningSoft
            )
        }
        Spacer(Modifier.height(9.dp))
        Row(
            Modifier.fillMaxWidth().clickable(onClick = onToggle),
            verticalAlignment = Alignment.Top
        ) {
            Column(Modifier.weight(1f)) {
                if (wrong.stem.isNullOrBlank()) {
                    Text("题目内容", fontSize = 15.sp)
                } else {
                    HtmlText(wrong.stem, fontSizeSp = 15)
                }
            }
            Icon(
                if (expanded) Icons.Filled.KeyboardArrowDown else Icons.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = Tokens.TextTertiary
            )
        }
        if (!wrong.lastWrongAt.isNullOrBlank()) {
            Spacer(Modifier.height(5.dp))
            Text(wrong.lastWrongAt, fontSize = 11.sp, color = Tokens.TextTertiary)
        }
        if (expanded) {
            if (wrong.options.isNotEmpty()) {
                Spacer(Modifier.height(10.dp))
                wrong.options.forEach { option ->
                    Row(
                        Modifier.fillMaxWidth().padding(vertical = 3.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (option.correct) Tokens.SuccessSoft else Tokens.SurfaceAlt.copy(alpha = 0.5f))
                            .padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            Modifier.size(24.dp).clip(RoundedCornerShape(12.dp))
                                .background(if (option.correct) Tokens.Success else Tokens.Surface),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(option.key, fontSize = 11.sp, color = if (option.correct) Color.White else Tokens.TextSecondary)
                        }
                        Spacer(Modifier.width(9.dp))
                        Box(Modifier.weight(1f)) {
                            HtmlText(option.text.ifBlank { option.content ?: "" }, fontSizeSp = 14)
                        }
                        if (option.correct) {
                            Text("正确答案", fontSize = 11.sp, color = Tokens.Success)
                        }
                    }
                }
            }
            Spacer(Modifier.height(10.dp))
            val answer = wrong.answerText ?: wrong.expectedText
            if (!answer.isNullOrBlank()) {
                Text("答案：$answer", fontSize = 13.sp, color = Tokens.TextPrimary)
            }
            if (!wrong.analysis.isNullOrBlank()) {
                Spacer(Modifier.height(8.dp))
                Box(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                        .background(Tokens.SurfaceAlt.copy(alpha = 0.6f)).padding(12.dp)
                ) {
                    Column {
                        Text("解析", fontSize = 11.sp, color = Tokens.TextSecondary)
                        Spacer(Modifier.height(4.dp))
                        RichContentView(wrong.analysis ?: "", fontSizeSp = 13)
                    }
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        SmallAction(
            if (wrong.mastered) "标记待复习" else "我已掌握",
            onClick = onToggleMaster,
            color = if (wrong.mastered) Tokens.TextSecondary else Tokens.Success
        )
    }
}
