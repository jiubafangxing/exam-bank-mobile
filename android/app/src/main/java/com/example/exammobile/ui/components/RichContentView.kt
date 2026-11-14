package com.example.exammobile.ui.components

import android.annotation.SuppressLint
import android.os.Handler
import android.os.Looper
import android.graphics.Color as AndroidColor
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.example.exammobile.ui.theme.Tokens

/**
 * 富文本渲染：HTML + KaTeX 公式（与 H5 RichContent 对齐）。
 * KaTeX 资源走公共 CDN；内容来自可信后台，仍做基础脚本/事件属性清洗。
 */
@SuppressLint("SetJavaScriptEnabled", "JavascriptInterface")
@Composable
fun RichContentView(
    html: String?,
    modifier: Modifier = Modifier,
    fontSizeSp: Int = 16
) {
    val raw = html ?: ""
    val body = remember(raw) { toSafeBody(raw) }
    val document = remember(body, fontSizeSp) { buildDocument(body, fontSizeSp) }
    var heightPx by remember { mutableIntStateOf(0) }
    val density = LocalDensity.current

    AndroidView(
        factory = { context ->
            WebView(context).apply {
                settings.javaScriptEnabled = true
                settings.allowFileAccess = false
                settings.allowContentAccess = false
                settings.domStorageEnabled = false
                settings.builtInZoomControls = false
                settings.displayZoomControls = false
                settings.loadWithOverviewMode = false
                settings.useWideViewPort = false
                isVerticalScrollBarEnabled = false
                isHorizontalScrollBarEnabled = false
                setBackgroundColor(AndroidColor.TRANSPARENT)
                webViewClient = object : WebViewClient() {
                    override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean = true
                }
                val mainHandler = Handler(Looper.getMainLooper())
                addJavascriptInterface(object {
                    @JavascriptInterface
                    fun onHeight(height: Int) {
                        if (height > 0) mainHandler.post { heightPx = height }
                    }
                }, "AndroidHeight")
                setOnTouchListener { _, _ -> false }
            }
        },
        update = { web ->
            if (web.tag != document) {
                web.tag = document
                web.loadDataWithBaseURL(null, document, "text/html", "utf-8", null)
            }
        },
        modifier = modifier
            .fillMaxWidth()
            .height(if (heightPx > 0) with(density) { heightPx.toDp() } else 1.dp)
    )

    if (heightPx == 0) {
        // 兜底：WebView 尚未完成测量前，先用纯文本占位避免空白
        Text(plainText(raw), color = Tokens.TextPrimary, fontSize = 15.sp)
    }
}

/** 轻量 HTML 文本（用于选项等不需要公式的场景，避免每题多个 WebView）。 */
@Composable
fun HtmlText(
    html: String?,
    modifier: Modifier = Modifier,
    color: Color = Tokens.TextPrimary,
    fontSizeSp: Int = 15
) {
    val raw = html ?: ""
    val hasHtml = remember(raw) {
        Regex("<[a-z][\\s\\S]*>", RegexOption.IGNORE_CASE).containsMatchIn(raw)
    }
    AndroidView(
        factory = { context ->
            android.widget.TextView(context).apply {
                setBackgroundColor(AndroidColor.TRANSPARENT)
                setTextColor(color.toArgb())
                setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, fontSizeSp.toFloat())
                setLineSpacing(0f, 1.15f)
                includeFontPadding = false
            }
        },
        update = { tv ->
            tv.setTextColor(color.toArgb())
            tv.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, fontSizeSp.toFloat())
            tv.text = if (hasHtml) {
                android.text.Html.fromHtml(raw, android.text.Html.FROM_HTML_MODE_LEGACY)
            } else {
                raw
            }
        },
        modifier = modifier
    )
}

private fun buildDocument(body: String, fontSizeSp: Int): String {
    val katex = "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist"
    return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <link rel="stylesheet" href="$katex/katex.min.css">
          <style>
            html, body { margin:0; padding:0; }
            body { font-size:${fontSizeSp}px; line-height:1.75; color:#1F2937;
                   font-family:-apple-system,BlinkMacSystemFont,'PingFang SC','Microsoft YaHei',sans-serif;
                   word-break:break-word; }
            p { margin:0 0 6px; } p:last-child { margin-bottom:0; }
            img { max-width:100%; height:auto; }
            table { border-collapse:collapse; max-width:100%; }
            th, td { border:1px solid #DBE3EC; padding:4px 8px; }
            .katex { font-size:1.02em; }
            .katex-display { margin:8px 0; overflow-x:auto; overflow-y:hidden; }
          </style>
          <script defer src="$katex/katex.min.js"></script>
          <script defer src="$katex/contrib/auto-render.min.js"></script>
          <script>
            function reportHeight() {
              try {
                var h = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight);
                if (window.AndroidHeight) { AndroidHeight.onHeight(h); }
              } catch (e) {}
            }
            function render() {
              try {
                if (window.renderMathInElement) {
                  renderMathInElement(document.body, {
                    delimiters: [
                      {left:'$$', right:'$$', display:true},
                      {left:'\\[', right:'\\]', display:true},
                      {left:'\\(', right:'\\)', display:false},
                      {left:'$', right:'$', display:false}
                    ],
                    throwOnError:false
                  });
                }
              } catch (e) {}
              reportHeight();
            }
            document.addEventListener('DOMContentLoaded', function(){ render(); setTimeout(reportHeight,300); setTimeout(reportHeight,1000); });
            window.addEventListener('load', function(){ render(); setTimeout(reportHeight,200); });
          </script>
        </head>
        <body>$body</body>
        </html>
    """.trimIndent()
}

private fun toSafeBody(raw: String): String {
    val hasHtml = Regex("<[a-z][\\s\\S]*>", RegexOption.IGNORE_CASE).containsMatchIn(raw)
    var body = if (hasHtml) raw else escapeHtml(raw).replace("\n", "<br>")
    body = Regex("(?is)<script.*?</script>").replace(body, "")
    body = Regex("(?is)<style.*?</style>").replace(body, "")
    body = Regex("(?i)\\son\\w+\\s*=\\s*\"[^\"]*\"").replace(body, "")
    body = Regex("(?i)\\son\\w+\\s*=\\s*'[^']*'").replace(body, "")
    body = body.replace("javascript:", "", ignoreCase = true)
    return body
}

private fun escapeHtml(value: String): String = value
    .replace("&", "&amp;")
    .replace("<", "&lt;")
    .replace(">", "&gt;")
    .replace("\"", "&quot;")

private fun plainText(raw: String): String =
    raw.replace(Regex("(?is)<[^>]+>"), "")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&amp;", "&")
        .replace("&quot;", "\"")
        .trim()
