#!/usr/bin/env bash
# ============================================================================
# inject-config.sh — 把构建期配置（域名等）注入三端本地配置文件
# ----------------------------------------------------------------------------
# 设计目标：**域名等构建配置不进仓库**。
#   - 本地开发：开发者自行 export 环境变量后运行本脚本；
#   - CI：由 GitHub Actions 从 vars/secrets 注入环境变量后调用本脚本。
#
# 用法：
#   API_BASE_URL="https://<host>/api" bash scripts/inject-config.sh
#
# 环境变量：
#   API_BASE_URL          必填，考试端后端地址（不写入仓库，仅写本地忽略文件）
#   API_ALLOW_CLEARTEXT   可选，true/false，仅本地联调用 http 时置 true（默认 false）
#   ANDROID_SDK_DIR       可选，Android SDK 路径（写入 android/local.properties）
#   ANDROID_APP_ID        可选，Android applicationId 覆盖（默认 com.example.exammobile）
#   IOS_BUNDLE_ID         可选，iOS bundleId 覆盖（默认 com.example.exammobile）
#   HARMONY_BUNDLE_NAME   可选，Harmony bundleName 覆盖（默认 com.example.exammobile）
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${API_BASE_URL:?必须设置 API_BASE_URL（不要提交到仓库）}"
ALLOW_CLEARTEXT="${API_ALLOW_CLEARTEXT:-false}"
REGISTRATION_URL="${REGISTRATION_URL:-}"

# 粗略校验：必须是 http(s) URL，避免把占位符注入产物
if ! printf '%s' "$API_BASE_URL" | grep -qE '^https?://[^[:space:]]+$'; then
  echo "✗ API_BASE_URL 非法：$API_BASE_URL" >&2
  exit 1
fi
if printf '%s' "$API_BASE_URL" | grep -qiE '(your[-_]|<[^>]+>|example\.com|placeholder|change[-_]?me)'; then
  echo "✗ API_BASE_URL 仍是占位符：$API_BASE_URL" >&2
  exit 1
fi

# CI/公开仓库日志可能公开可见：默认不打印域名原值，避免 host 落入公开日志
QUIET="${QUIET:-${CI:-0}}"
if [[ "$QUIET" == "1" || "$QUIET" == "true" ]]; then
  echo "→ 注入构建配置（CI 模式，隐藏域名原值）"
  echo "  API_ALLOW_CLEARTEXT=$ALLOW_CLEARTEXT"
else
  echo "→ 注入配置（值不会入库）："
  echo "  API_BASE_URL=<redacted>"
  echo "  API_ALLOW_CLEARTEXT=$ALLOW_CLEARTEXT"
fi

# ---------- Android：local.properties ----------
ANDROID_LOCAL="$ROOT/android/local.properties"
SDK_LINE=""
if [[ -n "${ANDROID_SDK_DIR:-}" ]]; then SDK_LINE="sdk.dir=$ANDROID_SDK_DIR"; fi
cat > "$ANDROID_LOCAL" <<EOF
# 本地生成，勿提交（.gitignore 已忽略）
$SDK_LINE
apiBaseUrl=$API_BASE_URL
apiAllowCleartext=$ALLOW_CLEARTEXT
androidAppId=${ANDROID_APP_ID:-com.example.exammobile}
registrationUrl=$REGISTRATION_URL
EOF
echo "  ✓ android/local.properties"

# ---------- iOS：Configs/Secrets.xcconfig ----------
# xcconfig 中 "//" 会被当成注释，URL 必须转义为 /$()/
IOS_SECRETS="$ROOT/ios/Configs/Secrets.xcconfig"
IOS_URL_ESCAPED=$(printf '%s' "$API_BASE_URL" | sed 's#//#/$()/#g')
IOS_REG_ESCAPED=$(printf '%s' "$REGISTRATION_URL" | sed 's#//#/$()/#g')
cat > "$IOS_SECRETS" <<EOF
// 本地生成，勿提交（.gitignore 已忽略）
API_BASE_URL = $IOS_URL_ESCAPED
API_ALLOW_CLEARTEXT = $ALLOW_CLEARTEXT
IOS_BUNDLE_ID = ${IOS_BUNDLE_ID:-com.example.exammobile}
REGISTRATION_URL = $IOS_REG_ESCAPED
EOF
echo "  ✓ ios/Configs/Secrets.xcconfig"

# ---------- Harmony：local.properties + BuildProfile 常量 ----------
HARMONY_LOCAL="$ROOT/harmony/local.properties"
cat > "$HARMONY_LOCAL" <<EOF
# 本地生成，勿提交（.gitignore 已忽略）
apiBaseUrl=$API_BASE_URL
apiAllowCleartext=$ALLOW_CLEARTEXT
harmonyBundleName=${HARMONY_BUNDLE_NAME:-com.example.exammobile}
EOF
# HarmonyOS 通过 build-profile 的 buildOption.buildProfileFields 注入编译期常量
HARMONY_GENERATED="$ROOT/harmony/entry/src/main/ets/common/config/GeneratedConfig.ets"
mkdir -p "$(dirname "$HARMONY_GENERATED")"
cat > "$HARMONY_GENERATED" <<EOF
// 由 scripts/inject-config.sh 生成（.gitignore 已忽略）。请勿手改、勿提交。
export class GeneratedConfig {
  static readonly API_BASE_URL: string = '${API_BASE_URL}';
  static readonly API_ALLOW_CLEARTEXT: boolean = ${ALLOW_CLEARTEXT};
  static readonly REGISTRATION_URL: string = '${REGISTRATION_URL}';
}
EOF
echo "  ✓ harmony/local.properties"
echo "  ✓ harmony/entry/src/main/ets/common/config/GeneratedConfig.ets"

echo "✓ 配置注入完成。"
