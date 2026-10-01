---
name: project-setup
description: >-
  Set up the .claude/ and .context/ structure for a new research project, or
  bring an existing project's structure up to date. Creates the rules layer
  (numbered, with paths-frontmatter for scoped rules), a SessionStart hook that
  already has the segmented time budget and nonce verification built in,
  settings.json, the .context/ knowledge skeleton, and a CLAUDE.md that points
  at both. Use when starting a new project, when an existing project has no
  .claude/ or a stale one, or when the user says 初始化專案 / set up workspace /
  新專案設置. Copies templates and then interviews for the blanks — it does not
  copy another project's content.
---

# project-setup

把 `templates/` 的骨架複製到目標專案，然後訪談填空。

`templates/` 在這個 skill 所屬 plugin 的根目錄：本檔所在目錄往上兩層
（`<skill base>/../../templates`）。

**不是複製別的專案。** 模板裡是骨架與說明，`<!-- 填入 -->` 標記處要問使用者。
把另一個專案的實際內容搬過來，會讓新專案帶著不屬於它的假設開張。

## 先確認

1. 目標專案根目錄在哪
2. `.claude/` 或 `.context/` 是否已存在 —— **存在就不要覆蓋**，
   列出差異讓使用者決定逐項合併
3. 這是研究專案嗎。不是的話這套結構不適用，直接說

## 複製什麼

| 來源 | 去向 |
|---|---|
| `templates/rules/`（`README.md` 除外） | `<專案>/.claude/rules/` |
| `templates/hooks/` | `<專案>/.claude/hooks/` |
| `templates/settings.json` | `<專案>/.claude/settings.json`（**合併**，不覆蓋）|
| `templates/context/` | `<專案>/.context/` |
| `templates/CLAUDE.md` | `<專案>/CLAUDE.md` |

複製後 `chmod +x` 所有 hook。

`.gitignore` 要加：`.claude/hook-fired.log`、`.context/log/`。

## 訪談填空

依序問，一次一題，答完才問下一題：

1. **專案一句話是什麼** → `CLAUDE.md` 開頭
2. **環境怎麼啟動**（conda env 名稱 / venv 路徑）→ `rules/10-environment.md`；
   用 conda 的話，提示在 shell 設 `PYCHECK_CONDA_ENV=<env>` 給語法檢查 hook
3. **GPU 情況**：固定還是共用、VRAM 多少 → 同上
4. **有沒有不得修改的檔案**（凍結的核心實作、外部規格）
   → 有就填 `rules/20-stable-core.md`，**沒有就把那個檔刪掉**
5. **目錄結構** → `CLAUDE.md` 與 `conventions.md`
6. **現在在做什麼、下一步** → `current-focus.md` 的常駐區
7. **寫作語言是不是繁體中文** → 不是的話刪掉 `80-reporting.md` 的用詞段、
   `hooks/stop-humanizer.sh`、`hooks/humanizer_check.py` 與 settings 裡的 Stop hook

## 做完之後一定要驗

模板的 hook 不驗證就等於沒裝 —— 注入失敗時它不會報錯，只會讓 CC 用
`CLAUDE.md` 推斷出看起來可信但過期的答案。

```bash
# 1. 手動跑，確認輸出是合法 JSON、常駐區在裡面
echo '{"source":"startup"}' | CLAUDE_PROJECT_DIR=$PWD \
  bash .claude/hooks/session-start-context.sh | python3 -m json.tool

# 2. 確認常駐區沒超過 2,000 bytes 上限

# 3. 開一個新 session，然後比對 nonce
cat .claude/hook-fired.log            # 取最後一個 HOOK-NONCE
grep -c "<那個 nonce>" ~/.claude/projects/<proj>/<session-id>.jsonl
```

**第 3 步不能省，也不能用「問模型有沒有收到」代替。** 模型的自述正是
待驗證的東西；回答品質也不行，注入失敗照樣產出流暢的答案。

## 常見錯誤

| 錯誤 | 後果 |
|---|---|
| 在 hook 裡呼叫會遍歷檔案系統的東西 | 15 秒逾時，整支被砍，注入全失且無徵狀 |
| 規則全部不加 `paths` | 每個 session 都載入全部，清單越長越沒人遵守 |
| 把規則同時寫在 `CLAUDE.md` 與 `rules/` | 兩份規則就是沒有規則 |
| 常駐區塞背景與決策史 | 超過 2,000 bytes 被截斷，而截斷是靜默的 |
| 裝完不驗證 | 見上一節 |
