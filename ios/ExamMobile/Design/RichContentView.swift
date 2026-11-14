import SwiftUI
import WebKit

/// 富文本渲染：HTML + KaTeX 公式（与 H5 RichContent 对齐）。
struct RichText: View {
    let content: String?
    var fontSize: CGFloat = 16
    @State private var height: CGFloat = 24

    var body: some View {
        RichContentView(html: content ?? "", fontSize: fontSize, height: $height)
            .frame(height: max(height, 20))
    }
}

/// 轻量 HTML 文本（用于选项，避免每题多个 WebView）。
struct HtmlText: View {
    let content: String?
    var fontSize: CGFloat = 15
    var color: Color = Tokens.textPrimary

    var body: some View {
        Text(attributed)
            .font(.system(size: fontSize))
            .foregroundColor(color)
    }

    private var attributed: AttributedString {
        let raw = content ?? ""
        guard raw.contains("<"), let data = raw.data(using: .utf8) else {
            return AttributedString(raw)
        }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let ns = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return AttributedString(ns)
        }
        return AttributedString(raw)
    }
}

private struct RichContentView: UIViewRepresentable {
    let html: String
    let fontSize: CGFloat
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(height: $height) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.scrollView.backgroundColor = .clear
        web.scrollView.contentInset = .zero
        web.navigationDelegate = context.coordinator
        context.coordinator.webView = web
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        let doc = buildDocument(html, fontSize: fontSize)
        if context.coordinator.lastDocument != doc {
            context.coordinator.lastDocument = doc
            web.loadHTMLString(doc, baseURL: nil)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var lastDocument: String?
        let height: Binding<CGFloat>

        init(height: Binding<CGFloat>) {
            self.height = height
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            measure()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.measure() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in self?.measure() }
        }

        private func measure() {
            webView?.evaluateJavaScript("Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)") { [weak self] result, _ in
                if let number = result as? NSNumber {
                    let value = CGFloat(truncating: number)
                    DispatchQueue.main.async { self?.height.wrappedValue = value }
                }
            }
        }
    }
}

private func buildDocument(_ raw: String, fontSize: CGFloat) -> String {
    let body = safeBody(raw)
    let katex = "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist"
    return """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link rel="stylesheet" href="\(katex)/katex.min.css">
      <style>
        html, body { margin:0; padding:0; }
        body { font-size:\(Int(fontSize))px; line-height:1.75; color:#1F2937;
               font-family:-apple-system,BlinkMacSystemFont,'PingFang SC','Microsoft YaHei',sans-serif;
               word-break:break-word; -webkit-text-size-adjust:100%; }
        p { margin:0 0 6px; } p:last-child { margin-bottom:0; }
        img { max-width:100%; height:auto; }
        table { border-collapse:collapse; max-width:100%; }
        th, td { border:1px solid #DBE3EC; padding:4px 8px; }
        .katex { font-size:1.02em; }
        .katex-display { margin:8px 0; overflow-x:auto; overflow-y:hidden; }
      </style>
      <script defer src="\(katex)/katex.min.js"></script>
      <script defer src="\(katex)/contrib/auto-render.min.js"></script>
      <script>
        function render() {
          try {
            if (window.renderMathInElement) {
              renderMathInElement(document.body, {
                delimiters: [
                  {left:'$$', right:'$$', display:true},
                  {left:'\\\\[', right:'\\\\]', display:true},
                  {left:'\\\\(', right:'\\\\)', display:false},
                  {left:'$', right:'$', display:false}
                ],
                throwOnError:false
              });
            }
          } catch (e) {}
        }
        document.addEventListener('DOMContentLoaded', render);
        window.addEventListener('load', render);
      </script>
    </head>
    <body>\(body)</body>
    </html>
    """
}

private func safeBody(_ raw: String) -> String {
    let hasHTML = raw.range(of: "<[a-z][\\s\\S]*>", options: .regularExpression) != nil
    var body = hasHTML ? raw : escapeHTML(raw).replacingOccurrences(of: "\n", with: "<br>")
    body = body.replacingOccurrences(of: "(?is)<script.*?</script>", with: "", options: .regularExpression)
    body = body.replacingOccurrences(of: "(?is)<style.*?</style>", with: "", options: .regularExpression)
    body = body.replacingOccurrences(of: "(?i)\\son\\w+\\s*=\\s*\"[^\"]*\"", with: "", options: .regularExpression)
    body = body.replacingOccurrences(of: "(?i)\\son\\w+\\s*=\\s*'[^']*'", with: "", options: .regularExpression)
    body = body.replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
    return body
}

private func escapeHTML(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
}
