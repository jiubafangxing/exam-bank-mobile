#!/usr/bin/env bash
# 安装仓库级 Git hooks（密钥扫描）。
# 每个克隆执行一次：bash scripts/install-git-hooks.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
git -C "$ROOT" config core.hooksPath .githooks
chmod +x "$ROOT/.githooks/pre-commit" "$ROOT/scripts/scan-secrets.sh"
echo "✓ 已启用 .githooks（pre-commit 密钥扫描）"
