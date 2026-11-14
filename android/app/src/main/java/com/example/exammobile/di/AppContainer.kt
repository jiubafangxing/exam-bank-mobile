package com.example.exammobile.di

import android.content.Context
import com.example.exammobile.core.network.ApiClient
import com.example.exammobile.core.storage.SessionStore
import com.example.exammobile.data.CandidateRepository
import kotlinx.coroutines.flow.MutableSharedFlow

/**
 * 手动依赖注入容器。会话失效事件通过 unauthorizedEvents 通知导航层跳登录。
 */
class AppContainer(context: Context) {

    val unauthorizedEvents = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    val sessionStore: SessionStore = SessionStore(context.applicationContext)

    val apiClient: ApiClient = ApiClient(sessionStore) {
        unauthorizedEvents.tryEmit(Unit)
    }

    val repository: CandidateRepository = CandidateRepository(apiClient)
}
