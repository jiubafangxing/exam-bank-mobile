#!/usr/bin/env bash
# ============================================================================
# scan-secrets.sh — 提交前/CI 密钥扫描
# 用法：
#   bash scripts/scan-secrets.sh            # 扫描暂存区（pre-commit 默认）
#   bash scripts/scan-secrets.sh --all      # 扫描工作区全部可提交文本
#   bash scripts/scan-secrets.sh --staged   # 显式扫描暂存区
# 命中即返回非 0，用于阻断提交。
# ============================================================================
set -uo pipefail

MODE="--staged"
if [[ "${1:-}" == "--all" ]]; then MODE="--all"; fi
if [[ "${1:-}" == "--staged" ]]; then MODE="--staged"; fi

RED=$'\033[31m'; YEL=$'\033[33m'; GRN=$'\033[32m'; RST=$'\033[0m'

# 只检查文本文件，跳过二进制/构建产物/第三方依赖
is_text() {
  case "$1" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.pdf|*.zip|*.jar|*.aar|*.so|*.a|*.dylib|\
    *.ttf|*.otf|*.woff|*.woff2|*.mp3|*.mp4|*.wav|*.bin|*.class|*.dex|*.apk|*.ipa|*.hap|*.har|\
    *.p12|*.jks|*.keystore|*.cer|*.der) return 1 ;;
    */build/*|*/.gradle/*|*/node_modules/*|*/oh_modules/*|*/Pods/*|*/DerivedData/*|*/.git/*) return 1 ;;
  esac
  return 0
}

files_to_scan() {
  if [[ "$MODE" == "--all" ]]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git ls-files -z 2>/dev/null | tr '\0' '\n'
    else
      # 未初始化 git 时也能全量扫描（提交前自检）
      find . -type f -not -path './.git/*' 2>/dev/null | sed 's#^\./##'
    fi
  else
    git diff --cached --name-only --diff-filter=ACM 2>/dev/null
  fi
}

# ---- 结构化模式（明显的高危字面量）----
PATTERNS=(
  '-----BEGIN (RSA|EC|OPENSSH|DSA|PGP) PRIVATE KEY-----'
  '(aws_access_key_id|aws_secret_access_key|AWS_SECRET_ACCESS_KEY)[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
  '(AKIA|ASIA)[0-9A-Z]{16}'
  'sk-[A-Za-z0-9]{20,}'
  'ghp_[A-Za-z0-9]{20,}'
  'gho_[A-Za-z0-9]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'AIza[0-9A-Za-z_-]{20,}'
  'glpat-[A-Za-z0-9_-]{20,}'
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
  'jdbc:[a-z0-9]+://[^[:space:]]*password=[^[:space:]]+'
  '(password|passwd|pwd|secret|api[_-]?key|apikey|access[_-]?key|private[_-]?key|client[_-]?secret|token)[[:space:]]*[=:][[:space:]]*["'"'"'][^"'"'"']{8,}["'"'"']'
)

hits=0
declare -a REPORT

scan_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  is_text "$f" || return 0
  # 跳过模板与策略文档（它们本身就演示了模式/占位）
  case "$f" in
    *.example|*.example.*|SECURITY.md|AGENTS.md|scripts/scan-secrets.sh|.githooks/pre-commit) return 0 ;;
    docs/*) return 0 ;;
  esac

  # 1) 模式匹配
  local pat line
  for pat in "${PATTERNS[@]}"; do
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      # 忽略明显的占位/示例值
      if echo "$line" | grep -qiE '(example|placeholder|your[-_]|<[^>]+>|xxxx|change[-_]?me|dummy|sample|test|localhost|127\.0\.0\.1|api\.example)'; then
        continue
      fi
      hits=$((hits+1))
      REPORT+=("${RED}[高危]${RST} $f :: $(echo "$line" | cut -c1-160)")
    done < <(grep -nE "$pat" "$f" 2>/dev/null)
  done

  # 2) 高熵串（长度 >= 32 的 base64/hex 风格随机串）
  while IFS= read -r line; do
    local tok
    tok=$(echo "$line" | grep -oE '[A-Za-z0-9+/_-]{32,}' | head -n1)
    [[ -z "$tok" ]] && continue
    echo "$tok" | grep -qiE '(example|placeholder|abcdef|123456|your|xxxx|sample|dummy)' && continue
    # 跳过文件路径（含多个 "/" 或已知目录），避免把构建产物路径误判为高熵密钥
    if [[ "$tok" == */* ]]; then
      local slash_count
      slash_count=$(printf '%s' "$tok" | tr -cd '/' | wc -c | tr -d ' ')
      if [[ "$slash_count" -ge 2 ]]; then continue; fi
      case "$tok" in
        build/*|dist/*|android/*|ios/*|harmony/*|scripts/*|docs/*|shared/*|*/Products/*|*.app|*.hap|*.apk) continue ;;
      esac
    fi
    # 估算熵：唯一字符比例 + 字符类别
    local score
    score=$(printf '%s' "$tok" | awk '{n=length($0); split("",s); for(i=1;i<=n;i++){c=substr($0,i,1); s[c]=1} u=0; for(k in s) u++; print (u/n>=0.5 && n>=40)?"1":"0"}')
    if [[ "$score" == "1" ]]; then
      hits=$((hits+1))
      REPORT+=("${YEL}[高熵]${RST} $f :: $(echo "$tok" | cut -c1-60)…")
    fi
  done < <(grep -nE '[A-Za-z0-9+/_-]{40,}' "$f" 2>/dev/null)
}

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  scan_file "$f"
done < <(files_to_scan)

if [[ $hits -gt 0 ]]; then
  echo "${RED}✗ 检测到 $hits 处疑似密钥/凭证，已阻断。${RST}"
  printf '%s\n' "${REPORT[@]}" | sort -u
  echo
  echo "${YEL}处理建议：${RST}"
  echo "  1) 若为误报：把该行改为读取本地配置或加入 scripts/scan-secrets.sh 白名单；"
  echo "  2) 若为真实值：立即从代码移除、写入本地不入库文件，并在服务端轮换。"
  echo "  参考 SECURITY.md。"
  exit 1
fi

echo "${GRN}✓ 未发现疑似密钥/凭证。${RST}"
exit 0
