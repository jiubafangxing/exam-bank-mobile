package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
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
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.example.exammobile.core.config.AppConfig
import com.example.exammobile.core.model.AppJson
import com.example.exammobile.core.model.ExamSummary
import com.example.exammobile.core.model.OpenExamSummary
import com.example.exammobile.core.model.Question
import com.example.exammobile.core.model.ReviewView
import com.example.exammobile.core.model.SubmitResult
import com.example.exammobile.core.util.Formatters
import com.example.exammobile.core.util.UiState
import com.example.exammobile.data.CandidateRepository
import com.example.exammobile.ui.components.*
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.util.rememberRemote
import com.example.exammobile.ui.util.toast
import com.example.exammobile.ui.util.userMessage
import com.example.exammobile.ui.viewmodel.ExamEvent
import com.example.exammobile.ui.viewmodel.ExamTakingViewModel
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.util.Calendar

@Composable
fun ExamListScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var keyword by remember { mutableStateOf("") }
    var paidFilter by remember { mutableStateOf("") }
    var sort by remember { mutableStateOf("startTime") }
    var reload by remember { mutableIntStateOf(0) }
    var passwordDialog by remember { mutableStateOf(false) }
    var passwordValue by remember { mutableStateOf("") }
    var pendingExam by remember { mutableStateOf<ExamSummary?>(null) }
    var pendingResult by remember { mutableStateOf(false) }

    val examsController = rememberRemote("exams-$keyword-$paidFilter-$sort-$reload") {
        repository.exams(buildMap {
            keyword.trim().takeIf { it.isNotBlank() }?.let { put("keyword", it) }
            if (paidFilter.isNotEmpty()) put("paid", paidFilter)
            if (sort.isNotEmpty()) put("sort", sort)
        })
    }
    val openController = rememberRemote("open-$reload") { repository.openExams() }

    fun openRegistration() {
        val base = AppConfig.registrationUrl.trimEnd('/')
        if (base.isBlank()) {
            context.toast("报名入口未配置")
            return
        }
        runCatching {
            context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse("$base/campaigns")))
        }
    }

    fun launchExam(exam: ExamSummary, result: Boolean = false, password: String? = null) {
        scope.launch {
            runCatching { repository.startExam(exam.id, password) }
                .onSuccess { state ->
                    if (result || state.status in listOf("SUBMITTED", "GRADED")) {
                        nav.result(state.attemptId)
                    } else {
                        nav.examTaking(exam.id)
                    }
                }
                .onFailure { e ->
                    val message = e.userMessage()
                    if (password == null && message.contains("密码")) {
                        pendingExam = exam
                        pendingResult = result
                        passwordValue = ""
                        passwordDialog = true
                    } else {
                        context.toast(message)
                    }
                }
        }
    }

    fun startOpen(exam: OpenExamSummary) {
        when {
            exam.eligibility == "NEED_PAYMENT" -> scope.launch {
                runCatching { repository.payOpenExam(exam.id) }
                    .onSuccess {
                        context.toast("缴费成功")
                        reload += 1
                        val assigned = ExamSummary(id = exam.id, name = exam.name)
                        launchExam(assigned)
                    }
                    .onFailure { context.toast(it.userMessage()) }
            }
            exam.eligibility == "READY_TO_START" -> launchExam(
                ExamSummary(id = exam.id, name = exam.name)
            )
            exam.accessMode == "REGISTER" || exam.accessMode == "APPROVAL" -> openRegistration()
            else -> context.toast(openConditionText(exam))
        }
    }

    PageScaffold(title = "我的考试") { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = PagePadding, vertical = 10.dp)
        ) {
            GradientHero {
                Text(
                    "${Formatters.greeting(Calendar.getInstance().get(Calendar.HOUR_OF_DAY))}，同学",
                    fontSize = 21.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Spacer(Modifier.height(6.dp))
                Text(
                    "欢迎回来，请按考试时间参加；支持断线续考，作答会自动保存。",
                    fontSize = 13.sp,
                    color = Color.White.copy(alpha = 0.88f),
                    lineHeight = 20.sp
                )
            }

            SectionCard(Modifier.padding(top = 12.dp)) {
                OutlinedTextField(
                    value = keyword,
                    onValueChange = { keyword = it },
                    placeholder = { Text("搜索考试名称", fontSize = 13.sp) },
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null, tint = Tokens.TextTertiary) },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Tokens.Primary,
                        unfocusedBorderColor = Tokens.Border,
                        focusedContainerColor = Tokens.Surface,
                        unfocusedContainerColor = Tokens.SurfaceAlt.copy(alpha = 0.5f)
                    )
                )
                Spacer(Modifier.height(10.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.horizontalScroll(rememberScrollState())
                ) {
                    listOf("" to "全部", "false" to "免费", "true" to "付费").forEach { (value, label) ->
                        FilterChip(
                            selected = paidFilter == value,
                            onClick = { paidFilter = value },
                            label = { Text(label, fontSize = 12.sp) }
                        )
                    }
                    listOf("startTime" to "最新", "name" to "名称", "priceAsc" to "价格↑", "priceDesc" to "价格↓").forEach { (value, label) ->
                        FilterChip(
                            selected = sort == value,
                            onClick = { sort = value },
                            label = { Text(label, fontSize = 12.sp) }
                        )
                    }
                }
            }

            SectionHeader(title = "我的考试")
            AsyncContent(
                state = examsController.state,
                onRetry = { examsController.reload() },
                emptyCheck = { it.isEmpty() },
                emptyText = "暂无考试"
            ) { list ->
                list.forEach { exam ->
                    ExamCard(exam, onStart = { launchExam(exam) }, onResult = { launchExam(exam, result = true) })
                }
            }

            val openExams = (openController.state as? UiState.Success)?.data.orEmpty()
            val assignedIds = ((examsController.state as? UiState.Success)?.data.orEmpty()).map { it.id }.toSet()
            val openVisible = openExams.filter { it.id !in assignedIds }
            if (openVisible.isNotEmpty() || openController.state is UiState.Loading) {
                SectionHeader(title = "开放考试", actionLabel = "刷新") { openController.reload() }
                AsyncContent(
                    state = openController.state,
                    onRetry = { openController.reload() },
                    emptyCheck = { true },
                    emptyText = ""
                ) { all ->
                    all.filter { it.id !in assignedIds }.forEach { exam ->
                        OpenExamCard(exam) { startOpen(exam) }
                    }
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }

    if (passwordDialog && pendingExam != null) {
        AlertDialog(
            onDismissRequest = { passwordDialog = false },
            title = { Text("请输入考试密码") },
            text = {
                OutlinedTextField(
                    value = passwordValue,
                    onValueChange = { passwordValue = it },
                    placeholder = { Text("考试密码") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    val exam = pendingExam
                    val asResult = pendingResult
                    passwordDialog = false
                    if (exam != null && passwordValue.isNotBlank()) {
                        launchExam(exam, asResult, passwordValue.trim())
                    } else {
                        context.toast("请输入考试密码")
                    }
                }) { Text("进入考试") }
            },
            dismissButton = { TextButton(onClick = { passwordDialog = false }) { Text("取消") } }
        )
    }
}

