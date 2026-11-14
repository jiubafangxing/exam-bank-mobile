package com.example.exammobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.exammobile.ui.components.PageScaffold
import com.example.exammobile.ui.components.PrimaryButton
import com.example.exammobile.ui.components.SecondaryButton
import com.example.exammobile.ui.navigation.AppNav
import com.example.exammobile.ui.theme.Tokens
import com.example.exammobile.ui.viewmodel.AuthViewModel

@Composable
private fun AuthField(
    label: String,
    value: String,
    onChange: (String) -> Unit,
    password: Boolean = false,
    keyboardType: KeyboardType = KeyboardType.Text
) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        visualTransformation = if (password) PasswordVisualTransformation() else androidx.compose.ui.text.input.VisualTransformation.None,
        keyboardOptions = KeyboardOptions(keyboardType = if (password) KeyboardType.Password else keyboardType),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Tokens.Primary,
            unfocusedBorderColor = Tokens.Border,
            focusedLabelColor = Tokens.Primary
        )
    )
}

@Composable
private fun AuthHeader(title: String, subtitle: String) {
    Column(Modifier.fillMaxWidth().padding(top = 48.dp, bottom = 24.dp)) {
        Text(title, fontSize = 26.sp, fontWeight = FontWeight.Bold, color = Tokens.TextPrimary)
        Spacer(Modifier.height(6.dp))
        Text(subtitle, fontSize = 14.sp, color = Tokens.TextSecondary)
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
                .padding(horizontal = 24.dp)
        ) {
            AuthHeader("在线考试", "登录后参加考试、练习与学习")
            AuthField("账号", username, { username = it })
            Spacer(Modifier.height(12.dp))
            AuthField("密码", password, { password = it }, password = true)
            Spacer(Modifier.height(20.dp))
            PrimaryButton("登录", onClick = { authVm.login(username, password) }, loading = submitting)
            Spacer(Modifier.height(12.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                if (meta?.smsEnabled == true) {
                    Text("短信登录", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.clickable { nav.smsLogin() })
                } else {
                    Spacer(Modifier.width(1.dp))
                }
                Text("注册账号", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.clickable { nav.register() })
                Text("忘记密码", color = Tokens.Primary, fontSize = 13.sp, modifier = Modifier.clickable { nav.resetPassword() })
            }
            Spacer(Modifier.height(40.dp))
        }
    }
}

@Composable
fun SmsLoginScreen(authVm: AuthViewModel, nav: AppNav) {
    var phone by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    val submitting by authVm.submitting.collectAsState()

    PageScaffold(title = "短信登录", onBack = { nav.back() }) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().padding(24.dp)) {
            AuthHeader("短信登录", "输入手机号与验证码")
            AuthField("手机号", phone, { phone = it }, keyboardType = KeyboardType.Phone)
            Spacer(Modifier.height(12.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f)) {
                    AuthField("验证码", code, { code = it }, keyboardType = KeyboardType.Number)
                }
                Spacer(Modifier.width(12.dp))
                SecondaryButton("发送验证码", onClick = { authVm.sendOtp(phone) })
            }
            Spacer(Modifier.height(20.dp))
            PrimaryButton("登录", onClick = { authVm.smsLogin(phone, code) }, loading = submitting)
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
        Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp)) {
            AuthHeader("创建账号", "注册后即可参加考试")
            AuthField("账号", username, { username = it })
            Spacer(Modifier.height(12.dp))
            AuthField("密码", password, { password = it }, password = true)
            Spacer(Modifier.height(12.dp))
            AuthField("姓名", realName, { realName = it })
            Spacer(Modifier.height(12.dp))
            AuthField("手机号", phone, { phone = it }, keyboardType = KeyboardType.Phone)
            Spacer(Modifier.height(20.dp))
            PrimaryButton("注册", onClick = { authVm.register(username, password, realName, phone) }, loading = submitting)
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
        Column(Modifier.padding(padding).fillMaxSize().padding(24.dp)) {
            AuthHeader("重置密码", "通过手机号验证后设置新密码")
            AuthField("手机号", phone, { phone = it }, keyboardType = KeyboardType.Phone)
            Spacer(Modifier.height(12.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f)) {
                    AuthField("验证码", code, { code = it }, keyboardType = KeyboardType.Number)
                }
                Spacer(Modifier.width(12.dp))
                SecondaryButton("发送验证码", onClick = { authVm.sendOtp(phone, "reset") })
            }
            Spacer(Modifier.height(12.dp))
            AuthField("新密码", password, { password = it }, password = true)
            Spacer(Modifier.height(20.dp))
            PrimaryButton("确认重置", onClick = { authVm.resetPassword(phone, code, password) }, loading = submitting)
        }
    }
}

@Composable
fun TenantScreen(authVm: AuthViewModel, nav: AppNav) {
    val tenants by authVm.tenants.collectAsState()
    val submitting by authVm.submitting.collectAsState()
    LaunchedEffect(Unit) { authVm.loadTenants() }

    PageScaffold(title = "选择机构") { padding ->
        Column(Modifier.padding(padding).fillMaxSize().padding(16.dp)) {
            Text("当前账号属于多个机构，请选择要进入的机构", fontSize = 14.sp, color = Tokens.TextSecondary)
            Spacer(Modifier.height(16.dp))
            if (tenants.isEmpty()) {
                Text("加载机构列表…", fontSize = 14.sp, color = Tokens.TextSecondary)
            }
            tenants.forEach { tenant ->
                Card(
                    modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp)
                        .clickable { authVm.switchTenant(tenant.tenantId) },
                    colors = CardDefaults.cardColors(containerColor = Tokens.Surface)
                ) {
                    Column(Modifier.padding(16.dp)) {
                        Text(tenant.tenantName, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                        Text(tenant.tenantCode, fontSize = 13.sp, color = Tokens.TextSecondary)
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
