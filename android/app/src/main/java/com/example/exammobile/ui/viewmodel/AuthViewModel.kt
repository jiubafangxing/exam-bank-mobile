package com.example.exammobile.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.exammobile.core.model.AuthMeta
import com.example.exammobile.core.model.TenantMembership
import com.example.exammobile.core.model.User
import com.example.exammobile.core.network.ApiException
import com.example.exammobile.core.storage.SessionStore
import com.example.exammobile.data.CandidateRepository
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch

class AuthViewModel(
    private val repository: CandidateRepository,
    private val sessionStore: SessionStore
) : ViewModel() {

    val user: StateFlow<User?> = sessionStore.user
    val loggedIn: StateFlow<Boolean> = sessionStore.loggedIn

    private val _submitting = MutableStateFlow(false)
    val submitting: StateFlow<Boolean> = _submitting.asStateFlow()

    private val _meta = MutableStateFlow<AuthMeta?>(null)
    val meta: StateFlow<AuthMeta?> = _meta.asStateFlow()

    private val _tenants = MutableStateFlow<List<TenantMembership>>(emptyList())
    val tenants: StateFlow<List<TenantMembership>> = _tenants.asStateFlow()

    private val events = Channel<AuthEvent>(Channel.BUFFERED)
    val uiEvents = events.receiveAsFlow()

    fun loadMeta() {
        viewModelScope.launch {
            runCatching { repository.meta() }.onSuccess { _meta.value = it }
        }
    }

    fun loadTenants() {
        viewModelScope.launch {
            runCatching { repository.tenantContext() }.onSuccess {
                _tenants.value = it.tenants
                if (!it.requiresTenantSelection && it.tenantId != null) {
                    events.send(AuthEvent.LoggedIn)
                }
            }
        }
    }

    fun login(username: String, password: String, tenantId: String? = null, tenantCode: String? = null) {
        if (username.isBlank() || password.isBlank()) {
            emitToast("请输入账号和密码"); return
        }
        viewModelScope.launch {
            _submitting.value = true
            try {
                val resp = repository.login(username.trim(), password, tenantId, tenantCode)
                sessionStore.saveSession(resp.token, resp.user)
                if (resp.requiresTenantSelection == true && resp.tenantId == null) {
                    _tenants.value = resp.tenants ?: emptyList()
                    events.send(AuthEvent.NeedTenant)
                } else {
                    events.send(AuthEvent.LoggedIn)
                }
            } catch (e: Exception) {
                emitToast(e.userMessage())
            } finally {
                _submitting.value = false
            }
        }
    }

    fun smsLogin(phone: String, code: String, tenantId: String? = null, tenantCode: String? = null) {
        if (phone.isBlank() || code.isBlank()) {
            emitToast("请输入手机号和验证码"); return
        }
        viewModelScope.launch {
            _submitting.value = true
            try {
                val resp = repository.smsLogin(phone.trim(), code.trim(), tenantId, tenantCode)
                sessionStore.saveSession(resp.token, resp.user)
                if (resp.requiresTenantSelection == true && resp.tenantId == null) {
                    _tenants.value = resp.tenants ?: emptyList()
                    events.send(AuthEvent.NeedTenant)
                } else {
                    events.send(AuthEvent.LoggedIn)
                }
            } catch (e: Exception) {
                emitToast(e.userMessage())
            } finally {
                _submitting.value = false
            }
        }
    }

    fun sendOtp(phone: String, scene: String = "login") {
        if (phone.isBlank()) { emitToast("请输入手机号"); return }
        viewModelScope.launch {
            runCatching { repository.sendOtp(phone.trim(), scene) }
                .onSuccess { emitToast("验证码已发送") }
                .onFailure { emitToast(it.userMessage()) }
        }
    }

    fun register(username: String, password: String, realName: String, phone: String) {
        if (username.isBlank() || password.isBlank()) { emitToast("请输入账号和密码"); return }
        viewModelScope.launch {
            _submitting.value = true
            try {
                val resp = repository.register(username.trim(), password, realName.trim(), phone.trim())
                sessionStore.saveSession(resp.token, resp.user)
                events.send(AuthEvent.LoggedIn)
            } catch (e: Exception) {
                emitToast(e.userMessage())
            } finally {
                _submitting.value = false
            }
        }
    }

    fun resetPassword(phone: String, code: String, newPassword: String) {
        if (phone.isBlank() || code.isBlank() || newPassword.isBlank()) {
            emitToast("请完整填写"); return
        }
        viewModelScope.launch {
            _submitting.value = true
            try {
                repository.resetPassword(phone.trim(), code.trim(), newPassword)
                emitToast("密码已重置，请登录")
                events.send(AuthEvent.PasswordReset)
            } catch (e: Exception) {
                emitToast(e.userMessage())
            } finally {
                _submitting.value = false
            }
        }
    }

    fun switchTenant(tenantId: String) {
        viewModelScope.launch {
            _submitting.value = true
            try {
                val resp = repository.switchTenant(tenantId)
                sessionStore.saveSession(resp.token, resp.user)
                events.send(AuthEvent.LoggedIn)
            } catch (e: Exception) {
                emitToast(e.userMessage())
            } finally {
                _submitting.value = false
            }
        }
    }

    fun refreshMe() {
        if (sessionStore.token == null) return
        viewModelScope.launch {
            runCatching { repository.me() }.onSuccess { sessionStore.updateUser(it) }
        }
    }

    fun logout() {
        sessionStore.clear()
        viewModelScope.launch { events.send(AuthEvent.LoggedOut) }
    }

    private fun emitToast(message: String) {
        viewModelScope.launch { events.send(AuthEvent.Toast(message)) }
    }

    private fun Throwable.userMessage(): String =
        (this as? ApiException)?.message ?: "操作失败，请稍后重试"
}

sealed interface AuthEvent {
    data class Toast(val message: String) : AuthEvent
    data object NeedTenant : AuthEvent
    data object LoggedIn : AuthEvent
    data object LoggedOut : AuthEvent
    data object PasswordReset : AuthEvent
}
