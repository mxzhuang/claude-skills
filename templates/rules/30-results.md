---
paths:
  - "**/results/**"
  - "**/*.md"
---

# 結果管理

`results/` **部分進 git**：

| 進 git | 不進 git |
|---|---|
| `*.csv` `*.json` `*.jsonl` `*.md` —— 分析表與 manifest | 生成的圖、影音、checkpoint |
| `figures/` 底下的分析圖 | `*.log` —— 執行日誌 |
| 人工複查用的圖 | |

判準是「能不能從 manifest + seed 重生」：能重生的不留，不能重生的（分析表、圖表）留。

- 能重生的大檔由 `.gitignore` 擋住，不要用 `git add -f` 繞過
- 每次 run 用 timestamped 目錄，並寫一份 `run_config.json`（**所有會改變輸出的參數**，含環境變數與預設值）
- manifest 內的路徑一律是 **repo 相對路徑**

## 需要 resume 的長時間工作：用固定目錄

timestamped 目錄與 resume 互斥 —— 重跑會產生新目錄，manifest 找不到前次進度。
**任何需要 `--resume` 的長時間工作，用固定的 task 目錄**，參數快照寫進該目錄的
`run_config.json`，不靠目錄名記錄設定。

## 要引用的數字

`results/` 預設會被清掉或不進版控。**要寫進論文或報告的數字與圖，複製一份到
`docs/` 底下進 git**，並註明出自哪個 run。
