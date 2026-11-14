import webview from '@ohos.web.webview';

/**
 * 富文本渲染：HTML + KaTeX 公式（与 H5 RichContent 对齐）。
 * 使用 Web 组件，按内容高度自适应。
 */
@Component
export struct RichContent {
  content: string = '';
  fontSize: number = 16;
  @State private contentHeight: number = 30;
  private controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Web({ src: '', controller: this.controller })
      .width('100%')
      .height(this.contentHeight)
      .backgroundColor(Color.Transparent)
      .javaScriptAccess(true)
      .domStorageAccess(false)
      .fileAccess(false)
      .onControllerAttached(() => {
        this.controller.loadData(buildDocument(this.content, this.fontSize), 'text/html', 'utf-8');
      })
      .onPageEnd(() => {
        this.controller.runJavaScript('Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)')
          .then((result: string) => {
            const h = Number(result);
            if (h > 0) {
              this.contentHeight = px2vp(h) + 4;
            }
          })
          .catch(() => {});
      })
  }
}

/** 轻量 HTML 转纯文本（用于选项，避免每题多个 Web 组件）。 */
export function htmlToText(html?: string): string {
  if (!html) return '';
  return html
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .trim();
}

function sanitize(raw: string): string {
  const hasHtml = /<[a-z][\s\S]*>/i.test(raw);
  let body = hasHtml ? raw : escapeHtml(raw).replace(/\n/g, '<br>');
  body = body.replace(/<script[\s\S]*?<\/script>/gi, '');
  body = body.replace(/<style[\s\S]*?<\/style>/gi, '');
  body = body.replace(/\son\w+\s*=\s*"[^"]*"/gi, '');
  body = body.replace(/\son\w+\s*=\s*'[^']*'/gi, '');
  body = body.replace(/javascript:/gi, '');
  return body;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildDocument(raw: string, fontSize: number): string {
  const body = sanitize(raw);
  const katex = 'https://cdn.jsdelivr.net/npm/katex@0.16.9/dist';
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link rel="stylesheet" href="${katex}/katex.min.css">
      <style>
        html, body { margin:0; padding:0; background:transparent; }
        body { font-size:${fontSize}px; line-height:1.75; color:#1F2937;
               font-family:-apple-system,BlinkMacSystemFont,'PingFang SC','Microsoft YaHei',sans-serif;
               word-break:break-word; }
        p { margin:0 0 6px; } p:last-child { margin-bottom:0; }
        img { max-width:100%; height:auto; }
        table { border-collapse:collapse; max-width:100%; }
        th, td { border:1px solid #DBE3EC; padding:4px 8px; }
        .katex { font-size:1.02em; }
        .katex-display { margin:8px 0; overflow-x:auto; overflow-y:hidden; }
      </style>
      <script defer src="${katex}/katex.min.js"></script>
      <script defer src="${katex}/contrib/auto-render.min.js"></script>
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
    <body>${body}</body>
    </html>
  `;
}
