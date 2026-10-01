---
name: handoff
description: >-
  Compact the current session into a handoff document so a fresh agent can pick
  the work up cold. Use when a session is ending with work unfinished, when
  context is about to be compacted mid-task, when switching from one phase to
  another (design → implementation, implementation → analysis), and on explicit
  request ("handoff", "交接", "接手文件"). Writes to .context/log/ and updates
  the resident section of .context/current-focus.md so the next session gets the
  state through the SessionStart hook rather than by reading files.
---

# handoff

改寫自 [mattpocock/skills](https://github.com/mattpocock/skills) 的 `handoff`
（MIT）。

**與上游的兩個差異：**

1. 上游寫進作業系統的暫存目錄。這裡寫進 **`.context/log/`** —— 交接文件是
   專案史的一部分，`/tmp` 重開機就沒了。
2. 上游只產生文件。這裡**同時更新 `current-focus.md` 的常駐區** ——
   因為下一個 session 是靠 SessionStart hook 注入知道現況的，光有文件而
   不更新常駐區，等於交接文件寫了但沒人會讀到。

## 產出兩份東西

### 一、`.context/log/YYYY-MM-DD-<slug>.md`

完整的交接文件。內容：

- **這一輪做了什麼**，以及**還沒做完的是什麼**
- **卡在哪**，包含已經排除的可能性 —— 這一項最有價值，它防止下一個
  session 重跑同一輪排除
- **已凍結的決定**，以及它們的理由
- **建議下一步用哪些 skill**

**不要重複已經在別處的東西。** 規格、計畫、ADR、commit、diff 都用路徑或
URL 指過去，不要抄一份進來 —— 抄一份就是製造第二個真相來源。

**遮蔽敏感資訊**：API 金鑰、密碼、個資。

### 二、更新 `.context/current-focus.md`

只改常駐區（`<!-- HOOK_INJECT_END -->` 之前）：

- 「現在在做什麼」換成新的狀態
- 「下一步」重排，把交接時的第一優先放第一
- 「最近的卡點」換成尚未解決的那些

**改完檢查常駐區是否仍在 2,000 bytes 以內：**

```bash
python3 -c "
import pathlib
s=pathlib.Path('.context/current-focus.md').read_text()
r=s.split('<!-- HOOK_INJECT_END -->')[0].rstrip()
print(len(r.encode()), 'bytes / 上限 2000')"
```

超過就精簡，不要讓它被靜默截斷。

## 交接文件的判準

**下一個 session 冷啟動，只讀常駐區加這份文件，能不能接著做。**

答不出來就補。特別容易漏的是「已經排除的可能性」—— 那是這一輪最貴的
產出，而它不會出現在任何 commit 裡。
