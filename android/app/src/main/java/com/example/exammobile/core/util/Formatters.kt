package com.example.exammobile.core.util

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

object Formatters {

    private val dateTimeFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")
        .withZone(ZoneId.systemDefault())

    private val dateFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        .withZone(ZoneId.systemDefault())

    fun epochToDateTime(epochMillis: String?): String {
        val millis = epochMillis?.toLongOrNull() ?: return ""
        if (millis <= 0) return ""
        return runCatching { dateTimeFmt.format(Instant.ofEpochMilli(millis)) }.getOrDefault("")
    }

    fun epochToDate(epochMillis: String?): String {
        val millis = epochMillis?.toLongOrNull() ?: return ""
        if (millis <= 0) return ""
        return runCatching { dateFmt.format(Instant.ofEpochMilli(millis)) }.getOrDefault("")
    }

    /** durationSeconds -> HH:mm:ss（隐藏 0 小时） */
    fun countdown(remainingSeconds: Int): String {
        val total = remainingSeconds.coerceAtLeast(0)
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return if (h > 0) "%02d:%02d:%02d".format(h, m, s) else "%02d:%02d".format(m, s)
    }

    fun durationText(seconds: Int): String {
        if (seconds <= 0) return "不限时"
        val m = seconds / 60
        return if (m >= 60) "${m / 60}小时${m % 60}分" else "${m}分钟"
    }

    fun scoreText(value: Double?): String {
        if (value == null) return "-"
        return if (value % 1.0 == 0.0) value.toInt().toString() else "%.1f".format(value)
    }

    fun questionTypeLabel(type: String): String = when (type.uppercase()) {
        "SINGLE" -> "单选题"
        "MULTIPLE" -> "多选题"
        "JUDGE" -> "判断题"
        "FILL" -> "填空题"
        "ESSAY" -> "问答题"
        else -> type
    }

    fun attemptStatusLabel(status: String): String = when (status.uppercase()) {
        "ASSIGNED" -> "待开始"
        "STARTED", "IN_PROGRESS" -> "进行中"
        "SUBMITTED" -> "已交卷"
        "GRADING" -> "阅卷中"
        "GRADED" -> "已出分"
        "EXPIRED" -> "已过期"
        "ABSENT" -> "缺考"
        else -> status
    }

    fun examStatusLabel(status: String): String = when (status.uppercase()) {
        "DRAFT" -> "草稿"
        "PUBLISHED" -> "已发布"
        "ONGOING" -> "进行中"
        "FINISHED" -> "已结束"
        "CANCELLED" -> "已取消"
        else -> status
    }

    fun orderStatusLabel(status: String): String = when (status.uppercase()) {
        "UNPAID", "PENDING", "CREATED" -> "待支付"
        "PAID", "SUCCESS" -> "已支付"
        "CANCELLED", "CANCELED" -> "已取消"
        "CLOSED" -> "已关闭"
        "REFUNDED" -> "已退款"
        else -> status
    }

    fun greeting(hour: Int): String = when (hour) {
        in 5..10 -> "早上好"
        in 11..12 -> "中午好"
        in 13..17 -> "下午好"
        in 18..22 -> "晚上好"
        else -> "你好"
    }
}
