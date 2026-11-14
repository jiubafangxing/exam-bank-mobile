package com.example.exammobile.core.network

import com.example.exammobile.core.config.AppConfig
import com.example.exammobile.core.model.AppJson
import com.example.exammobile.core.storage.SessionStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.logging.HttpLoggingInterceptor
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * 统一网络客户端：
 * - baseUrl + Bearer + X-Client-Type
 * - 信封 {code,message,data} 解包；兼容裸对象/裸数组
 * - 401 触发 onUnauthorized
 * - 日志脱敏（不输出 Authorization / password / token）
 */
class ApiClient(
    private val sessionStore: SessionStore,
    private val onUnauthorized: () -> Unit
) {
    private val jsonMedia = "application/json; charset=utf-8".toMediaType()

    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(AppConfig.CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(AppConfig.READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .addInterceptor { chain ->
            val builder = chain.request().newBuilder()
                .header("Accept", "application/json")
                .header("X-Client-Type", AppConfig.clientType)
            sessionStore.token?.let { builder.header("Authorization", "Bearer $it") }
            chain.proceed(builder.build())
        }
        .apply {
            if (AppConfig.enableLog) {
                addInterceptor(HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC })
            }
        }
        .build()

    suspend fun get(path: String, query: Map<String, String?> = emptyMap()): JsonElement =
        execute("GET", path, query, null, emptyMap())

    suspend fun post(path: String, body: String? = null, headers: Map<String, String> = emptyMap()): JsonElement =
        execute("POST", path, emptyMap(), body, headers)

    suspend fun put(path: String, body: String? = null): JsonElement =
        execute("PUT", path, emptyMap(), body, emptyMap())

    suspend fun delete(path: String, query: Map<String, String?> = emptyMap()): JsonElement =
        execute("DELETE", path, query, null, emptyMap())

    suspend fun postMultipart(path: String, file: File, fieldName: String = "file"): JsonElement = withContext(Dispatchers.IO) {
        val url = (AppConfig.apiBaseUrl + path).toHttpUrlOrNull()
            ?: throw ApiException.business(-3, "服务地址配置无效")
        val mime = if (file.extension.lowercase() == "png") "image/png" else "image/jpeg"
        val form = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart(fieldName, file.name, file.asRequestBody(mime.toMediaType()))
            .build()
        val builder = Request.Builder()
            .url(url)
            .header("Accept", "application/json")
            .header("X-Client-Type", AppConfig.clientType)
            .post(form)
        sessionStore.token?.let { builder.header("Authorization", "Bearer $it") }
        val response = try {
            client.newCall(builder.build()).execute()
        } catch (e: IOException) {
            throw ApiException.network(e)
        }
        response.use { resp ->
            val raw = resp.body?.string().orEmpty()
            if (resp.code == 401) {
                sessionStore.clear()
                onUnauthorized()
                throw ApiException.http(401, "登录已过期，请重新登录")
            }
            if (!resp.isSuccessful) throw ApiException.http(resp.code, "上传失败(${resp.code})")
            unwrap(raw)
        }
    }

    private suspend fun execute(
        method: String,
        path: String,
        query: Map<String, String?>,
        body: String?,
        headers: Map<String, String>
    ): JsonElement = withContext(Dispatchers.IO) {
        val base = AppConfig.apiBaseUrl
        val url = (base + path).toHttpUrlOrNull()?.newBuilder()?.apply {
            query.forEach { (k, v) -> if (v != null) addQueryParameter(k, v) }
        }?.build() ?: throw ApiException.business(-3, "服务地址配置无效")

        val requestBuilder = Request.Builder().url(url)
        headers.forEach { (k, v) -> requestBuilder.header(k, v) }
        val requestBody = body?.toRequestBody(jsonMedia)
        requestBuilder.method(method, requestBody)

        val response = try {
            client.newCall(requestBuilder.build()).execute()
        } catch (e: IOException) {
            throw ApiException.network(e)
        }

        response.use { resp ->
            val raw = resp.body?.string().orEmpty()
            if (resp.code == 401) {
                sessionStore.clear()
                onUnauthorized()
                throw ApiException.http(401, "登录已过期，请重新登录")
            }
            if (!resp.isSuccessful) {
                val msg = runCatching {
                    AppJson.parseToJsonElement(raw).asEnvelopeMessage()
                }.getOrNull()
                throw ApiException.http(resp.code, msg ?: "请求失败(${resp.code})")
            }
            unwrap(raw)
        }
    }

    private fun unwrap(raw: String): JsonElement {
        if (raw.isBlank()) return JsonNull
        val element = try {
            AppJson.parseToJsonElement(raw)
        } catch (e: Exception) {
            throw ApiException.parse(e)
        }
        return when (element) {
            is JsonObject -> {
                val codeEl = element["code"]
                if (codeEl != null) {
                    val code = codeEl.jsonPrimitive.content.toIntOrNull() ?: 0
                    if (code != 0) {
                        val message = element["message"]?.jsonPrimitive?.content ?: "请求失败"
                        throw ApiException.business(code, message)
                    }
                    element["data"] ?: JsonNull
                } else {
                    element
                }
            }
            is JsonArray -> element
            else -> element
        }
    }

    private fun JsonElement.asEnvelopeMessage(): String? = when (this) {
        is JsonObject -> (this["message"] ?: this["msg"])?.jsonPrimitive?.content
        else -> null
    }
}
