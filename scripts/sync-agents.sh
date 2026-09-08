#!/usr/bin/env bash
#
# sync-agents.sh — skills/ を Antigravity 認識用の .agents/skills/ へ同期する
#
# Antigravity のワークスペース設定ディレクトリ (.agents/skills/) へ
# skills/ の内容を実体コピーで同期します（symlink は不使用）。
#
# 使い方:
#   bash scripts/sync-agents.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# skills/ -> .agents/skills/ の同期
if [ -d "$REPO_ROOT/skills" ]; then
  mkdir -p "$REPO_ROOT/.agents"
  rm -rf "$REPO_ROOT/.agents/skills"
  cp -R "$REPO_ROOT/skills" "$REPO_ROOT/.agents/skills"
  echo "同期完了: skills/ -> .agents/skills/"
else
  echo "警告: skills/ ディレクトリが見つかりませんでした" >&2
  exit 1
fi