private fun examTag(status: String): Triple<String, Color, Color> = when (status) {
    "IN_PROGRESS", "STARTED" -> Triple("作答中", Tokens.Primary, Tokens.PrimarySoft)
    "GRADED" -> Triple("已出分", Tokens.Success, Tokens.SuccessSoft)
    "SUBMITTED", "GRADING" -> Triple("已交卷", Tokens.Warning, Tokens.WarningSoft)
    "ABSENT" -> Triple("缺考", Tokens.Danger, Tokens.DangerSoft)
    "EXPIRED" -> Triple("已过期", Tokens.TextSecondary, Tokens.SurfaceAlt)
    else -> Triple(Formatters.attemptStatusLabel(status), Tokens.TextSecondary, Tokens.SurfaceAlt)
}

private fun canStartExam(status: String): Boolean =
    status !in listOf("SUBMITTED", "GRADED", "REGISTERED", "REJECTED", "CANCELLED")

@Composable
private fun ExamCard(exam: ExamSummary, onStart: () -> Unit, onResult: () -> Unit) {
    val (tagText, tagFg, tagBg) = examTag(exam.attemptStatus)
    SectionCard(Modifier.padding(vertical = 6.dp)) {
        Column {
            if (!exam.coverUrl.isNullOrBlank()) {
                coil.compose.AsyncImage(
                    model = exam.coverUrl,
                    contentDescription = null,
                    modifier = Modifier.fillMaxWidth().height(132.dp).clip(RoundedCornerShape(16.dp)),
                    contentScale = androidx.compose.ui.layout.ContentScale.Crop
                )
                Spacer(Modifier.height(12.dp))
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    exam.name,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Tokens.TextPrimary,
                    modifier = Modifier.weight(1f),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(Modifier.width(8.dp))
                TagPill(tagText, tagFg, tagBg)
            }
            if (!exam.paperName.isNullOrBlank() || exam.displayPrice != null) {
                Spacer(Modifier.height(5.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(exam.paperName ?: "未命名试卷", fontSize = 13.sp, color = Tokens.TextSecondary)
                    exam.displayPrice?.let {
                        Text(" · ¥${Formatters.scoreText(it)}", fontSize = 13.sp, color = Tokens.Danger, fontWeight = FontWeight.Medium)
                    }
                }
            }
            if (!exam.intro.isNullOrBlank()) {
                Spacer(Modifier.height(6.dp))
                Text(exam.intro, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 2, overflow = TextOverflow.Ellipsis)
            }
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp), modifier = Modifier.fillMaxWidth()) {
                MiniMeta("开始", Formatters.epochToDateTime(exam.startEpochMillis))
                MiniMeta("时长", Formatters.durationText(exam.durationSeconds))
                exam.totalScore?.let { MiniMeta("总分", Formatters.scoreText(it)) }
                exam.score?.let { MiniMeta("得分", Formatters.scoreText(it), Tokens.Primary) }
            }
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                if (canStartExam(exam.attemptStatus)) {
                    GradientMiniButton("开始/继续作答", onClick = onStart)
                }
                if (exam.attemptStatus in listOf("SUBMITTED", "GRADED")) {
                    OutlineMiniButton("查看成绩", onClick = onResult)
                }
            }
        }
    }
}

