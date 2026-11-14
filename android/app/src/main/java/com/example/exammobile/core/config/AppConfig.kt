package com.example.exammobile.core.config

import com.example.exammobile.BuildConfig

/**
 * 构建期注入的运行配置。
 * 域名由 scripts/inject-config.sh 在构建前写入 local.properties（不入库），
 * 再经 Gradle buildConfigField 注入，源码中不出现真实域名。
 */
object AppConfig {
    val apiBaseUrl: String = BuildConfig.API_BASE_URL.trimEnd('/')
    val allowCleartext: Boolean = BuildConfig.API_ALLOW_CLEARTEXT
    val clientType: String = BuildConfig.CLIENT_TYPE
    val registrationUrl: String = BuildConfig.REGISTRATION_URL
    val enableLog: Boolean = BuildConfig.ENABLE_LOG

    const val CONNECT_TIMEOUT_SECONDS = 20L
    const val READ_TIMEOUT_SECONDS = 30L

    // 作答状态机参数（与三端一致）
    const val DEBOUNCE_SAVE_MS = 500L
    const val HEARTBEAT_INTERVAL_MS = 30_000L
    const val EVENT_THROTTLE_MS = 1_000L
}
