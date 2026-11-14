package com.example.exammobile.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/** 与 shared/design/tokens.json 一一对应的颜色令牌。 */
object Tokens {
    val Primary = Color(0xFF1F5F99)
    val PrimaryDark = Color(0xFF16466F)
    val PrimaryLight = Color(0xFF5AA7EA)
    val PrimarySoft = Color(0xFFE8F1FA)
    val Background = Color(0xFFF4F6FB)
    val Surface = Color(0xFFFFFFFF)
    val SurfaceAlt = Color(0xFFEEF3F8)
    val TextPrimary = Color(0xFF1F2937)
    val TextSecondary = Color(0xFF8A94A6)
    val TextTertiary = Color(0xFF94A3B8)
    val Border = Color(0xFFE2EAF3)
    val BorderStrong = Color(0xFFCBD5E1)
    val Success = Color(0xFF15803D)
    val SuccessSoft = Color(0xFFECFDF5)
    val Warning = Color(0xFFB45309)
    val WarningSoft = Color(0xFFFFFBEB)
    val Danger = Color(0xFFC0392B)
    val DangerSoft = Color(0xFFFDF2F2)
    val Info = Color(0xFF6D28D9)
    val InfoSoft = Color(0xFFF5F3FF)
    val Pink = Color(0xFFBE185D)
    val PinkSoft = Color(0xFFFDF2F8)

    fun typeColor(type: String): Pair<Color, Color> = when (type.uppercase()) {
        "SINGLE" -> Color(0xFF1F5F99) to Color(0xFFEEF6FF)
        "MULTIPLE" -> Color(0xFF6D28D9) to Color(0xFFF5F3FF)
        "JUDGE" -> Color(0xFF15803D) to Color(0xFFECFDF5)
        "FILL" -> Color(0xFFB45309) to Color(0xFFFFF7ED)
        "ESSAY" -> Color(0xFFBE185D) to Color(0xFFFDF2F8)
        else -> Color(0xFF1F5F99) to Color(0xFFEEF6FF)
    }
}

private val ColorScheme = lightColorScheme(
    primary = Tokens.Primary,
    onPrimary = Color.White,
    primaryContainer = Tokens.PrimarySoft,
    onPrimaryContainer = Tokens.PrimaryDark,
    secondary = Tokens.PrimaryLight,
    onSecondary = Color.White,
    background = Tokens.Background,
    onBackground = Tokens.TextPrimary,
    surface = Tokens.Surface,
    onSurface = Tokens.TextPrimary,
    surfaceVariant = Tokens.SurfaceAlt,
    onSurfaceVariant = Tokens.TextSecondary,
    outline = Tokens.Border,
    outlineVariant = Tokens.BorderStrong,
    error = Tokens.Danger,
    onError = Color.White,
    errorContainer = Tokens.DangerSoft,
    onErrorContainer = Tokens.Danger
)

private val AppTypography = Typography(
    displaySmall = TextStyle(fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Tokens.TextPrimary),
    headlineSmall = TextStyle(fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = Tokens.TextPrimary),
    titleLarge = TextStyle(fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = Tokens.TextPrimary),
    titleMedium = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Medium, color = Tokens.TextPrimary),
    bodyLarge = TextStyle(fontSize = 15.sp, fontWeight = FontWeight.Normal, color = Tokens.TextPrimary),
    bodyMedium = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Normal, color = Tokens.TextPrimary),
    bodySmall = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Normal, color = Tokens.TextSecondary),
    labelSmall = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.Medium, color = Tokens.TextSecondary)
)

@Composable
fun ExamMobileTheme(content: @Composable () -> Unit) {
    // 本产品为浅色教育类界面，固定浅色主题以与三端保持一致
    @Suppress("UNUSED_VARIABLE")
    val dark = isSystemInDarkTheme()
    MaterialTheme(colorScheme = ColorScheme, typography = AppTypography, content = content)
}
