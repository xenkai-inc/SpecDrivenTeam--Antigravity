#!/usr/bin/env bash
#
# check-standalone.sh — SpecDrivenTeam の自己完結性チェック
#
# このスターターは、特定の個人・組織の環境（開発者本人のホームディレクトリ・
# 社内の業務システム・特定のタスク管理の仕組みなど）に依存せず、誰でもそのまま
# 使える状態を保つことを目指しています。このスクリプトはその健全性を機械的に
# 確認するためのものです。
#
# 使い方:
#   bash scripts/check-standalone.sh
#
# 対応環境: bash が前提です。Windows をお使いの場合は Git Bash（Git for Windows
# に同梱）で実行してください。
#
# 終了コード: 0 = 問題なし / 1 = 問題あり（詳細は標準出力に列挙されます）

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

source "$REPO_ROOT/scripts/lib-roles.sh"

# SELF_PATH は固定文字列ではなく、このスクリプト自身の実パスから REPO_ROOT
# 相対で導出する（リネーム・移設しても自己除外が追従する）。
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SELF_PATH="${SELF_PATH#"$REPO_ROOT"/}"
FAIL=0

echo "== SpecDrivenTeam 自己完結性チェック =="
echo "対象: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# 1. 環境依存パターンの grep
# ---------------------------------------------------------------------------
#
# 「SpecDrivenCoder」という単語自体は禁止しません。このリポジトリは
# SpecDrivenCoder（単体版）の姉妹プロダクトであり、README・AGENTS.md で
# 製品ラインの説明として言及するのは正当な用途です（例:「単体版との関係」節）。
# 禁止したいのは「特定個人・組織の開発環境そのものへの参照」であり、
# 「単体版という製品名への言及」ではないため、この単語だけは対象パターンから
# 意図的に除外しています。

# 環境依存パターン（拡張正規表現）。それぞれ見つかった時点で環境依存の疑いあり。
PATTERNS=(
  '/Users/masatoshi'
  '~/studio'
  'ai-agents/'
  'vault/'
  '05_tasks'
  'T[0-9]{4}'
  'models\.md'
  'sdd-quality-gate'
  'org-gardener'
  'guards/'
  'judge-rubric'
  'vault-conventions'
  'hermes'
  'eng-director'
  # 'tech-lead' — SpecDrivenTeam の窓口役の正規名称として意図的に採用しているため
  #   denylist から除外（漏洩ではなく製品語彙）。他の engineering 語彙は検出継続。
  'degisense'
  'Discord'
  'masatoshi'
  'endo'
  'xenkai'
  'akakuro'
)

# 検索対象は working tree の全ファイル（git 追跡の有無を問わない）。
# AC-1 は「全ファイルへの grep」であり、git 未追跡（commit 前）のファイルを
# 見落とすと自己完結性チェックとして機能しないため、常に find を使う。
# .git 内部・自分自身（このスクリプト）は対象から除外する（自己除外設計）。
# 注: bash 3.2（macOS 標準）には mapfile が無いため while read で配列を作る。
TARGET_FILES=()
while IFS= read -r line; do
  TARGET_FILES+=("$line")
done < <(find . -type f -not -path './.git/*' | sed 's|^\./||')

