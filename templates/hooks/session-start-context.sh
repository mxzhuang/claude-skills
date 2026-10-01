#!/usr/bin/env bash
# SessionStart：把知識層的常駐區注入 context。
#
# 這是模板。複製到專案的 .claude/hooks/ 之後可直接用，不需要改 —— 除非
# 你的 .context/ 結構不同。
#
# ============================================================================
# 這支腳本的形狀是繳過學費換來的。改之前先讀完這一段。
# ============================================================================
#
# 一、分段時間預算：因為被砍是全失，不是降級
#
#   SessionStart 有硬性 15 秒上限。超過就整支被砍，attachment 型別是
#   hook_cancelled，**一個字都不會進 context**。
#
#   最糟的是 CC 不會察覺注入失敗。它會改用 CLAUDE.md 與 rules 推斷，
#   產出一套理由鏈完整、看起來可信、但內容過期的答案，並附上行動建議。
#   除非有獨立驗證，這個答案會被採信。
#
#   所以：必要段不設 timeout 先送出，選配段各自包 timeout，逾時就略過
#   並在輸出裡註明。另有總預算，超過就把已備好的內容立刻送出並結束 ——
#   **自己收尾是降級，被系統砍是全失。**
#
#   實際踩過的坑：某個「顯示鎖定狀態」的輔助腳本用 `find .` 掃全 repo，
#   在 NFS 上要 21 秒。一個純顯示功能就這樣擋掉了整個知識層注入。
#   **選配段只讀預先算好的快取檔，不要在 hook 裡呼叫任何會遍歷檔案系統的東西。**
#
# 二、nonce：因為注入是否成立不能靠模型自述
#
#   注入對使用者靜默，看不到就不知道有沒有成功。而問模型「你有沒有收到」
#   是循環論證 —— 它的自述正是待驗證的東西。靠回答品質判斷也不行，
#   失敗模式就是「答案照樣產出且品質看似正常」。
#
#   所以每次執行產生一次性 nonce，同時寫進注入內容與 log。事後在 session
#   的 jsonl 裡找 type=hook_additional_context 且含該 nonce 的條目：
#
#     grep -c "<nonce>" ~/.claude/projects/<proj>/<session-id>.jsonl
#
#   為什麼是 nonce 不是固定字串：手動跑 hook 驗證時，內容會被印進工具輸出，
#   「驗證痕跡」與「正常工作痕跡」就混在一起，字串比對失去鑑別力。
#   nonce 每次不同且不可能從 repo 讀到 —— 能引用它就只可能來自注入。
#
# 三、輸出格式
#
#   純文字 stdout 對 SessionStart 本來就會送達，JSON 信封不是必要的。
#   這裡用 JSON 是為了將來要加 sessionTitle / reloadSkills 時不用改結構。
#   兩種都可以，不要因為注入失敗就先去改格式 —— 先查是不是逾時。
# ============================================================================

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CTX="$ROOT/.context"
MARKER='<!-- HOOK_INJECT_END -->'
MAX_BYTES=2000
LOG="$ROOT/.claude/hook-fired.log"
LOG_KEEP=200

BUDGET_MS=10000
START_NS=$(date +%s%N)
elapsed_ms() { echo $(( ($(date +%s%N) - START_NS) / 1000000 )); }
over_budget() { [ "$(elapsed_ms)" -gt "$BUDGET_MS" ]; }

NONCE="$(date -Is)-$(head -c 4 /dev/urandom 2>/dev/null | od -An -tx1 | tr -d ' \n' || echo 'nourandom')"
{
  printf '%s pid=%s ROOT=%s\n' "$(date -Is)" "$$" "$ROOT"
  printf 'HOOK-NONCE: %s\n' "$NONCE"
  timeout 2 cat || echo '(stdin 無資料或逾時)'
} >> "$LOG" 2>/dev/null
if [ -w "$LOG" ]; then
  tail -n "$LOG_KEEP" "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG" 2>/dev/null
  rm -f "$LOG.tmp" 2>/dev/null
fi

[ -d "$CTX" ] || exit 0

build_payload() {
  # nonce 放第一行而非結尾：從尾端截斷時標記還在，截斷過的注入仍驗得出來。
  echo "HOOK-NONCE: $NONCE"
  echo

  # --- 必要段：常駐區。不設 timeout —— 它只花數毫秒，讀不到才是真問題。
  local FOCUS="$CTX/current-focus.md"
  if [ -r "$FOCUS" ]; then
    local resident size truncated=0
    if grep -qF "$MARKER" "$FOCUS"; then
      resident=$(sed "/$(printf '%s' "$MARKER" | sed 's/[][\.*^$/]/\\&/g')/q" "$FOCUS" \
                 | grep -vF "$MARKER")
    else
      resident=$(cat "$FOCUS")
      echo "[WARN] current-focus.md 找不到 $MARKER，退回全文注入。"
    fi
    size=$(printf '%s' "$resident" | wc -c)
    if [ "$size" -gt "$MAX_BYTES" ]; then
      resident=$(printf '%s' "$resident" | head -c "$MAX_BYTES"); truncated=1
    fi
    echo "===== .context/current-focus.md（常駐區）====="
    printf '%s\n' "$resident"
    [ "$truncated" -eq 1 ] && {
      echo "…（已截斷）"
      echo "[WARN] 常駐區超過上限（${size} > ${MAX_BYTES} bytes），請精簡"
    }
    echo "===== end（其餘見標記之後的按需區）====="
    echo
  fi

  # --- 選配段：檔案索引。2 秒預算，逾時略過。
  if over_budget; then
    echo "[hook] 總預算用盡，檔案索引已略過"
    return 0
  fi
  local index
  if index=$(timeout 2 bash -c '
      CTX="$1"
      find "$CTX" -maxdepth 2 -type f -name "*.md" -not -path "*/log/*" \
           -not -path "*/archive/*" 2>/dev/null \
        | sed "s|^$CTX/||" | sort | while read -r f; do
            printf "  %-26s %s 行\n" "$f" "$(wc -l < "$CTX/$f")"
          done
    ' _ "$CTX"); then
    echo "===== .context/ 可讀檔案（按需自行讀取）====="
    printf '%s\n' "$index"
    echo "===== end index ====="
  else
    echo "[hook] .context 檔案索引逾時，已略過（檔案仍可直接讀取）"
  fi

  # --- 這裡加你自己的選配段。每一段都要：
  #       1. 先 over_budget 檢查
  #       2. 實際工作包在 timeout 裡
  #       3. 逾時輸出一行說明，不要靜默略過
  #     絕對不要在這裡呼叫會遍歷檔案系統的東西。
}

PAYLOAD=$(build_payload)

printf '%s' "$PAYLOAD" | python3 -c '
import json, sys
json.dump({"hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": sys.stdin.read(),
}}, sys.stdout, ensure_ascii=False)
' 2>/dev/null || {
  echo "[hook] JSON 包裝失敗，退回純文字輸出" >> "$LOG" 2>/dev/null
  printf '%s\n' "$PAYLOAD"
}

exit 0
