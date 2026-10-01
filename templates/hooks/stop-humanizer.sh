#!/usr/bin/env bash
# Stop hook：檢查這一輪寫入 repo 的繁中 .md 有沒有中文用詞問題。
#
# 規則見 skills/humanizer-research-zhtw/SKILL.md，這裡只做機械可查的部分：
# 壓縮縮略詞、單字詞、內部代號未附說明。斷句與語氣需要判斷，不自動查。
#
# 只報告，不改寫。沒有問題就完全不輸出 —— 每次都說「檢查通過」會讓人
# 開始忽略它。
#
# 只看 git 工作區裡這一輪動過的 .md，不看對話回覆、不看 archive。

set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT" 2>/dev/null || exit 0
command -v git >/dev/null 2>&1 || exit 0

FILES=$(git diff --name-only --diff-filter=ACM HEAD -- '*.md' 2>/dev/null \
        | grep -v 'archive/' | head -40)
[ -z "$FILES" ] && exit 0

# 不要在這裡加 2>/dev/null —— 檢查結果就是寫在 stderr 上的。
# 初版加了，結果 hook 每次都安靜地跑完並回報「沒問題」，實際上是把自己的
# 輸出丟掉了。這是 70-measurement 第 2 條的實例，而且是在寫那條規則的
# 同一天踩到的。
timeout 10 python3 "$ROOT/.claude/hooks/humanizer_check.py" $FILES || exit 0
exit 0
