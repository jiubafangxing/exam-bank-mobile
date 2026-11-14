package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.exammobile.ui.components.GradientHero
import com.example.exammobile.ui.components.IconTile
import com.example.exammobile.ui.components.PageScaffold
import com.example.exammobile.ui.components.PagePadding
import com.example.exammobile.ui.components.PrimaryButton
import com.example.exammobile.ui.components.SecondaryButton
import com.example.exammobile.ui.components.SectionCard
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.viewmodel.AuthViewModel

@Composable
private fun AuthField(
    label: String,
    value: String,
    onChange: (String) -> Unit,
    password: Boolean = false,
    keyboardType: KeyboardType = KeyboardType.Text,
    icon: ImageVector? = null
) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label, fontSize = 13.sp) },
        singleLine = true,
        leadingIcon = icon?.let {
            { Icon(it, contentDescription = null, tint = Tokens.TextTertiary) }
        },
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        visualTransformation = if (password) PasswordVisualTransformation() else androidx.compose.ui.text.input.VisualTransformation.None,
        keyboardOptions = KeyboardOptions(keyboardType = if (password) KeyboardType.Password else keyboardType),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Tokens.Primary,
            unfocusedBorderColor = Tokens.Border,
            focusedLabelColor = Tokens.Primary,
            focusedContainerColor = Tokens.Surface,
            unfocusedContainerColor = Tokens.Surface
        )
    )
}

@Composable
private fun AuthHero(title: String, subtitle: String, icon: ImageVector) {
    GradientHero {
        IconTile(icon, Color.White, Color.White.copy(alpha = 0.20f), size = 46.dp, iconSize = 24.dp)
        Spacer(Modifier.height(14.dp))
        Text(title, fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.White)
        Spacer(Modifier.height(5.dp))
        Text(subtitle, fontSize = 13.sp, color = Color.White.copy(alpha = 0.88f))
    }
}

@Composable
fun LoginScreen(authVm: AuthViewModel, nav: AppNav) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    val submitting by authVm.submitting.collectAsState()
    val meta by authVm.meta.collectAsState()

    PageScaffold { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .background(Tokens.Background)
                .verticalScroll(rememberScrollState())
        ) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(244.dp)
                    .clip(RoundedCornerShape(bottomStart = 34.dp, bottomEnd = 34.dp))
                    .background(Tokens.HeroGradient)
            ) {
                Box(
                    Modifier.align(Alignment.TopEnd).offset(x = 48.dp, y = (-52).dp).size(190.dp)
                        .clip(CircleShape).background(Color.White.copy(alpha = 0.13f))
                )
                Box(
                    Modifier.align(Alignment.BottomStart).offset(x = (-40).dp, y = 42.dp).size(130.dp)
                        .clip(CircleShape).background(Color.White.copy(alpha = 0.08f))
                )
                Column(Modifier.padding(horizontal = 24.dp).padding(top = 54.dp)) {
                    IconTile(Icons.Filled.Lock, Color.White, Color.White.copy(alpha = 0.20f), size = 50.dp, iconSize = 26.dp)
                    Spacer(Modifier.height(16.dp))
                    Text("在线考试", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color.White)
                    Spacer(Modifier.height(5.dp))
                    Text("登录后参加考试、练习与学习", fontSize = 13.sp, color = Color.White.copy(alpha = 0.88f))
                }
            }

            SectionCard(Modifier.padding(horizontal = 20.dp).offset(y = (-30).dp)) {
                Text("账号登录", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = Tokens.TextPrimary)
                Spacer(Modifier.height(14.dp))
                AuthField("账号", username, { username = it }, icon = Icons.Filled.AccountCircle)
                Spacer(Modifier.height(12.dp))
                AuthField("密码", password, { password = it }, password = true, icon = Icons.Filled.Lock)
                Spacer(Modifier.height(20.dp))
                PrimaryButton("登录", onClick = { authVm.login(username, password) }, loading = submitting)
                Spacer(Modifier.height(14.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    if (meta?.smsEnabled == true) {
                        Text("短信登录", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.clickable { nav.smsLogin() })
                    } else {
                        Spacer(Modifier.width(1.dp))
                    }
                    Text("注册账号", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.clickable { nav.register() })
                    Text("忘记密码", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.clickable { nav.resetPassword() })
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
fun SmsLoginScreen(authVm: AuthViewModel, nav: AppNav) {
    var phone by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    val submitting by authVm.submitting.collectAsState()

    PageScaffold(title = "短信登录", onBack = { nav.back() }) { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(PagePadding)
        ) {
            AuthHero("短信登录", "输入手机号与验证码，快速进入学习", Icons.Filled.Phone)
            Spacer(Modifier.height(12.dp))
            SectionCard {
                AuthField("手机号", phone, { phone = it }, keyboardType = KeyboardType.Phone, icon = Icons.Filled.Phone)
                Spacer(Modifier.height(12.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.weight(1f)) {
                        AuthField("验证码", code, { code = it }, keyboardType = KeyboardType.Number, icon = Icons.Filled.Send)
                    }
                    Spacer(Modifier.width(10.dp))
                    SecondaryButton("发送验证码", onClick = { authVm.sendOtp(phone) })
                }
                Spacer(Modifier.height(20.dp))
                PrimaryButton("登录", onClick = { authVm.smsLogin(phone, code) }, loading = submitting)
            }
        }
    }
}

@Composable
fun RegisterScreen(authVm: AuthViewModel, nav: AppNav) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var realName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    val submitting by authVm.submitting.collectAsState()

    PageScaffold(title = "注册", onBack = { nav.back() }) { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(PagePadding)
        ) {
            AuthHero("创建账号", "注册后即可参加考试与在线练习", Icons.Filled.Person)
            Spacer(Modifier.height(12.dp))
            SectionCard {
                AuthField("账号", username, { username = it }, icon = Icons.Filled.AccountCircle)
                Spacer(Modifier.height(12.dp))
                AuthField("密码", password, { password = it }, password = true, icon = Icons.Filled.Lock)
                Spacer(Modifier.height(12.dp))
                AuthField("姓名", realName, { realName = it }, icon = Icons.Filled.Person)
                Spacer(Modifier.height(12.dp))
                AuthField("手机号", phone, { phone = it }, keyboardType = KeyboardType.Phone, icon = Icons.Filled.Phone)
                Spacer(Modifier.height(20.dp))
                PrimaryButton("注册", onClick = { authVm.register(username, password, realName, phone) }, loading = submitting)
            }
        }
    }
}

