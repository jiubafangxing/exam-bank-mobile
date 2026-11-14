package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import com.example.exammobile.core.model.*
import com.example.exammobile.core.util.Formatters
import com.example.exammobile.core.util.UiState
import com.example.exammobile.data.CandidateRepository
import com.example.exammobile.ui.components.*
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.util.flattenJsonView
import com.example.exammobile.ui.util.rememberRemote
import com.example.exammobile.ui.util.toast
import com.example.exammobile.ui.util.userMessage
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.util.UUID

@Composable
fun ScoreScreen(repository: CandidateRepository, nav: AppNav) {
    var records by remember { mutableStateOf<List<ScoreRecord>>(emptyList()) }
    var page by remember { mutableIntStateOf(1) }
    var total by remember { mutableLongStateOf(0L) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(page) {
        loading = true
        try {
            val res = repository.scores(page, 20)
            records = if (page == 1) res.records else records + res.records
            total = res.total
            error = null
        } catch (e: Exception) {
            error = e.userMessage()
        } finally {
            loading = false
        }
    }

    PageScaffold(title = "我的成绩", onBack = { nav.back() }) { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)
        ) {
            if (loading && records.isEmpty()) {
                LoadingState()
            } else if (error != null && records.isEmpty()) {
                ErrorBanner(error!!)
            } else if (records.isEmpty()) {
                EmptyState("暂无成绩记录")
            } else {
                records.forEach { score ->
                    SectionCard(Modifier.padding(bottom = 10.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(score.examName ?: "考试", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            Text(Formatters.scoreText(score.totalScore), fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Tokens.Primary)
                        }
                        Spacer(Modifier.height(6.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("客观题 ${Formatters.scoreText(score.objectiveScore)}", fontSize = 12.sp, color = Tokens.TextSecondary)
                            Spacer(Modifier.width(16.dp))
                            Text("主观题 ${Formatters.scoreText(score.subjectiveScore)}", fontSize = 12.sp, color = Tokens.TextSecondary)
                            Spacer(Modifier.weight(1f))
                            if (score.status == "PUBLISHED") {
                                TagPill("已发布", Tokens.Success, Tokens.SuccessSoft)
                            } else {
                                TagPill("待发布", Tokens.Warning, Tokens.WarningSoft)
                            }
                        }
                        if (!score.publishedAt.isNullOrBlank()) {
                            Spacer(Modifier.height(6.dp))
                            Text("发布时间：${score.publishedAt}", fontSize = 11.sp, color = Tokens.TextTertiary)
                        }
                    }
                }
                if (records.size < total) {
                    SecondaryButton(
                        "加载更多",
                        onClick = { page += 1 },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }
    }
}

@Composable
fun AnalysisScreen(repository: CandidateRepository, nav: AppNav) {
    val controller = rememberRemote("analysis") { repository.analysis() }
    PageScaffold(title = "个人分析", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }) { a: AnalysisView ->
            val weak = (a.weakPoints.ifEmpty { a.weakestTypes })
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                SectionCard {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
                        AnalysisCell("总考试", "${a.totalExams}")
                        AnalysisCell("已参加", "${a.attendedExams ?: a.totalExams}")
                        AnalysisCell("平均分", Formatters.scoreText(a.avgScore ?: a.averageScore))
                        AnalysisCell("及格率", "${(a.passRate * 100).toInt()}%")
                    }
                }
                Spacer(Modifier.height(12.dp))
                SectionCard {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceAround) {
                        AnalysisCell("最低分", Formatters.scoreText(a.lowestScore))
                        AnalysisCell("最高分", Formatters.scoreText(a.highestScore))
                    }
                    if (a.studyMinutes > 0) {
                        Spacer(Modifier.height(8.dp))
                        KeyValueRow("学习时长", "${a.studyMinutes} 分钟")
                    }
                }
                if (weak.isNotEmpty()) {
                    SectionTitle("薄弱知识点")
                    SectionCard {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            weak.forEach { point ->
                                TagPill(Formatters.questionTypeLabel(point), Tokens.Warning, Tokens.WarningSoft)
                            }
                        }
                    }
                }
                if (a.trend.isNotEmpty()) {
                    SectionTitle("成绩趋势")
                    SectionCard {
                        a.trend.forEach { point ->
                            Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text(point.label, fontSize = 13.sp, color = Tokens.TextSecondary)
                                Text(Formatters.scoreText(point.value), fontSize = 14.sp, color = Tokens.Primary, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AnalysisCell(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, fontSize = 19.sp, fontWeight = FontWeight.Bold, color = Tokens.Primary)
        Text(label, fontSize = 12.sp, color = Tokens.TextSecondary)
    }
}

@Composable
fun RankingScreen(repository: CandidateRepository, nav: AppNav) {
    var tab by remember { mutableIntStateOf(0) }
    val pointsController = rememberRemote("points") { repository.pointsRanking() }
    val classController = rememberRemote("classRank") { repository.classRanking() }
    PageScaffold(title = "排行榜", onBack = { nav.back() }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {
            TabRow(selectedTabIndex = tab, containerColor = Tokens.Surface) {
                Tab(selected = tab == 0, onClick = { tab = 0 }) { Text("积分排行", modifier = Modifier.padding(12.dp)) }
                Tab(selected = tab == 1, onClick = { tab = 1 }) { Text("班级排行", modifier = Modifier.padding(12.dp)) }
            }
            val isClass = tab == 1
            val controller = if (isClass) classController else pointsController
            AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无排行") { rows: List<RankingRow> ->
                Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                    rows.forEach { row ->
                        val title = if (isClass) (row.className ?: row.classId ?: "") else row.name.ifBlank { row.memberNo ?: row.userId ?: "" }
                        val subtitle = if (isClass) "${row.participants ?: 0} 人参考" else (row.levelCode ?: "")
                        val value = if (isClass) Formatters.scoreText(row.averageScore ?: row.score) else "${row.points ?: 0} 分"
                        SectionCard(Modifier.padding(vertical = 4.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    "${row.rank ?: 0}",
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if ((row.rank ?: 0) <= 3) Tokens.Warning else Tokens.TextSecondary,
                                    modifier = Modifier.width(36.dp)
                                )
                                Column(Modifier.weight(1f)) {
                                    Text(title, fontSize = 15.sp, fontWeight = if (row.isMe == true) FontWeight.Bold else FontWeight.Medium)
                                    if (subtitle.isNotBlank()) {
                                        Text(subtitle, fontSize = 12.sp, color = Tokens.TextSecondary)
                                    }
                                }
                                Text(value, fontSize = 15.sp, color = Tokens.Primary, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ClassScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var tab by remember { mutableIntStateOf(0) }
    var keyword by remember { mutableStateOf("") }
    var paidFilter by remember { mutableStateOf("") }
    var sort by remember { mutableStateOf("") }
    var reload by remember { mutableIntStateOf(0) }
    var passwordDialog by remember { mutableStateOf(false) }
    var passwordValue by remember { mutableStateOf("") }
    var pendingClass by remember { mutableStateOf<ClassItem?>(null) }
    var paidTarget by remember { mutableStateOf<ClassItem?>(null) }

    val controller = rememberRemote("classes-$tab-$paidFilter-$sort-$reload") {
        if (tab == 0) repository.myClasses()
        else repository.classes(buildMap {
            if (keyword.isNotBlank()) put("keyword", keyword.trim())
            if (paidFilter.isNotEmpty()) put("paid", paidFilter)
            if (sort.isNotEmpty()) put("sort", sort)
        })
    }

    fun doJoin(item: ClassItem, password: String? = null) {
        scope.launch {
            runCatching { repository.joinClass(item.id, password = password) }
                .onSuccess { context.toast("已加入"); reload += 1 }
                .onFailure { context.toast(it.userMessage()) }
        }
    }

    fun join(item: ClassItem) {
        when (item.joinMode) {
            "PAID" -> paidTarget = item
            "PASSWORD" -> { pendingClass = item; passwordValue = ""; passwordDialog = true }
            else -> doJoin(item)
        }
    }

    PageScaffold(title = "班级", onBack = { nav.back() }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {
            Column(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(
                        value = keyword,
                        onValueChange = { keyword = it },
                        placeholder = { Text("搜索班级") },
                        singleLine = true,
                        modifier = Modifier.weight(1f),
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = Tokens.Primary, unfocusedBorderColor = Tokens.Border)
                    )
                    Spacer(Modifier.width(8.dp))
                    SecondaryButton("搜索", onClick = { reload += 1 })
                }
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(top = 8.dp).horizontalScroll(rememberScrollState())
                ) {
                    listOf("" to "全部", "false" to "免费", "true" to "付费").forEach { (value, label) ->
                        FilterChip(selected = paidFilter == value, onClick = { paidFilter = value }, label = { Text(label, fontSize = 12.sp) })
                    }
                    listOf("" to "默认", "priceAsc" to "价格↑", "priceDesc" to "价格↓", "students" to "人数", "newest" to "最新").forEach { (value, label) ->
                        FilterChip(selected = sort == value, onClick = { sort = value }, label = { Text(label, fontSize = 12.sp) })
                    }
                }
            }
            TabRow(selectedTabIndex = tab, containerColor = Tokens.Surface) {
                Tab(selected = tab == 0, onClick = { tab = 0 }) { Text("我的班级", modifier = Modifier.padding(12.dp)) }
                Tab(selected = tab == 1, onClick = { tab = 1 }) { Text("全部班级", modifier = Modifier.padding(12.dp)) }
            }
            AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无班级") { list ->
                Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                    list.forEach { cls ->
                        SectionCard(Modifier.padding(bottom = 10.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                if (!cls.coverUrl.isNullOrBlank()) {
                                    coil.compose.AsyncImage(
                                        model = cls.coverUrl,
                                        contentDescription = null,
                                        modifier = Modifier.size(72.dp).clip(RoundedCornerShape(10.dp)),
                                        contentScale = androidx.compose.ui.layout.ContentScale.Crop
                                    )
                                    Spacer(Modifier.width(12.dp))
                                }
                                Column(Modifier.weight(1f)) {
                                    Text(cls.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                                    Text(cls.description ?: "暂无简介", fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 2)
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(top = 4.dp)) {
                                        TagPill(joinModeText(cls.joinMode))
                                        if ((cls.price ?: 0.0) > 0) {
                                            Text("¥${Formatters.scoreText(cls.price)}", fontSize = 12.sp, color = Tokens.Danger)
                                        }
                                        Text("${cls.studentCount ?: cls.memberCount} 人", fontSize = 12.sp, color = Tokens.TextSecondary)
                                    }
                                }
                                when {
                                    cls.joined -> TagPill("已加入", Tokens.Success, Tokens.SuccessSoft)
                                    cls.joinStatus == "PENDING" -> TagPill("审核中", Tokens.Warning, Tokens.WarningSoft)
                                    else -> SecondaryButton("加入", onClick = { join(cls) })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (passwordDialog && pendingClass != null) {
        AlertDialog(
            onDismissRequest = { passwordDialog = false },
            title = { Text("班级密码") },
            text = {
                OutlinedTextField(
                    value = passwordValue,
                    onValueChange = { passwordValue = it },
                    placeholder = { Text("请输入班级加入密码") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    val target = pendingClass
                    passwordDialog = false
                    if (target != null) doJoin(target, passwordValue)
                }) { Text("加入") }
            },
            dismissButton = { TextButton(onClick = { passwordDialog = false }) { Text("取消") } }
        )
    }

    val target = paidTarget
    if (target != null) {
        AlertDialog(
            onDismissRequest = { paidTarget = null },
            title = { Text("付费加入") },
            text = { Text("需支付 ¥${Formatters.scoreText(target.price)}，确认支付？") },
            confirmButton = {
                TextButton(onClick = {
                    paidTarget = null
                    scope.launch {
                        runCatching {
                            val order = repository.createOrder("CLASS", target.id)
                            repository.payOrder(order.id)
                            repository.joinClass(target.id)
                        }.onSuccess { context.toast("已加入"); reload += 1 }
                            .onFailure { context.toast(it.userMessage()) }
                    }
                }) { Text("确认支付") }
            },
            dismissButton = { TextButton(onClick = { paidTarget = null }) { Text("取消") } }
        )
    }
}

private fun joinModeText(mode: String?): String = when (mode) {
    "FREE" -> "免费加入"
    "PASSWORD" -> "密码加入"
    "PAID" -> "付费加入"
    "APPROVAL" -> "审核加入"
    else -> "加入"
}

@Composable
fun ExamGroupScreen(repository: CandidateRepository, nav: AppNav) {
    val controller = rememberRemote("groups") { repository.examGroups() }
    val expanded = remember { mutableStateMapOf<String, Boolean>() }
    PageScaffold(title = "考试组进度", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无考试组") { list ->
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                list.forEach { group ->
                    val isOpen = expanded[group.id] ?: true
                    SectionCard(Modifier.padding(bottom = 10.dp)) {
                        Row(
                            Modifier.fillMaxWidth().clickable { expanded[group.id] = !isOpen },
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(Modifier.weight(1f)) {
                                Text(group.name, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                                Text(
                                    (if (group.groupType == "ALL_PASS") "通关：全部通过" else "闯关：按顺序解锁") +
                                        " · 及格线 ${Formatters.scoreText(group.passScore)}",
                                    fontSize = 12.sp,
                                    color = Tokens.TextSecondary
                                )
                            }
                            when {
                                group.passed == true -> TagPill("已通关", Tokens.Success, Tokens.SuccessSoft)
                                (group.passedCount ?: 0) > 0 -> TagPill("${group.passedCount}/${group.requiredCount ?: group.examCount}", Tokens.Warning, Tokens.WarningSoft)
                                else -> TagPill("0/${group.requiredCount ?: group.examCount}", Tokens.Primary, Tokens.PrimarySoft)
                            }
                        }
                        if (isOpen) {
                            if (group.items.isNotEmpty()) {
                                Spacer(Modifier.height(8.dp))
                                group.items.forEach { item ->
                                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                                        Box(
                                            Modifier.size(24.dp).clip(RoundedCornerShape(12.dp)).background(Tokens.SurfaceAlt),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text("${item.sortNo}", fontSize = 12.sp, color = Tokens.TextSecondary)
                                        }
                                        Spacer(Modifier.width(10.dp))
                                        Column(Modifier.weight(1f)) {
                                            Text(item.examName ?: item.examId, fontSize = 14.sp, color = Tokens.TextPrimary)
                                            Text("及格 ${Formatters.scoreText(item.passScore)}", fontSize = 11.sp, color = Tokens.TextSecondary)
                                        }
                                        val (label, fg, bg) = groupItemTag(item.status)
                                        TagPill(label, fg, bg)
                                    }
                                }
                            } else {
                                Spacer(Modifier.height(8.dp))
                                LinearProgressIndicator(
                                    progress = { (group.completedCount.toFloat() / (group.examCount.coerceAtLeast(1))).coerceIn(0f, 1f) },
                                    modifier = Modifier.fillMaxWidth(),
                                    color = Tokens.Primary
                                )
                                Spacer(Modifier.height(6.dp))
                                Text("共 ${group.examCount} 场 · 已完成 ${group.completedCount} 场", fontSize = 12.sp, color = Tokens.TextSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun groupItemTag(status: String): Triple<String, androidx.compose.ui.graphics.Color, androidx.compose.ui.graphics.Color> =
    when (status.uppercase()) {
        "PASSED" -> Triple("已通过", Tokens.Success, Tokens.SuccessSoft)
        "FAILED" -> Triple("未通过", Tokens.Danger, Tokens.DangerSoft)
        "AVAILABLE" -> Triple("可参加", Tokens.Primary, Tokens.PrimarySoft)
        "LOCKED" -> Triple("未解锁", Tokens.Warning, Tokens.WarningSoft)
        "NOT_PUBLISHED" -> Triple("成绩未发布", Tokens.Warning, Tokens.WarningSoft)
        else -> Triple(status, Tokens.TextSecondary, Tokens.SurfaceAlt)
    }

@Composable
fun MemberScreen(
    repository: CandidateRepository,
    nav: AppNav,
    pendingBizType: String? = null,
    pendingBizId: String? = null
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var reload by remember { mutableIntStateOf(0) }
    val profileController = rememberRemote("member-$reload") { repository.memberProfile() }
    val levelsController = rememberRemote("levels-$reload") { repository.memberLevels() }
    val ordersController = rememberRemote("orders-$reload") { repository.orders() }

    LaunchedEffect(pendingBizType, pendingBizId) {
        if (pendingBizType.isNullOrBlank() || pendingBizId.isNullOrBlank()) return@LaunchedEffect
        runCatching {
            val existing = repository.orders().firstOrNull {
                it.bizType == pendingBizType && it.bizId == pendingBizId && it.status in listOf("CREATED", "PAID")
            }
            val order = existing ?: repository.createOrder(pendingBizType, pendingBizId)
            if (order.status != "PAID") repository.payOrder(order.id)
        }.onSuccess {
            context.toast("支付成功")
            reload += 1
        }.onFailure { context.toast(it.userMessage()) }
    }

    PageScaffold(title = "会员中心", onBack = { nav.back() }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
            when (val s = profileController.state) {
                is UiState.Success -> {
                    val p = s.data
                    GradientHero(gradient = Tokens.GoldGradient) {
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(
                                    "${p.realName ?: "我"} · ${p.levelName.ifBlank { if (p.levelCode == "BASIC") "基础会员" else p.levelCode ?: "普通会员" }}",
                                    fontSize = 19.sp, fontWeight = FontWeight.Bold, color = Color.White
                                )
                                Spacer(Modifier.height(4.dp))
                                Text(
                                    when {
                                        !p.vipExpireAt.isNullOrBlank() -> "VIP 有效期至 ${p.vipExpireAt}"
                                        p.levelCode != null && p.levelCode != "BASIC" -> "长期有效"
                                        else -> "基础会员，购买等级享专属考试与练习"
                                    },
                                    fontSize = 12.sp, color = Color.White.copy(alpha = 0.9f)
                                )
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text("${p.pointsBalance ?: p.points}", fontSize = 26.sp, fontWeight = FontWeight.Bold, color = Color.White)
                                Text("积分余额", fontSize = 11.sp, color = Color.White.copy(alpha = 0.85f))
                            }
                        }
                    }
                }
                is UiState.Loading -> LoadingState()
                is UiState.Error -> ErrorBanner(s.message)
                else -> Unit
            }

            SectionHeader(title = "会员等级")
            val levels = (levelsController.state as? UiState.Success)?.data
            if (levels.isNullOrEmpty()) {
                EmptyState("暂无在售等级")
            } else {
                levels.forEach { level ->
                    SectionCard(Modifier.padding(bottom = 8.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(level.name, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                                Text(
                                    "${level.durationDays ?: 0} 天 · ${level.description ?: ""}",
                                    fontSize = 12.sp, color = Tokens.TextSecondary
                                )
                            }
                            Text("¥${Formatters.scoreText(level.price)}", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Tokens.Danger)
                        }
                        Spacer(Modifier.height(8.dp))
                        SecondaryButton("立即开通", onClick = {
                            scope.launch {
                                runCatching {
                                    val order = repository.createOrder("VIP", level.code)
                                    repository.payOrder(order.id)
                                }.onSuccess { context.toast("开通成功"); reload += 1 }
                                    .onFailure { context.toast(it.userMessage()) }
                            }
                        })
                    }
                }
            }

            SectionHeader(title = "我的订单")
            val orders = (ordersController.state as? UiState.Success)?.data
            if (orders.isNullOrEmpty()) {
                EmptyState("暂无订单")
            } else {
                orders.forEach { order ->
                    SectionCard(Modifier.padding(bottom = 8.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(bizText(order.bizType) + if (order.bizType == "VIP" && !order.bizId.isNullOrBlank()) " / ${order.bizId}" else "", fontSize = 14.sp, fontWeight = FontWeight.Medium)
                                Text("${order.orderNo ?: ""} · ${order.createdAt ?: ""}", fontSize = 11.sp, color = Tokens.TextSecondary)
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text("¥${Formatters.scoreText(order.amount)}", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Tokens.Danger)
                                TagPill(Formatters.orderStatusLabel(order.status), orderTagColor(order.status), orderTagBg(order.status))
                            }
                        }
                        if (order.status in listOf("CREATED", "UNPAID", "PENDING")) {
                            Spacer(Modifier.height(8.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                SecondaryButton("继续支付", onClick = {
                                    scope.launch {
                                        runCatching { repository.payOrder(order.id) }
                                            .onSuccess { context.toast("支付成功"); reload += 1 }
                                            .onFailure { context.toast(it.userMessage()) }
                                    }
                                })
                                SecondaryButton("取消", onClick = {
                                    scope.launch {
                                        runCatching { repository.cancelOrder(order.id) }
                                            .onSuccess { context.toast("已取消"); reload += 1 }
                                            .onFailure { context.toast(it.userMessage()) }
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun bizText(bizType: String?): String = when (bizType) {
    "EXAM" -> "考试订单"
    "PRACTICE" -> "练习订单"
    "CLASS" -> "班级订单"
    "VIP" -> "会员订单"
    else -> bizType ?: "订单"
}

private fun orderTagColor(status: String?): androidx.compose.ui.graphics.Color = when (status) {
    "PAID" -> Tokens.Success
    "CREATED", "UNPAID", "PENDING" -> Tokens.Warning
    "REFUNDED" -> Tokens.Danger
    else -> Tokens.TextSecondary
}

private fun orderTagBg(status: String?): androidx.compose.ui.graphics.Color = when (status) {
    "PAID" -> Tokens.SuccessSoft
    "CREATED", "UNPAID", "PENDING" -> Tokens.WarningSoft
    "REFUNDED" -> Tokens.DangerSoft
    else -> Tokens.SurfaceAlt
}

@Composable
fun NotificationScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val controller = rememberRemote("notifications") { repository.notifications() }
    PageScaffold(title = "消息通知", onBack = { nav.back() }, actions = {
        Text("全部已读", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.padding(end = 16.dp).clickable {
            scope.launch {
                runCatching { repository.markAllNotificationsRead() }.onSuccess { controller.reload() }.onFailure { context.toast(it.userMessage()) }
            }
        })
    }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无通知") { list: List<NotificationItem> ->
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                list.forEach { item ->
                    SectionCard(Modifier.padding(vertical = 5.dp)) {
                        Row(Modifier.clickable {
                            if (!item.read) {
                                scope.launch {
                                    runCatching { repository.markNotificationRead(item.id) }
                                        .onSuccess { controller.reload() }
                                }
                            }
                            val link = item.linkUrl
                            if (!link.isNullOrBlank()) {
                                when {
                                    link.startsWith("http", true) -> runCatching {
                                        context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(link)))
                                    }
                                    link.contains("exam") -> nav.tab(com.example.exammobile.ui.navigation.Routes.EXAMS)
                                    link.contains("practice") -> nav.tab(com.example.exammobile.ui.navigation.Routes.PRACTICE)
                                    link.contains("member") -> nav.member()
                                    link.contains("score") -> nav.scores()
                                    else -> nav.notifications()
                                }
                            }
                        }, verticalAlignment = Alignment.Top) {
                            Column(Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    if (!item.read) Box(Modifier.size(7.dp).clip(RoundedCornerShape(4.dp)).background(Tokens.Danger))
                                    Spacer(Modifier.width(6.dp))
                                    Text(item.title, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                                    item.type?.let { NotificationTypePill(it) }
                                    if (!item.linkUrl.isNullOrBlank()) {
                                        Text("›", fontSize = 18.sp, color = Tokens.TextTertiary)
                                    }
                                }
                                item.content?.let { Text(it, fontSize = 13.sp, color = Tokens.TextSecondary, maxLines = 3, overflow = TextOverflow.Ellipsis) }
                                item.createdAt?.let { Text(it, fontSize = 11.sp, color = Tokens.TextTertiary) }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationTypePill(type: String) {
    val (label, fg, bg) = when (type.uppercase()) {
        "APPEAL_RESULT" -> Triple("申诉", Tokens.Warning, Tokens.WarningSoft)
        "EXAM_PUBLISH" -> Triple("考试", Tokens.Primary, Tokens.PrimarySoft)
        "SYSTEM" -> Triple("系统", Tokens.Slate, Tokens.SlateSoft)
        else -> Triple("通知", Tokens.TextSecondary, Tokens.SurfaceAlt)
    }
    TagPill(label, fg, bg)
}

@Composable
fun CalendarScreen(repository: CandidateRepository, nav: AppNav) {
    val controller = rememberRemote("calendar") { repository.calendar() }
    PageScaffold(title = "考试日历", onBack = { nav.back() }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无安排") { list: List<CalendarItem> ->
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                list.forEach { item ->
                    SectionCard(Modifier.padding(vertical = 5.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(item.title, fontSize = 15.sp, fontWeight = FontWeight.Medium)
                                Text(listOfNotNull(item.date, item.startTime, item.endTime).joinToString(" "), fontSize = 12.sp, color = Tokens.TextSecondary)
                            }
                            item.type?.let { TagPill(it, Tokens.Primary, Tokens.PrimarySoft) }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun AppealScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val controller = rememberRemote("appeals") { repository.appeals() }
    var showDialog by remember { mutableStateOf(false) }
    var examId by remember { mutableStateOf("") }
    var reason by remember { mutableStateOf("") }

    PageScaffold(title = "成绩申诉", onBack = { nav.back() }, actions = {
        Text("发起申诉", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.padding(end = 16.dp).clickable { showDialog = true })
    }) { padding ->
        AsyncContent(controller.state, onRetry = { controller.reload() }, emptyCheck = { it.isEmpty() }, emptyText = "暂无申诉记录") { list: List<AppealItem> ->
            Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                list.forEach { appeal ->
                    SectionCard(Modifier.padding(vertical = 5.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(appeal.examName ?: appeal.examId ?: "考试", fontSize = 15.sp, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                            TagPill(appeal.status, Tokens.Primary, Tokens.PrimarySoft)
                        }
                        appeal.reason?.let { Text(it, fontSize = 12.sp, color = Tokens.TextSecondary) }
                        appeal.reply?.let { Text("回复：$it", fontSize = 12.sp, color = Tokens.Success) }
                    }
                }
            }
        }
    }

    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text("发起申诉") },
            text = {
                Column {
                    OutlinedTextField(value = examId, onValueChange = { examId = it }, label = { Text("考试 ID") }, singleLine = true)
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(value = reason, onValueChange = { reason = it }, label = { Text("申诉理由") }, minLines = 3)
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (examId.isBlank() || reason.isBlank()) { context.toast("请填写完整"); return@TextButton }
                    scope.launch {
                        runCatching {
                            repository.createAppeal(buildJsonObject { put("examId", examId.trim()); put("reason", reason.trim()) })
                        }.onSuccess { context.toast("已提交"); showDialog = false; controller.reload() }
                            .onFailure { context.toast(it.userMessage()) }
                    }
                }) { Text("提交") }
            },
            dismissButton = { TextButton(onClick = { showDialog = false }) { Text("取消") } }
        )
    }
}

@Composable
fun FaceScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var reload by remember { mutableIntStateOf(0) }
    var photoUrl by remember { mutableStateOf("") }
    var verifyPhotoUrl by remember { mutableStateOf("") }
    var examId by remember { mutableStateOf("") }
    var liveness by remember { mutableStateOf("PASS") }
    var uploading by remember { mutableStateOf(false) }

    val statusController = rememberRemote("face-$reload") { repository.faceStatus() }
    val logsController = rememberRemote("faceLogs-$reload") { repository.faceLogs() }

    fun upload(uri: android.net.Uri, onDone: (String) -> Unit) {
        scope.launch {
            uploading = true
            try {
                val file = java.io.File(context.cacheDir, "face_${System.currentTimeMillis()}.jpg")
                context.contentResolver.openInputStream(uri)?.use { input ->
                    file.outputStream().use { output -> input.copyTo(output) }
                }
                val resp = repository.faceUpload(file)
                onDone(resp.url)
                context.toast("照片已上传")
                file.delete()
            } catch (e: Exception) {
                context.toast(e.userMessage())
            } finally {
                uploading = false
            }
        }
    }

    val collectPicker = androidx.activity.compose.rememberLauncherForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.GetContent()
    ) { uri -> if (uri != null) upload(uri) { photoUrl = it } }
    val verifyPicker = androidx.activity.compose.rememberLauncherForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.GetContent()
    ) { uri -> if (uri != null) upload(uri) { verifyPhotoUrl = it } }

    PageScaffold(title = "人脸核验", onBack = { nav.back() }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
            when (val s = statusController.state) {
                is UiState.Success -> SectionCard {
                    KeyValueRow("照片状态", s.data.photo?.status ?: if (s.data.collected) "已采集" else "未采集")
                    KeyValueRow("最近核验", s.data.latestVerify?.result ?: if (s.data.verified) "PASS" else "无")
                    KeyValueRow("是否必需", if (s.data.required) "是" else "否")
                    if (s.data.livenessRequired == true) KeyValueRow("活体检测", "需完成")
                    s.data.message?.let { Text(it, fontSize = 12.sp, color = Tokens.TextSecondary) }
                }
                is UiState.Error -> ErrorBanner(s.message)
                else -> LoadingState()
            }
            Spacer(Modifier.height(12.dp))
            SectionCard {
                Text("照片采集", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    SecondaryButton(if (uploading) "上传中…" else "拍照/选择照片", onClick = { collectPicker.launch("image/*") }, enabled = !uploading)
                    SecondaryButton("提交采集", onClick = {
                        if (photoUrl.isBlank()) {
                            context.toast("请先上传照片")
                        } else {
                            scope.launch {
                                runCatching { repository.faceCollect(photoUrl) }
                                    .onSuccess { context.toast("已提交，等待审核"); reload += 1 }
                                    .onFailure { context.toast(it.userMessage()) }
                            }
                        }
                    })
                }
                if (photoUrl.isNotBlank()) {
                    Spacer(Modifier.height(8.dp))
                    coil.compose.AsyncImage(
                        model = photoUrl,
                        contentDescription = null,
                        modifier = Modifier.fillMaxWidth().height(160.dp).clip(RoundedCornerShape(10.dp)),
                        contentScale = androidx.compose.ui.layout.ContentScale.Crop
                    )
                }
            }
            Spacer(Modifier.height(12.dp))
            SectionCard {
                Text("考前核验", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = examId,
                    onValueChange = { examId = it },
                    label = { Text("考试 ID（可选）") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    SecondaryButton(if (uploading) "上传中…" else "现场拍照/选择照片", onClick = { verifyPicker.launch("image/*") }, enabled = !uploading)
                }
                if (verifyPhotoUrl.isNotBlank()) {
                    Spacer(Modifier.height(8.dp))
                    coil.compose.AsyncImage(
                        model = verifyPhotoUrl,
                        contentDescription = null,
                        modifier = Modifier.fillMaxWidth().height(160.dp).clip(RoundedCornerShape(10.dp)),
                        contentScale = androidx.compose.ui.layout.ContentScale.Crop
                    )
                }
                Spacer(Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("活体检测", fontSize = 13.sp, color = Tokens.TextSecondary)
                    Spacer(Modifier.width(12.dp))
                    FilterChip(selected = liveness == "PASS", onClick = { liveness = "PASS" }, label = { Text("检测通过", fontSize = 12.sp) })
                    Spacer(Modifier.width(8.dp))
                    FilterChip(selected = liveness == "FAIL", onClick = { liveness = "FAIL" }, label = { Text("未通过", fontSize = 12.sp) })
                }
                Spacer(Modifier.height(8.dp))
                PrimaryButton("开始核验", onClick = {
                    scope.launch {
                        runCatching {
                            repository.faceVerify(FaceVerifyRequest(
                                photoUrl = verifyPhotoUrl.takeIf { it.isNotBlank() },
                                examId = examId.takeIf { it.isNotBlank() },
                                livenessStatus = liveness
                            ))
                        }.onSuccess { context.toast("已核验"); reload += 1 }
                            .onFailure { context.toast(it.userMessage()) }
                    }
                })
            }
            SectionTitle("核验记录")
            val logs = (logsController.state as? UiState.Success)?.data
            if (logs.isNullOrEmpty()) {
                EmptyState("暂无记录")
            } else {
                SectionCard {
                    logs.forEach { log ->
                        Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(log.result ?: "-", fontSize = 13.sp)
                                Text(
                                    (log.verifiedAt ?: log.createdAt ?: "") +
                                        (if (!log.livenessStatus.isNullOrBlank()) " · 活体 ${log.livenessStatus}" else ""),
                                    fontSize = 11.sp, color = Tokens.TextSecondary
                                )
                            }
                            Text(log.similarity?.let { "${it}%" } ?: "-", fontSize = 13.sp, color = Tokens.Primary)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun DeviceScreen(repository: CandidateRepository, nav: AppNav) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val deviceId = remember { UUID.randomUUID().toString().replace("-", "") }
    val controller = rememberRemote("device") { repository.deviceAuth() }
    PageScaffold(title = "设备管理", onBack = { nav.back() }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
            when (val s = controller.state) {
                is UiState.Success -> SectionCard {
                    KeyValueRow("授权状态", if (s.data.authorized) "已授权" else "未授权")
                    s.data.deviceName?.let { KeyValueRow("设备", it) }
                    s.data.message?.let { Text(it, fontSize = 12.sp, color = Tokens.TextSecondary) }
                }
                is UiState.Error -> ErrorBanner(s.message)
                else -> LoadingState()
            }
            Spacer(Modifier.height(12.dp))
            SectionCard {
                Text("本机设备 ID", fontSize = 12.sp, color = Tokens.TextSecondary)
                Text(deviceId, fontSize = 12.sp, color = Tokens.TextPrimary)
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    SecondaryButton("绑定本机", onClick = {
                        scope.launch {
                            runCatching { repository.bindDevice(DeviceBindRequest(deviceId, "Android 设备", "ANDROID")) }
                                .onSuccess { context.toast("已绑定"); controller.reload() }
                                .onFailure { context.toast(it.userMessage()) }
                        }
                    })
                    SecondaryButton("解绑", onClick = {
                        scope.launch {
                            runCatching { repository.unbindDevice(deviceId) }
                                .onSuccess { context.toast("已解绑"); controller.reload() }
                                .onFailure { context.toast(it.userMessage()) }
                        }
                    })
                }
            }
        }
    }
}
