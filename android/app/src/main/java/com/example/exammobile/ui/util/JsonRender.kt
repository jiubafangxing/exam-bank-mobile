package com.example.exammobile.ui.util

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** 未知结构响应的通用可读化渲染（用于成绩、详情等契约未固定的返回）。 */
fun flattenJsonView(element: JsonElement, prefix: String = ""): List<Pair<String, String>> {
    val out = mutableListOf<Pair<String, String>>()
    when (element) {
        is JsonObject -> element.entries.forEach { (k, v) ->
            val key = if (prefix.isBlank()) k else "$prefix.$k"
            if (v is JsonObject || v is JsonArray) out += flattenJsonView(v, key) else out += key to elementText(v)
        }
        is JsonArray -> element.forEachIndexed { i, v ->
            val key = "$prefix[$i]"
            if (v is JsonObject || v is JsonArray) out += flattenJsonView(v, key) else out += key to elementText(v)
        }
        else -> out += (prefix.ifBlank { "内容" }) to elementText(element)
    }
    return out
}

private fun elementText(e: JsonElement): String = when (e) {
    is JsonPrimitive -> e.content
    else -> e.toString()
}
