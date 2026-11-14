package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Face
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.exammobile.ui.components.*
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.navigation.Routes
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.viewmodel.AuthViewModel

@Composable
fun ProfileScreen(authVm: AuthViewModel, nav: AppNav) {
    val user by authVm.user.collectAsState()
    var showLogout by remember { mutableStateOf(false) }
    val displayName = user?.realName?.takeIf { it.isNotBlank() } ?: user?.username?.takeIf { it.isNotBlank() } ?: "同学"

    PageScaffold(title = "个人中心") { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = PagePadding, vertical = 10.dp)
        ) {
            GradientHero {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(64.dp).clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.20f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            displayName.take(1),
                            color = Color.White, fontSize = 25.sp, fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(displayName, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
                        Spacer(Modifier.height(3.dp))
                        Text(
                            user?.username ?: "在线考试学员",
                            fontSize = 13.sp,
                            color = Color.White.copy(alpha = 0.85f)
                        )
                    }
                    Box(
                        Modifier.clip(RoundedCornerShape(999.dp))
                            .background(Color.White.copy(alpha = 0.18f))
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("学员", fontSize = 11.sp, color = Color.White)
                    }
                }
            }

            SectionHeader(title = "学习与成绩")
            SectionCard(padding = 14.dp) {
                ListRow("我的成绩", icon = Icons.Filled.Star, iconTint = Tokens.Amber, iconBg = Tokens.AmberSoft, onClick = { nav.scores() })
                DividerLine()
                ListRow("成绩申诉", icon = Icons.Filled.Send, iconTint = Tokens.Coral, iconBg = Tokens.CoralSoft, onClick = { nav.appeals() })
                DividerLine()
                ListRow("考试日历", icon = Icons.Filled.DateRange, iconTint = Tokens.Accent, iconBg = Tokens.AccentSoft, onClick = { nav.calendar() })
                DividerLine()
                ListRow("消息通知", icon = Icons.Filled.Notifications, iconTint = Tokens.Sky, iconBg = Tokens.SkySoft, onClick = { nav.notifications() })
                DividerLine()
                ListRow("考试组进度", icon = Icons.Filled.CheckCircle, iconTint = Tokens.Violet, iconBg = Tokens.VioletSoft, onClick = { nav.examGroups() })
                DividerLine()
                ListRow("排行榜", icon = Icons.Filled.Star, iconTint = Tokens.Primary, iconBg = Tokens.PrimarySoft, onClick = { nav.ranking() })
            }

            SectionHeader(title = "练习与成长")
            SectionCard(padding = 14.dp) {
                ListRow("在线练习", icon = Icons.Filled.Edit, iconTint = Tokens.Accent, iconBg = Tokens.AccentSoft, onClick = { nav.tab(Routes.PRACTICE) })
                DividerLine()
                ListRow("我的错题集", icon = Icons.Filled.Warning, iconTint = Tokens.Danger, iconBg = Tokens.DangerSoft, onClick = { nav.wrong() })
                DividerLine()
                ListRow("练习统计", icon = Icons.Filled.List, iconTint = Tokens.Sky, iconBg = Tokens.SkySoft, onClick = { nav.practiceStats() })
                DividerLine()
                ListRow("会员中心", icon = Icons.Filled.ShoppingCart, iconTint = Tokens.Amber, iconBg = Tokens.AmberSoft, onClick = { nav.member() })
                DividerLine()
                ListRow("个人分析", icon = Icons.Filled.Info, iconTint = Tokens.Violet, iconBg = Tokens.VioletSoft, onClick = { nav.analysis() })
                DividerLine()
                ListRow("班级", icon = Icons.Filled.Person, iconTint = Tokens.Coral, iconBg = Tokens.CoralSoft, onClick = { nav.classes() })
            }

            SectionHeader(title = "账号与安全")
            SectionCard(padding = 14.dp) {
                ListRow("人脸核验", icon = Icons.Filled.Face, iconTint = Tokens.Sky, iconBg = Tokens.SkySoft, onClick = { nav.face() })
                DividerLine()
                ListRow("设备管理", icon = Icons.Filled.Settings, iconTint = Tokens.Slate, iconBg = Tokens.SlateSoft, onClick = { nav.device() })
                DividerLine()
                ListRow("修改密码", icon = Icons.Filled.Lock, iconTint = Tokens.Primary, iconBg = Tokens.PrimarySoft, onClick = { nav.resetPassword() })
            }

            Spacer(Modifier.height(18.dp))
            Box(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Tokens.DangerSoft)
                    .clickable { showLogout = true }
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text("退出登录", color = Tokens.Danger, fontSize = 15.sp, fontWeight = FontWeight.Medium)
            }
            Spacer(Modifier.height(20.dp))
        }
    }

    if (showLogout) {
        AlertDialog(
            onDismissRequest = { showLogout = false },
            title = { Text("退出登录") },
            text = { Text("确认退出当前账号？") },
            confirmButton = { TextButton(onClick = { showLogout = false; authVm.logout() }) { Text("退出") } },
            dismissButton = { TextButton(onClick = { showLogout = false }) { Text("取消") } }
        )
    }
}