@Composable
private fun MiniMeta(label: String, value: String, valueColor: Color = Tokens.TextSecondary) {
    Column {
        Text(label, fontSize = 10.sp, color = Tokens.TextTertiary)
        Text(value, fontSize = 12.sp, color = valueColor, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun GradientMiniButton(text: String, onClick: () -> Unit) {
    Box(
        Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(Tokens.PrimaryGradient)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 9.dp)
    ) {
        Text(text, color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun OutlineMiniButton(text: String, onClick: () -> Unit) {
    Box(
        Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(Tokens.PrimarySoft)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 9.dp)
    ) {
        Text(text, color = Tokens.Primary, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    }
}

private fun accessModeText(mode: String?): String = when (mode) {
    "PAID" -> "付费考试"
    "PASSWORD" -> "密码考试"
    "VIP" -> "VIP 考试"
    "POINTS" -> "积分考试"
    "QRCODE" -> "扫码考试"
    "ORG_POSITION" -> "部门考试"
    "REGISTER" -> "报名考试"
    "APPROVAL" -> "申报审核"
    "CLASS" -> "班级考试"
    "FIXED" -> "固定人群"
    else -> mode ?: "开放考试"
}

private fun openConditionText(exam: OpenExamSummary): String = when (exam.accessMode) {
    "REGISTER" -> "请先报名"
    "APPROVAL" -> "报名审核中"
    else -> accessModeText(exam.accessMode)
}

@Composable
private fun OpenExamCard(exam: OpenExamSummary, onAction: () -> Unit) {
    val (label, fg, bg) = when (exam.eligibility) {
        "READY_TO_START" -> Triple("可开始", Tokens.Success, Tokens.SuccessSoft)
        "NEED_PAYMENT" -> Triple("待缴费", Tokens.Warning, Tokens.WarningSoft)
        else -> Triple("需条件", Tokens.TextSecondary, Tokens.SurfaceAlt)
    }
    SectionCard(Modifier.padding(vertical = 6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(exam.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(accessModeText(exam.accessMode), fontSize = 12.sp, color = Tokens.TextSecondary)
                    exam.price?.takeIf { it > 0 }?.let {
                        Text(" / ¥${Formatters.scoreText(it)}", fontSize = 12.sp, color = Tokens.Danger, fontWeight = FontWeight.Medium)
                    }
                }
                Spacer(Modifier.height(6.dp))
                Text(
                    "${Formatters.epochToDateTime(exam.startEpochMillis)} · ${Formatters.durationText(exam.durationSeconds)}",
                    fontSize = 12.sp,
                    color = Tokens.TextSecondary
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                TagPill(label, fg, bg)
                Spacer(Modifier.height(8.dp))
                when {
                    exam.eligibility == "NEED_PAYMENT" -> GradientMiniButton("缴费进入", onAction)
                    exam.eligibility == "READY_TO_START" -> GradientMiniButton("开始作答", onAction)
                    exam.accessMode == "REGISTER" || exam.accessMode == "APPROVAL" -> OutlineMiniButton("去报名", onAction)
                    else -> Text(openConditionText(exam), fontSize = 12.sp, color = Tokens.TextTertiary)
                }
            }
        }
    }
}

// ============================ 作答页 ============================

@Composable
fun ExamTakingScreen(repository: CandidateRepository, examId: String, nav: AppNav) {
    val context = LocalContext.current
    val vm: ExamTakingViewModel = viewModel(
        key = "taking-$examId",
        factory = viewModelFactory { initializer { ExamTakingViewModel(repository, examId) } }
    )
    val state by vm.state.collectAsState()
    val currentIndex by vm.currentIndex.collectAsState()
    val remaining by vm.remainingSeconds.collectAsState()
    val answers by vm.answers.collectAsState()
    val fills by vm.fillValues.collectAsState()
    val saveStatus by vm.saveStatus.collectAsState()
    val submitting by vm.submitting.collectAsState()
    var showSheet by remember { mutableStateOf(false) }
    var showSubmit by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { vm.load() }

    LaunchedEffect(Unit) {
        vm.uiEvents.collect { e ->
            when (e) {
                is ExamEvent.Toast -> context.toast(e.message)
                ExamEvent.ConfirmSubmit -> showSubmit = true
                is ExamEvent.Submitted -> {
                    context.toast(if (e.auto) "时间到，已自动交卷" else "交卷成功")
                    nav.result(e.attemptId)
                }
                is ExamEvent.NavigateResult -> nav.result(e.attemptId)
            }
        }
    }

    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_STOP -> vm.reportEvent("APP_SWITCH", "onStop")
                Lifecycle.Event.ON_START -> vm.reportEvent("FOCUS", "onStart")
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    when (val s = state) {
        is UiState.Loading -> PageScaffold(title = "正在加载…", onBack = { nav.back() }) { LoadingState(Modifier.padding(it)) }
        is UiState.Error -> PageScaffold(title = "在线作答", onBack = { nav.back() }) { padding ->
            Column(Modifier.padding(padding).padding(16.dp)) {
                ErrorBanner(s.message)
                Spacer(Modifier.height(12.dp))
                SecondaryButton("重试", onClick = { vm.load() })
            }
        }
        is UiState.Success -> {
            val attempt = s.data
            val questions = attempt.questions
            val current = questions.getOrNull(currentIndex)
            val answeredCount = questions.count { vm.isAnswered(it) }

            PageScaffold(
                title = attempt.examName.ifBlank { "在线作答" },
                onBack = { nav.back(); context.toast("已自动保存，可稍后断线续考") },
                actions = { CountdownTimer(remaining, Modifier.padding(end = 16.dp)) }
            ) { padding ->
                Column(Modifier.padding(padding).fillMaxSize()) {
                    Row(
                        Modifier.fillMaxWidth().background(Tokens.PrimarySoft).padding(horizontal = 16.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("第 ${currentIndex + 1} / ${questions.size} 题", fontSize = 12.sp, color = Tokens.TextSecondary)
                        Text("已答 $answeredCount · 已保存 ${saveStatus.count { it.value == "saved" }}", fontSize = 12.sp, color = Tokens.TextSecondary)
                        Text("${Formatters.scoreText(current?.score)} 分", fontSize = 12.sp, color = Tokens.TextSecondary)
                    }

                    if (current != null) {
                        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(16.dp)) {
                            QuestionCard(vm, current, fills, saveStatus)
                        }
                    }

                    Row(
                        Modifier.fillMaxWidth().background(Tokens.Surface).padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        SecondaryButton("上一题", onClick = { vm.jumpTo(currentIndex - 1) }, enabled = currentIndex > 0)
                        SecondaryButton("答题卡", onClick = { showSheet = true })
                        if (currentIndex < questions.size - 1) {
                            Button(
                                onClick = { vm.jumpTo(currentIndex + 1) },
                                shape = RoundedCornerShape(999.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = Tokens.Primary)
                            ) { Text("下一题") }
                        } else {
                            Button(
                                onClick = { vm.askSubmit() },
                                enabled = !submitting,
                                shape = RoundedCornerShape(999.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = Tokens.Success)
                            ) { Text("交卷") }
                        }
                    }
                }
            }

            if (showSheet) {
                AnswerSheetDialog(
                    questions = questions,
                    currentIndex = currentIndex,
                    answered = { vm.isAnswered(it) },
                    flagged = { (answers[it.paperQuestionId]?.flagged == true) },
                    onJump = { vm.jumpTo(it); showSheet = false },
                    onSubmit = { showSheet = false; vm.askSubmit() },
                    onDismiss = { showSheet = false }
                )
            }
            if (showSubmit) {
                AlertDialog(
                    onDismissRequest = { showSubmit = false },
                    title = { Text("交卷确认") },
                    text = { Text("交卷后不可再修改答案，确认交卷？") },
                    confirmButton = { TextButton(onClick = { showSubmit = false; vm.submit(false) }) { Text("确认交卷") } },
                    dismissButton = { TextButton(onClick = { showSubmit = false }) { Text("再检查一下") } }
                )
            }
        }
        else -> Unit
    }
}

@Composable
private fun QuestionCard(
    vm: ExamTakingViewModel,
    question: Question,
    fills: Map<String, List<String>>,
    saveStatus: Map<String, String>
) {
    val type = question.type.ifBlank { question.typeCode ?: "" }
    val (fg, bg) = Tokens.typeColor(type)
    SectionCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("第 ${question.sortNo} 题", fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.width(8.dp))
            TagPill(Formatters.questionTypeLabel(type), fg, bg)
            Spacer(Modifier.weight(1f))
            val status = saveStatus[question.paperQuestionId] ?: "pending"
            val statusText = when (status) {
                "saving" -> "保存中"; "saved" -> "已保存"; "error" -> "保存失败"; else -> "待保存"
            }
            val statusColor = when (status) {
                "saved" -> Tokens.Success; "error" -> Tokens.Danger; else -> Tokens.TextTertiary
            }
            Text(statusText, fontSize = 11.sp, color = statusColor)
            Spacer(Modifier.width(8.dp))
            Text(
                "标记",
                fontSize = 12.sp,
                color = if (vm.answerOf(question).flagged) Tokens.Warning else Tokens.TextSecondary,
                modifier = Modifier.clickable { vm.toggleFlag(question) }
            )
        }
        Spacer(Modifier.height(14.dp))
        RichContentView(question.stem, fontSizeSp = 16)
        Spacer(Modifier.height(16.dp))

        when (question.type) {
            "FILL" -> {
                val values = fills[question.paperQuestionId] ?: List(question.blanks.coerceAtLeast(1)) { "" }
                values.forEachIndexed { index, value ->
                    OutlinedTextField(
                        value = value,
                        onValueChange = { vm.updateFill(question, index, it) },
                        label = { Text("第 ${index + 1} 空") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp),
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = Tokens.Primary, unfocusedBorderColor = Tokens.Border)
                    )
                }
            }
            "ESSAY" -> {
                OutlinedTextField(
                    value = vm.answerOf(question).answerText,
                    onValueChange = { vm.updateEssay(question, it) },
                    placeholder = { Text("请输入作答内容") },
                    minLines = 6,
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = Tokens.Primary, unfocusedBorderColor = Tokens.Border)
                )
            }
            else -> {
                question.options.forEach { option ->
                    val selected = vm.isSelected(question, option.key)
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(vertical = 5.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (selected) Tokens.PrimarySoft else Tokens.Surface)
                            .clickable { vm.choose(question, option.key) }
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            Modifier.size(24.dp).clip(RoundedCornerShape(12.dp))
                                .background(if (selected) Tokens.Primary else Tokens.SurfaceAlt),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(option.key, fontSize = 12.sp, color = if (selected) Color.White else Tokens.TextPrimary)
                        }
                        Spacer(Modifier.width(10.dp))
                        HtmlText(option.text ?: option.content, fontSizeSp = 15)
                    }
                }
            }
        }
    }
}

