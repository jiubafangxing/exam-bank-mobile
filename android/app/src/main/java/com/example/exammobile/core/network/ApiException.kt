package com.example.exammobile.core.network

/** 统一业务/网络异常。message 可直接展示给用户（服务端 message 或兜底文案）。 */
class ApiException(
    val code: Int,
    override val message: String,
    val httpStatus: Int = 0,
    cause: Throwable? = null
) : Exception(message, cause) {

    val isUnauthorized: Boolean get() = httpStatus == 401 || code == 401

    companion object {
        fun network(cause: Throwable) = ApiException(-1, "网络异常，请检查网络后重试", 0, cause)
        fun parse(cause: Throwable) = ApiException(-2, "数据解析失败", 0, cause)
        fun business(code: Int, message: String) = ApiException(code, message.ifBlank { "请求失败" })
        fun http(status: Int, message: String) = ApiException(status, message.ifBlank { "请求失败($status)" }, status)
    }
}
