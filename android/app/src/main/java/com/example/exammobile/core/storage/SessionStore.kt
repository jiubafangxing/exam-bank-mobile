package com.example.exammobile.core.storage

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.example.exammobile.core.model.AppJson
import com.example.exammobile.core.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID

/**
 * 会话与安全存储。
 * - Token / 用户信息存 EncryptedSharedPreferences（由 Android Keystore 保护）；
 * - 绝不持久化登录密码；
 * - 仅内存 + 加密盘保存会话，禁止备份（见 data_extraction_rules.xml）。
 */
class SessionStore(context: Context) {

    private val prefs: SharedPreferences = createPrefs(context)

    @Volatile
    private var cachedToken: String? = prefs.getString(KEY_TOKEN, null)

    private val _user = MutableStateFlow(readUser())
    val user: StateFlow<User?> = _user.asStateFlow()

    private val _loggedIn = MutableStateFlow(cachedToken != null)
    val loggedIn: StateFlow<Boolean> = _loggedIn.asStateFlow()

    val token: String? get() = cachedToken

    private fun createPrefs(context: Context): SharedPreferences {
        return try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // 极端设备加密不可用时的降级（仍不入备份）；不记录任何敏感值
            context.getSharedPreferences(PREFS_NAME_FALLBACK, Context.MODE_PRIVATE)
        }
    }

    fun saveSession(token: String, user: User) {
        cachedToken = token
        val safeUser = user.copy() // 仅存必要字段
        prefs.edit()
            .putString(KEY_TOKEN, token)
            .putString(KEY_USER, AppJson.encodeToString(User.serializer(), safeUser))
            .apply()
        _user.value = safeUser
        _loggedIn.value = true
    }

    fun updateUser(user: User) {
        prefs.edit().putString(KEY_USER, AppJson.encodeToString(User.serializer(), user)).apply()
        _user.value = user
    }

    fun clear() {
        cachedToken = null
        prefs.edit().remove(KEY_TOKEN).remove(KEY_USER).apply()
        _user.value = null
        _loggedIn.value = false
    }

    fun deviceId(): String {
        val existing = prefs.getString(KEY_DEVICE_ID, null)
        if (!existing.isNullOrBlank()) return existing
        val generated = UUID.randomUUID().toString().replace("-", "")
        prefs.edit().putString(KEY_DEVICE_ID, generated).apply()
        return generated
    }

    private fun readUser(): User? {
        val raw = prefs.getString(KEY_USER, null) ?: return null
        return runCatching { AppJson.decodeFromString(User.serializer(), raw) }.getOrNull()
    }

    private companion object {
        const val PREFS_NAME = "exam_mobile_secure"
        const val PREFS_NAME_FALLBACK = "exam_mobile_secure_fallback"
        const val KEY_TOKEN = "token"
        const val KEY_USER = "user"
        const val KEY_DEVICE_ID = "device_id"
    }
}