@Composable
private fun AnswerSheetDialog(
    questions: List<Question>,
    currentIndex: Int,
    answered: (Question) -> Boolean,
    flagged: (Question) -> Boolean,
    onJump: (Int) -> Unit,
    onSubmit: () -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Card(colors = CardDefaults.cardColors(containerColor = Tokens.Surface)) {
            Column(Modifier.padding(16.dp)) {
                Text("答题卡", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(12.dp))
                LazyVerticalGrid(
                    columns = GridCells.Fixed(5),
                    modifier = Modifier.heightIn(max = 360.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(count = questions.size) { index ->
                        val q = questions[index]
                        val bg = if (answered(q)) Tokens.PrimarySoft else Tokens.Surface
                        val border = when {
                            index == currentIndex -> Tokens.Primary
                            flagged(q) -> Tokens.Warning
                            else -> Tokens.Border
                        }
                        Box(
                            Modifier
                                .height(42.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(bg)
                                .clickable { onJump(index) },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "${index + 1}",
                                fontSize = 14.sp,
                                color = if (index == currentIndex) Tokens.Primary else Tokens.TextPrimary,
                                fontWeight = if (index == currentIndex) FontWeight.Bold else FontWeight.Normal
                            )
                        }
                    }
                }
                Spacer(Modifier.height(12.dp))
                PrimaryButton("交卷", onClick = onSubmit)
            }
        }
    }
}