HIT_COUNT=0
for pattern in "${PATTERNS[@]}"; do
  for f in "${TARGET_FILES[@]}"; do
    # 自己除外: このスクリプト自身はパターン一覧を含むため対象から外す
    [ "$f" = "$SELF_PATH" ] && continue
    [ -f "$f" ] || continue

    matches=$(grep -InE "$pattern" -- "$f" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      while IFS= read -r line; do
        echo "[環境依存パターン] $f : $line  (pattern: $pattern)"
        HIT_COUNT=$((HIT_COUNT + 1))
      done <<< "$matches"
    fi
  done
done

if [ "$HIT_COUNT" -gt 0 ]; then
  echo ""
  echo "-> $HIT_COUNT 件の環境依存の疑いがある記述が見つかりました。"
  FAIL=1
else
  echo "OK: 環境依存パターンは見つかりませんでした（$HIT_COUNT 件）"
fi
echo ""

# ---------------------------------------------------------------------------
# 1.5 git commit メタデータ（author / committer）の検査
# ---------------------------------------------------------------------------
#
# ファイル内容の grep だけでは、commit の author/committer に刻まれた個人情報
# （氏名・メールアドレス等）を見逃す（今回実際に起きた）。commit メタデータは
# ファイルの中身とは別の場所に記録されるため、専用の検査工程として分離する。

if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  COMMIT_META=$(git -C "$REPO_ROOT" log --all --format='%an|%ae|%cn|%ce' 2>/dev/null || true)

  if [ -n "$COMMIT_META" ]; then
    META_HIT_COUNT=0
    while IFS= read -r meta_line; do
      [ -z "$meta_line" ] && continue
      for pattern in "${PATTERNS[@]}"; do
        if echo "$meta_line" | grep -inE "$pattern" >/dev/null 2>&1; then
          echo "[commit メタデータの環境依存パターン] $meta_line  (pattern: $pattern)"
          META_HIT_COUNT=$((META_HIT_COUNT + 1))
        fi
      done
    done <<< "$COMMIT_META"

    if [ "$META_HIT_COUNT" -gt 0 ]; then
      echo ""
      echo "-> commit の author/committer（氏名・メールアドレス）に $META_HIT_COUNT 件の環境依存の疑いが見つかりました。"
      echo "   ファイルの中身を直しても commit 履歴には残り続けます。squash や履歴の書き換えが必要です。"
      FAIL=1
    else
      echo "OK: commit メタデータ（author/committer）に環境依存パターンは見つかりませんでした"
    fi
  else
    echo "OK: commit 履歴がありません（メタデータ検査は対象なし）"
  fi
else
  echo "SKIP: git リポジトリではないため、commit メタデータの検査をスキップしました"
fi
echo ""

# ---------------------------------------------------------------------------
# 2. symlink 検査（0 件であること）
# ---------------------------------------------------------------------------
#
# サブエージェント定義等はすべて実ファイルで直置きする方針（Windows での
# clone・展開で symlink が壊れることを避けるため）。.git 内部は対象外。

SYMLINKS=()
while IFS= read -r line; do
  SYMLINKS+=("$line")
done < <(find "$REPO_ROOT" -type l -not -path '*/.git/*')

if [ "${#SYMLINKS[@]}" -gt 0 ]; then
  echo "[symlink 検出]"
  for s in "${SYMLINKS[@]}"; do
    echo "  - $s"
  done
  echo "-> symlink は 0 件である必要があります（${#SYMLINKS[@]} 件検出）"
  FAIL=1
else
  echo "OK: symlink は 0 件です"
fi
echo ""

# ---------------------------------------------------------------------------
# 3. launch.json / .env が git 追跡されていないことの確認
# ---------------------------------------------------------------------------
#
# launch.json はローカル起動設定、.env* は秘密情報の置き場のため、
# どちらも git に追跡されていてはならない。

if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TRACKED_SENSITIVE=$(git -C "$REPO_ROOT" ls-files | grep -iE '(^|/)(\.env(\..*)?|launch\.json)$' || true)
  if [ -n "$TRACKED_SENSITIVE" ]; then
    echo "[git 追跡されている機密ファイル]"
    echo "$TRACKED_SENSITIVE" | sed 's/^/  - /'
    echo "-> launch.json / .env 系ファイルは git 追跡されてはいけません"
    FAIL=1
  else
    echo "OK: launch.json / .env 系ファイルは git 追跡されていません"
  fi
else
  echo "SKIP: git リポジトリではないため、追跡ファイルの確認をスキップしました"
fi
echo ""

# ---------------------------------------------------------------------------
# 4. skills/ と .agents/skills/ コピーの同一性検査
# ---------------------------------------------------------------------------
#
# Antigravity が認識する .agents/skills/ は skills/ の生成物（実体コピー）
# である必要がある。scripts/sync-agents.sh の実行漏れや直接編集を検知する。

SKILLS_MISMATCH=0
if [ ! -d "$REPO_ROOT/.agents/skills" ]; then
  echo "[.agents/skills/ 未存在] .agents/skills/ ディレクトリが存在しません"
  SKILLS_MISMATCH=1
elif ! diff -r -q "$REPO_ROOT/skills" "$REPO_ROOT/.agents/skills" >/dev/null 2>&1; then
  echo "[skills/ と .agents/skills/ の不一致]"
  diff -r -q "$REPO_ROOT/skills" "$REPO_ROOT/.agents/skills" | sed 's/^/  /'
  SKILLS_MISMATCH=1
fi

if [ "$SKILLS_MISMATCH" -gt 0 ]; then
  echo ""
  echo "-> skills/ と .agents/skills/ の内容が一致しません。bash scripts/sync-agents.sh を実行してください。"
  FAIL=1
else
  echo "OK: skills/ と .agents/skills/ は一致しています"
fi
echo ""

# ---------------------------------------------------------------------------
# 結果
# ---------------------------------------------------------------------------

if [ "$FAIL" -ne 0 ]; then
  echo "== 結果: 問題が見つかりました（exit 1） =="
  exit 1
else
  echo "== 結果: 問題なし（exit 0） =="
  exit 0
fi
