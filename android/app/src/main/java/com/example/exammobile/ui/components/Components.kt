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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.exammobile.core.util.UiState
import com.example.exammobile.ui.theme.Tokens

val PagePadding = 16.dp
val CardRadius = RoundedCornerShape(18.dp)
private val SoftShadow = Color(0x140F172A)
private val ButtonShape = RoundedCornerShape(16.dp)

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
                    title = { Text(title, fontSize = 18.sp, fontWeight = FontWeight.SemiBold) },
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
                        titleContentColor = Tokens.TextPrimary,
                        scrolledContainerColor = Tokens.Surface
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
    elevated: Boolean = true,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .then(
                if (elevated) Modifier.shadow(10.dp, CardRadius, spotColor = SoftShadow)
                else Modifier
            )
            .clip(CardRadius)
            .background(Tokens.Surface)
            .border(1.dp, Tokens.Border.copy(alpha = 0.65f), CardRadius)
            .padding(padding),
        content = content
    )
}

/** 顶部渐变 Hero，带装饰光斑，替代纯色块。 */
@Composable
fun GradientHero(
    modifier: Modifier = Modifier,
    gradient: Brush = Tokens.HeroGradient,
    content: @Composable ColumnScope.() -> Unit
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .shadow(18.dp, RoundedCornerShape(24.dp), spotColor = Tokens.Primary.copy(alpha = 0.28f))
            .clip(RoundedCornerShape(24.dp))
            .background(gradient)
    ) {
        Box(
            Modifier
                .align(Alignment.TopEnd)
                .offset(x = 44.dp, y = (-56).dp)
                .size(180.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.13f))
        )
        Box(
            Modifier
                .align(Alignment.BottomEnd)
                .offset(x = 30.dp, y = 34.dp)
                .size(96.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.08f))
        )
        Column(Modifier.padding(20.dp), content = content)
    }
}

/** 带柔和底色的图标块。 */
@Composable
fun IconTile(
    icon: ImageVector,
    tint: Color = Tokens.Primary,
    bg: Color = Tokens.PrimarySoft,
    size: Dp = 44.dp,
    iconSize: Dp = 22.dp,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(RoundedCornerShape(size * 0.32f))
            .background(Brush.linearGradient(listOf(bg, bg.copy(alpha = 0.55f)))),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(iconSize))
    }
}

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false
) {
    val active = enabled && !loading
    val gradient = if (active) Tokens.PrimaryGradient else Brush.linearGradient(
        listOf(Tokens.BorderStrong, Tokens.BorderStrong)
    )
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(50.dp)
            .then(
                if (active) Modifier.shadow(12.dp, ButtonShape, spotColor = Tokens.Primary.copy(alpha = 0.35f))
                else Modifier
            )
            .clip(ButtonShape)
            .background(gradient)
            .clickable(enabled = active, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (loading) {
                CircularProgressIndicator(modifier = Modifier.size(18.dp), color = Color.White, strokeWidth = 2.dp)
                Spacer(Modifier.width(8.dp))
            }
            Text(text, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    Box(
        modifier = modifier
            .height(44.dp)
            .clip(ButtonShape)
            .background(if (enabled) Tokens.PrimarySoft else Tokens.SurfaceAlt)
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = if (enabled) Tokens.Primary else Tokens.TextTertiary
        )
    }
}

@Composable
fun SmallAction(text: String, onClick: () -> Unit, color: Color = Tokens.Primary) {
    Box(
        Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(color.copy(alpha = 0.10f))
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(text, color = color, fontSize = 12.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
fun TagPill(text: String, fg: Color = Tokens.Primary, bg: Color = Tokens.PrimarySoft) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(bg)
            .padding(horizontal = 9.dp, vertical = 4.dp)
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
    icon: ImageVector? = null,
    iconTint: Color = Tokens.Primary,
    iconBg: Color = Tokens.PrimarySoft,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = onClick != null) { onClick?.invoke() }
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            IconTile(icon, iconTint, iconBg, size = 34.dp, iconSize = 18.dp)
            Spacer(Modifier.width(12.dp))
        }
        Column(Modifier.weight(1f)) {
            Text(title, fontSize = 15.sp, color = Tokens.TextPrimary, fontWeight = FontWeight.Medium)
            if (!subtitle.isNullOrBlank()) {
                Spacer(Modifier.height(2.dp))
                Text(subtitle, fontSize = 12.sp, color = Tokens.TextSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
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
    Box(Modifier.fillMaxWidth().height(1.dp).background(Tokens.Border.copy(alpha = 0.7f)))
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
            .clip(RoundedCornerShape(14.dp))
            .background(Tokens.DangerSoft)
            .border(1.dp, Tokens.Danger.copy(alpha = 0.15f), RoundedCornerShape(14.dp))
            .padding(14.dp)
    ) {
        Text(message, color = Tokens.Danger, fontSize = 13.sp)
    }
}

@Composable
fun CountdownTimer(remainingSeconds: Int, modifier: Modifier = Modifier) {
    val danger = remainingSeconds <= 300
    Box(
        modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (danger) Tokens.DangerSoft else Tokens.PrimarySoft)
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Text(
            text = com.example.exammobile.core.util.Formatters.countdown(remainingSeconds),
            color = if (danger) Tokens.Danger else Tokens.Primary,
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            fontFamily = FontFamily.Monospace
        )
    }
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

/** 带左侧渐变强调条的分区标题，右侧可放「查看更多」。 */
@Composable
fun SectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null
) {
    Row(
        modifier = modifier.fillMaxWidth().padding(top = 20.dp, bottom = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            Modifier
                .width(4.dp)
                .height(18.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(Tokens.AccentGradient)
        )
        Spacer(Modifier.width(8.dp))
        Text(title, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = Tokens.TextPrimary)
        Spacer(Modifier.weight(1f))
        if (actionLabel != null && onAction != null) {
            Row(
                Modifier.clickable(onClick = onAction).padding(vertical = 2.dp, horizontal = 2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(actionLabel, fontSize = 12.sp, color = Tokens.TextSecondary)
                Icon(
                    Icons.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = Tokens.TextTertiary,
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}

@Composable
fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    SectionHeader(title = text, modifier = modifier)
}

@Composable
fun StatTile(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    tint: Color = Tokens.Primary,
    bg: Color = Tokens.PrimarySoft
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Brush.linearGradient(listOf(bg, bg.copy(alpha = 0.45f))))
            .padding(vertical = 14.dp, horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(value, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = tint)
        Spacer(Modifier.height(3.dp))
        Text(label, fontSize = 11.sp, color = Tokens.TextSecondary, maxLines = 1)
    }
}

@Composable
fun KeyValueRow(label: String, value: String) {
    Row(Modifier.fillMaxWidth().padding(vertical = 5.dp)) {
        Text(label, modifier = Modifier.width(84.dp), fontSize = 13.sp, color = Tokens.TextSecondary)
        Text(value, fontSize = 13.sp, color = Tokens.TextPrimary)
    }
}