@Composable
fun ResetPasswordScreen(authVm: AuthViewModel, nav: AppNav) {
    var phone by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    val submitting by authVm.submitting.collectAsState()

    PageScaffold(title = "重置密码", onBack = { nav.back() }) { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(PagePadding)
        ) {
            AuthHero("重置密码", "通过手机号验证后设置新密码", Icons.Filled.Lock)
            Spacer(Modifier.height(12.dp))
            SectionCard {
                AuthField("手机号", phone, { phone = it }, keyboardType = KeyboardType.Phone, icon = Icons.Filled.Phone)
                Spacer(Modifier.height(12.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.weight(1f)) {
                        AuthField("验证码", code, { code = it }, keyboardType = KeyboardType.Number, icon = Icons.Filled.Send)
                    }
                    Spacer(Modifier.width(10.dp))
                    SecondaryButton("发送验证码", onClick = { authVm.sendOtp(phone, "reset") })
                }
                Spacer(Modifier.height(12.dp))
                AuthField("新密码", password, { password = it }, password = true, icon = Icons.Filled.Lock)
                Spacer(Modifier.height(20.dp))
                PrimaryButton("确认重置", onClick = { authVm.resetPassword(phone, code, password) }, loading = submitting)
            }
        }
    }
}

@Composable
fun TenantScreen(authVm: AuthViewModel, nav: AppNav) {
    val tenants by authVm.tenants.collectAsState()
    val submitting by authVm.submitting.collectAsState()
    LaunchedEffect(Unit) { authVm.loadTenants() }

    PageScaffold(title = "选择机构") { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(PagePadding)
        ) {
            GradientHero {
                Text("选择机构", fontSize = 21.sp, fontWeight = FontWeight.Bold, color = Color.White)
                Spacer(Modifier.height(5.dp))
                Text("当前账号属于多个机构，请选择要进入的机构", fontSize = 13.sp, color = Color.White.copy(alpha = 0.88f))
            }
            Spacer(Modifier.height(14.dp))
            if (tenants.isEmpty()) {
                SectionCard {
                    Text("当前账号尚未加入任何机构，请联系机构管理员邀请。", fontSize = 13.sp, color = Tokens.TextSecondary, lineHeight = 20.sp)
                }
            }
            tenants.forEach { tenant ->
                SectionCard(Modifier.padding(bottom = 10.dp)) {
                    Row(
                        Modifier.fillMaxWidth().clickable { authVm.switchTenant(tenant.tenantId) },
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconTile(Icons.Filled.Person, Tokens.Primary, Tokens.PrimarySoft)
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(tenant.tenantName, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                            Text(tenant.tenantCode, fontSize = 12.sp, color = Tokens.TextSecondary)
                        }
                        Text("›", fontSize = 20.sp, color = Tokens.TextTertiary)
                    }
                }
            }
            if (submitting) {
                Spacer(Modifier.height(12.dp))
                CircularProgressIndicator(color = Tokens.Primary)
            }
        }
    }
}
