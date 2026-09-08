#!/usr/bin/env bash
#
# lib-roles.sh — agents/ 配下の同期対象役割を判定する共通ヘルパー
#
# scripts/sync-agents.sh と scripts/check-standalone.sh の両方から
# `source` して使います。役割探索ロジック（agents/* 走査 → 除外 →
# AGENTS.md 存在チェック）はここに1箇所だけ定義し、両スクリプトは
# list_agent_roles 関数の出力に従ってください。除外対象を増やす場合も
# 本ファイルの EXCLUDE_ROLES だけを直せば両スクリプトに反映されます。
#
# 使い方（呼び出し側）:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib-roles.sh"
#   while IFS= read -r role; do ... ; done < <(list_agent_roles "$REPO_ROOT")

# SDT-tech-lead は frontmatter なしのメイン人格（subagent ではない）ため
# 同期・検査の対象から常に除外する。将来除外対象を増やす場合はここに追記する。
# 注意: この値は agents/ 配下の「開く入口」ディレクトリ名と一致させること。
EXCLUDE_ROLES=(SDT-tech-lead)

# list_agent_roles <REPO_ROOT>
#   agents/<role>/AGENTS.md が存在し、かつ EXCLUDE_ROLES に含まれない role を
#   1行1件で標準出力する。
list_agent_roles() {
  local repo_root="$1"
  local dir role excluded match

  for dir in "$repo_root"/agents/*/; do
    role="$(basename "$dir")"

    excluded=0
    for match in "${EXCLUDE_ROLES[@]}"; do
      if [ "$role" = "$match" ]; then
        excluded=1
        break
      fi
    done
    [ "$excluded" -eq 1 ] && continue

    [ -f "$dir/AGENTS.md" ] || continue

    echo "$role"
  done
}
