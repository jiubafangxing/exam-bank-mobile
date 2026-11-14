package com.example.exammobile.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.exammobile.core.util.UiState
import com.example.exammobile.ui.theme.Tokens

val PagePadding = 16.dp
val CardRadius = RoundedCornerShape(16.dp)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PageScaffold(
    title: String? = null,
    onBack: (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {},
    bottomBar: @Composable () -> Unit = {},
    content: @Composable (PaddingValues) -> Unit
) {
    Scaffold(
        containerColor = Tokens.Background,
        topBar = {
            if (title != null) {
                TopAppBar(
                    title = { Text(title, fontSize = 17.sp, fontWeight = FontWeight.SemiBold) },
                    navigationIcon = {
                        if (onBack != null) {
                            IconButton(onClick = onBack) {
                                Icon(Icons.Filled.ArrowBack, contentDescription = "返回", tint = Tokens.TextPrimary)
                            }
                        }
                    },
                    actions = actions,
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = Tokens.Surface,
                        titleContentColor = Tokens.TextPrimary
                    )
                )
            }
        },
        bottomBar = bottomBar,
        content = content
    )
}

@Composable
fun SectionCard(
    modifier: Modifier = Modifier,
    padding: Dp = PagePadding,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(CardRadius)
            .background(Tokens.Surface)
            .padding(padding),
        content = content
    )
}

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false
) {
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        modifier = modifier
            .fillMaxWidth()
            .height(48.dp),
        shape = RoundedCornerShape(999.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Tokens.Primary)
    ) {
        if (loading) {
            CircularProgressIndicator(modifier = Modifier.size(18.dp), color = Color.White, strokeWidth = 2.dp)
            Spacer(Modifier.width(8.dp))
        }
        Text(text, fontSize = 16.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.height(44.dp),
        shape = RoundedCornerShape(999.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, Tokens.Primary),
        colors = ButtonDefaults.outlinedButtonColors(contentColor = Tokens.Primary)
    ) {
        Text(text, fontSize = 14.sp)
    }
}

@Composable
fun TagPill(text: String, fg: Color = Tokens.Primary, bg: Color = Tokens.PrimarySoft) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(bg)
            .padding(horizontal = 8.dp, vertical = 3.dp)
    ) {
        Text(text, color = fg, fontSize = 11.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
fun ListRow(
    title: String,
    subtitle: String? = null,
    trailing: String? = null,
    showArrow: Boolean = true,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = onClick != null) { onClick?.invoke() }
            .padding(vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(title, fontSize = 15.sp, color = Tokens.TextPrimary, fontWeight = FontWeight.Medium)
            if (!subtitle.isNullOrBlank()) {
                Spacer(Modifier.height(2.dp))
                Text(subtitle, fontSize = 13.sp, color = Tokens.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        if (trailing != null) {
            Text(trailing, fontSize = 13.sp, color = Tokens.TextSecondary)
            Spacer(Modifier.width(6.dp))
        }
        if (showArrow) {
            Icon(Icons.Filled.KeyboardArrowRight, contentDescription = null, tint = Tokens.TextTertiary)
        }
    }
}

@Composable
fun DividerLine() {
    Box(Modifier.fillMaxWidth().height(1.dp).background(Tokens.Border))
}

@Composable
fun EmptyState(text: String = "暂无数据", modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().padding(vertical = 48.dp), contentAlignment = Alignment.Center) {
        Text(text, fontSize = 14.sp, color = Tokens.TextSecondary)
    }
}

@Composable
fun LoadingState(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().padding(vertical = 48.dp), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = Tokens.Primary, strokeWidth = 2.dp, modifier = Modifier.size(28.dp))
    }
}

@Composable
fun ErrorBanner(message: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Tokens.DangerSoft)
            .padding(14.dp)
    ) {
        Text(message, color = Tokens.Danger, fontSize = 13.sp)
    }
}

@Composable
fun CountdownTimer(remainingSeconds: Int, modifier: Modifier = Modifier) {
    val danger = remainingSeconds <= 300
    Text(
        text = com.example.exammobile.core.util.Formatters.countdown(remainingSeconds),
        modifier = modifier,
        color = if (danger) Tokens.Danger else Tokens.Primary,
        fontSize = 15.sp,
        fontWeight = FontWeight.SemiBold,
        fontFamily = FontFamily.Monospace
    )
}

/** 根据 UiState 统一渲染 加载/错误/内容。 */
@Composable
fun <T> AsyncContent(
    state: UiState<T>,
    onRetry: (() -> Unit)? = null,
    emptyCheck: (T) -> Boolean = { false },
    emptyText: String = "暂无数据",
    content: @Composable (T) -> Unit
) {
    when (state) {
        is UiState.Idle, is UiState.Loading -> LoadingState()
        is UiState.Error -> Column(Modifier.padding(PagePadding)) {
            ErrorBanner(state.message)
            if (onRetry != null) {
                Spacer(Modifier.height(12.dp))
                SecondaryButton(text = "重试", onClick = onRetry)
            }
        }
        is UiState.Success -> if (emptyCheck(state.data)) EmptyState(emptyText) else content(state.data)
    }
}

@Composable
fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        modifier = modifier.padding(top = 18.dp, bottom = 8.dp),
        fontSize = 15.sp,
        fontWeight = FontWeight.SemiBold,
        color = Tokens.TextPrimary
    )
}

@Composable
fun KeyValueRow(label: String, value: String) {
    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        Text(label, modifier = Modifier.width(84.dp), fontSize = 13.sp, color = Tokens.TextSecondary)
        Text(value, fontSize = 13.sp, color = Tokens.TextPrimary)
    }
}
