# 環境規則

常駐規則，無 `paths` frontmatter。

## 執行任何指令前

<!-- 填入：conda env / venv 名稱，以及啟動方式 -->

```bash
conda run -n <ENV_NAME> python <script>
```

## `--help` 不足以證明 runner 能跑

專案本地的 import 常寫在函式內部，argparse 會先退出，所以 `--help` exit=0
**不代表 import 解析得到**。驗證環境要用實際觸發 import 的方式：載入模組
執行 module-level bootstrap，再逐一 import 它 AST 裡函式內部的本地模組。

這一條是通則，不是某個專案的特例 —— 任何有 argparse 的 runner 都適用。

## GPU

<!-- 填入：可用的卡、是否共用、VRAM 上限 -->

GPU 不固定時，**所有輸出必須記錄 `gpu` 欄位**，throughput 數字沒有綁定
型號就沒有意義。

長時間 GPU 工作放進 detached tmux —— ssh 會斷線。
