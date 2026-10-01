---
name: paper-analyst
description: >-
  Analyse a single academic paper or research PDF and write a structured
  Traditional Chinese summary into .context/papers/. Use when a paper is
  uploaded, pasted, or named and the user wants to know what it says, how it
  relates to this project, or whether it is worth reading in full. Triggers
  include 分析這篇論文 / 解讀這篇 paper / 這篇論文講什麼 / 值不值得讀 /
  這篇跟我們的方法什麼關係 / summarise this paper. Every claim is tagged
  [原文陳述] or [模型推論] so the reader can tell what the paper said from what
  the model inferred. Do NOT use for non-academic PDFs, or for finding papers —
  that is lit-scout's job.
---

# paper-analyst

改寫自 [flyer-Li/paper-analyst](https://github.com/flyer-Li/paper-analyst)。

**與上游的差異：** 標記改為繁體 —— `[原文声明]` → **`[原文陳述]`**、
`[模型归纳]` → **`[模型推論]`**，輸出語言改繁體中文，並新增一節
「與本專案的關聯」。

## 為什麼標記制度是重點

這個 skill 的價值不在摘要，在**分辨摘要裡哪些是論文說的、哪些是模型推的**。

沒有這個分辨，一份讀起來流暢的摘要會把推論混進事實，而下游引用時
兩者一樣可信。這與 `70-measurement.md` 第 2 條同構：**看起來通過了，
但通過的不是你以為的那件事。**

## 標記

| 標記 | 意義 | 必須附上 |
|---|---|---|
| `[原文陳述]` | 論文直接寫的 | 出處（節次／頁碼／式號）|
| `[模型推論]` | 模型推出來的 | 推論依據 |
| `[不確定]` | 讀不出來或有歧義 | 為什麼不確定 |

**沒有第四種。** 每一條主張都要落在這三類之一。

**不要為了補滿章節而編造內容。** 讀不到的部分明說哪些讀不到 ——
一份有缺口但誠實的摘要，比一份完整但混入推論的摘要有用得多。

## 程序

1. **評估輸入品質** —— PDF 有沒有缺頁、公式有沒有轉成亂碼、表格有沒有錯位。
   有問題先講，不要當作沒發生。
2. **判斷論文類型** —— 方法、benchmark、資源、綜述。類型決定該問什麼問題。
3. **執行分析**（見下方章節）
4. **輸出前自我檢查** —— 每條主張都有標記了嗎、每個不確定都標了嗎、
   有沒有哪一句其實是我推的但寫得像論文說的。

## 輸出

寫進 `.context/papers/<編號>-<slug>.md`，並更新 `.context/papers/INDEX.md`
的表格。編號沿用該目錄現有的序號。

章節：

```markdown
# <編號>. <Short Name> — <全名>
**Authors:** … · **Link:** … · **Venue:** …

## 這篇在做什麼
[原文陳述] 一到三句。

## 方法
[原文陳述] 核心機制。有式號就引式號。
[模型推論] 它為什麼這樣設計（若論文沒明說）。

## 實驗與結果
[原文陳述] 用了什麼資料集、比了誰、贏多少。
[不確定] 讀不出來的部分。

## 與本專案的關聯
[模型推論] 三種之一：可借用的機制／可對照的 baseline／可引用的依據。
講清楚是「機制借用」還是「方法移植」——這兩者的可信度差很多。

## 限制與我們該注意的
[原文陳述] 論文自承的限制。
[模型推論] 論文沒說但套用到我們的設定會出問題的地方。
```

## 一句話判準

**讀完摘要的人，應該能夠只憑標記就知道哪些話可以直接引進論文、哪些話
必須自己回去確認。**