// ============================ 成绩页 ============================

@Composable
fun ResultScreen(repository: CandidateRepository, attemptId: String, nav: AppNav) {
    val controller = rememberRemote(attemptId) { repository.result(attemptId) }
    PageScaffold(title = "成绩", onBack = { nav.home() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }) { result: SubmitResult ->
            Column(
                Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)
            ) {
                val total = (result.objectiveTotal + result.subjectiveTotal).coerceAtLeast(0.0)
                val fraction = if (total <= 0) 0f else (result.totalScore / total).toFloat().coerceIn(0f, 1f)
                SectionCard {
                    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                        Spacer(Modifier.height(6.dp))
                        Box(contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(
                                progress = { fraction },
                                modifier = Modifier.size(150.dp),
                                color = Tokens.Primary,
                                trackColor = Tokens.PrimarySoft,
                                strokeWidth = 11.dp
                            )
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(Formatters.scoreText(result.totalScore), fontSize = 44.sp, fontWeight = FontWeight.Bold, color = Tokens.PrimaryDark)
                                Text("总分", fontSize = 12.sp, color = Tokens.TextSecondary)
                            }
                        }
                        Spacer(Modifier.height(12.dp))
                        when (result.isPassed) {
                            true -> TagPill("考试通过", Tokens.Success, Tokens.SuccessSoft)
                            false -> TagPill("未通过", Tokens.Danger, Tokens.DangerSoft)
                            null -> TagPill("主观题阅卷中", Tokens.Warning, Tokens.WarningSoft)
                        }
                        Spacer(Modifier.height(6.dp))
                        Text("满分 ${Formatters.scoreText(total)}", fontSize = 12.sp, color = Tokens.TextTertiary)
                        Spacer(Modifier.height(14.dp))
                    }
                    DividerLine()
                    Spacer(Modifier.height(10.dp))
                    KeyValueRow("客观题", "${Formatters.scoreText(result.objectiveScore)} / ${Formatters.scoreText(result.objectiveTotal)}")
                    KeyValueRow("主观题", "${Formatters.scoreText(result.subjectiveScore)} / ${Formatters.scoreText(result.subjectiveTotal)}")
                    KeyValueRow("答对", "${result.correctCount} 题")
                    KeyValueRow("答错", "${result.wrongCount} 题")
                    KeyValueRow("待阅", "${result.pendingCount} 题")
                    KeyValueRow("交卷方式", if (result.auto) "超时自动交卷" else "手动交卷")
                    result.submittedAt?.let { KeyValueRow("交卷时间", it) }
                }
                Spacer(Modifier.height(16.dp))
                PrimaryButton("查看解析", onClick = { nav.review(attemptId) })
                Spacer(Modifier.height(10.dp))
                SecondaryButton("返回首页", onClick = { nav.home() }, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}

