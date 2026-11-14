package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
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
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.viewmodel.AuthViewModel

@Composable
fun ProfileScreen(authVm: AuthViewModel, nav: AppNav) {
    val user by authVm.user.collectAsState()
    var showLogout by remember { mutableStateOf(false) }

    PageScaffold(title = "个人中心") { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)
        ) {
            SectionCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(56.dp).clip(CircleShape).background(Tokens.Primary),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            (user?.realName?.take(1) ?: user?.username?.take(1) ?: "?"),
                            color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(Modifier.width(16.dp))
                    Column {
                        Text(user?.realName?.ifBlank { user?.username ?: "同学" } ?: "同学", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                        Text(user?.username ?: "", fontSize = 13.sp, color = Tokens.TextSecondary)
                    }
                }
            }

            Spacer(Modifier.height(12.dp))
            SectionCard {
                ListRow("我的成绩", onClick = { nav.scores() })
                DividerLine()
                ListRow("成绩申诉", onClick = { nav.appeals() })
                DividerLine()
                ListRow("考试日历", onClick = { nav.calendar() })
                DividerLine()
                ListRow("消息通知", onClick = { nav.notifications() })
                DividerLine()
                ListRow("考试组进度", onClick = { nav.examGroups() })
                DividerLine()
                ListRow("排行榜", onClick = { nav.ranking() })
            }
            Spacer(Modifier.height(12.dp))
            SectionCard {
                ListRow("在线练习", onClick = { nav.tab(com.example.exammobile.ui.navigation.Routes.PRACTICE) })
                DividerLine()
                ListRow("我的错题集", onClick = { nav.wrong() })
                DividerLine()
                ListRow("练习统计", onClick = { nav.practiceStats() })
                DividerLine()
                ListRow("会员中心", onClick = { nav.member() })
                DividerLine()
                ListRow("个人分析", onClick = { nav.analysis() })
                DividerLine()
                ListRow("班级", onClick = { nav.classes() })
                DividerLine()
                ListRow("人脸核验", onClick = { nav.face() })
                DividerLine()
                ListRow("设备管理", onClick = { nav.device() })
                DividerLine()
                ListRow("修改密码", onClick = { nav.resetPassword() })
            }
            Spacer(Modifier.height(24.dp))
            TextButton(
                onClick = { showLogout = true },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("退出登录", color = Tokens.Danger, fontSize = 16.sp)
            }
            Spacer(Modifier.height(16.dp))
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
