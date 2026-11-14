package com.example.exammobile.ui.util

import android.content.Context
import android.widget.Toast
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import com.example.exammobile.core.network.ApiException
import com.example.exammobile.core.util.UiState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/** 轻量远程数据控制器：加载/成功/失败 + 重试，供简单页面复用。 */
class RemoteController<T>(
    private val scope: CoroutineScope,
    private val loader: suspend () -> T
) {
    var state: UiState<T> by mutableStateOf(UiState.Loading)
        private set

    fun reload() {
        scope.launch {
            state = UiState.Loading
            state = try {
                UiState.Success(loader())
            } catch (e: Exception) {
                UiState.Error((e as? ApiException)?.message ?: "加载失败，请稍后重试")
            }
        }
    }
}

@Composable
fun <T> rememberRemote(key: Any? = Unit, loader: suspend () -> T): RemoteController<T> {
    val scope = rememberCoroutineScope()
    val controller = remember(key) { RemoteController(scope, loader) }
    LaunchedEffect(key) { controller.reload() }
    return controller
}

fun Context.toast(message: String) {
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
}

fun Throwable.userMessage(): String =
    (this as? ApiException)?.message ?: "操作失败，请稍后重试"