// ============================ 解析页 ============================

@Composable
fun ReviewScreen(repository: CandidateRepository, attemptId: String, nav: AppNav) {
    val controller = rememberRemote(attemptId) { repository.review(attemptId) }
    PageScaffold(title = "答题详情", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }) { review: ReviewView ->
            if (!review.allowed) {
                Column(Modifier.padding(padding).padding(16.dp)) {
                    ErrorBanner(policyText(review.policy))
                }
                return@AsyncContent
            }
            Column(
                Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)
            ) {
                SectionCard {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("共 ${review.questions.size} 题", fontSize = 13.sp, color = Tokens.TextSecondary)
                        Text("得分 ${Formatters.scoreText(review.score?.totalScore)}", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Tokens.Primary)
                    }
                }
                Spacer(Modifier.height(12.dp))
                review.questions.forEachIndexed { index, item ->
                    SectionCard(Modifier.padding(bottom = 10.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("第 ${index + 1} 题", fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            Spacer(Modifier.width(8.dp))
                            when (item.correct) {
                                true -> TagPill("正确", Tokens.Success, Tokens.SuccessSoft)
                                false -> TagPill("错误", Tokens.Danger, Tokens.DangerSoft)
                                null -> TagPill("待阅卷", Tokens.Warning, Tokens.WarningSoft)
                            }
                            Spacer(Modifier.weight(1f))
                            Text("${Formatters.scoreText(item.score)} 分", fontSize = 12.sp, color = Tokens.TextSecondary)
                        }
                        Spacer(Modifier.height(10.dp))
                        RichContentView(item.stem, fontSizeSp = 15)
                        if (item.options.isNotEmpty()) {
                            Spacer(Modifier.height(8.dp))
                            item.options.forEach { option ->
                                Row(Modifier.padding(vertical = 2.dp)) {
                                    Text(option.key, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = Tokens.Primary)
                                    Spacer(Modifier.width(8.dp))
                                    HtmlText(option.text ?: option.content, fontSizeSp = 14)
                                }
                            }
                        }
                        DividerLine()
                        Spacer(Modifier.height(8.dp))
                        KeyValueRow("我的答案", formatAnswer(item.myAnswerJson))
                        if (item.expected.isNotEmpty()) {
                            KeyValueRow("正确答案", item.expected.joinToString(" / "))
                        }
                        if (!item.analysis.isNullOrBlank()) {
                            Spacer(Modifier.height(8.dp))
                            Box(
                                Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
                                    .background(Tokens.SurfaceAlt).padding(10.dp)
                            ) {
                                Column {
                                    Text("解析", fontSize = 12.sp, color = Tokens.TextSecondary)
                                    Spacer(Modifier.height(4.dp))
                                    RichContentView(item.analysis, fontSizeSp = 13)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun policyText(policy: String?): String = when (policy) {
    "NEVER" -> "本场考试不展示答题详情"
    "AFTER_PUBLISH" -> "成绩发布后可查看答题详情"
    "AFTER_END" -> "考试结束后可查看答题详情"
    else -> "暂不可查看答题详情"
}

private fun formatAnswer(value: String?): String {
    if (value.isNullOrBlank()) return "未作答"
    return runCatching {
        val element = AppJson.parseToJsonElement(value)
        when (element) {
            is JsonArray -> element.joinToString(" / ") { it.toString().trim('"') }
            else -> element.toString()
        }
    }.getOrDefault(value)
}
