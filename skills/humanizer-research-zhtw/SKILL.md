---
name: humanizer-research-zhtw
description: >-
  Check Traditional Chinese research writing for compressed jargon, bare
  internal codenames, unnatural clipped sentences, and overstated conclusions.
  Runs automatically on .md files written into the repo via the Stop hook, and
  can be invoked directly on a draft. Use before a document goes to the advisor
  or into a paper, and when reviewing any analysis write-up. Reports only —
  never rewrites the file. Does NOT check conversational replies, English text,
  or code comments.
---

# humanizer-research-zhtw

以 [kevintsai1202/humanizer-zh-tw](https://github.com/kevintsai1202/humanizer-zh-tw)
為底，併入研究寫作常用的中文用詞規則，成為**單一來源** ——
這些規則原本散在對話裡，每次都要重講一遍。

**只報告，不自動改寫。** 改寫需要判斷上下文，而判斷屬於作者。

## 一、壓縮縮略詞：展開

技術寫作最常見的問題不是用詞錯，是**把一個需要三個字說清楚的概念壓成
一個字**。壓縮之後只有寫的人看得懂。

| 壓縮 | 展開 |
|---|---|
| 全量 | 完整測試 |
| 人眼 | 人工確認 |
| 偏鬆 | 判定標準較寬鬆 |
| 換 seed | 更換 random seed |

判準：**這個詞拿掉上下文之後，還看得懂嗎。**

## 二、單字詞：補成雙字詞

中文的單字動詞與名詞在技術文件裡讀起來像電報。

| 單字 | 雙字 |
|---|---|
| 詞 | 詞彙 |
| 換 | 更換 |

## 三、內部代號：第一次出現時附白話說明

實驗批次代號、自訂指標名、變數縮寫這類代號，**在一份文件裡第一次出現時必須附一句白話**。
（Stop hook 會檢查 `.claude/hooks/codenames.txt` 裡列出的代號，一行一個。）

```
不好：B2 的結果顯示 drift 在第三組偏高。
較好：B2（第二批污染量測）的結果顯示 drift（輸出偏離原始場景的程度）
      在第三組偏高。
```

理由：這些代號對三個月後的自己、對指導教授、對審稿人都是不透明的。
而它們正是最需要被理解的部分。

## 四、斷句：不為求簡短硬切

不要把一個完整的因果關係切成兩個短句然後靠並列硬接。用自然的連接詞：
「因為」「所以」「但是」「而」「不過」。

```
不好：效果集中在單一象限。強度低時無效。
較好：效果集中在單一象限，而且強度低的時候本來就沒有效果。
```

## 五、技術術語保留英文

`velocity field`、`text encoder`、`noise floor`、`checkpoint`、`embedding`、
`inference` 這類詞不要翻譯。翻譯之後反而要讀者反推原文。

中英混排不加空格以外的裝飾，不要用全形括號包英文。

## 六、語氣：不誇飾、留餘地

| 過強 | 留餘地 |
|---|---|
| 已解決 | 已告一段落 |
| 證明了 | 支持 / 與……一致 |
| 顯著提升 | 提升 X%（附檢定結果或說明未檢定）|
| 完全沒有 | 未觀察到 |

理由與 `70-measurement.md` 第 1 條同源：**寫得比證據強，下游引用時會
再強一次。**

## 執行方式

### Stop hook（自動）

只檢查**這一輪寫入 repo 的 `.md` 檔**。不檢查對話回覆、不檢查英文文件、
不檢查 `.context/archive/`（凍結原件）。

輸出格式：

```
[humanizer] <檔案>:<行> 壓縮縮略詞「全量」→ 建議「完整測試」
[humanizer] <檔案>:<行> 內部代號「drift」首次出現，未附白話說明
[humanizer] 共 N 處，只報告未改寫
```

沒有問題就完全不輸出 —— 每次都說「檢查通過」會讓人開始忽略它。

### 直接呼叫

給定檔案路徑時逐條檢查並列出，附上建議改法但不動檔案。

## 已知限制

第三條（內部代號）需要判斷「這是不是第一次出現」與「這句算不算白話說明」，
自動檢查會有偽陽性。**偽陽性優於漏報**，但如果某個代號反覆被誤報，
把它加進文件開頭的詞彙表然後在檢查裡跳過該檔。
