---
paths:
  - "**/*.py"
---

# Python 研究腳本規範

這個專案的 Python 是研究程式碼，不是產品程式碼。工程專案的品質閘門
（覆蓋率門檻、E2E 測試、實作前強制搜尋既有實作）**不適用**。

測試範圍的判準見 `40-testing.md`，這裡不重複。

完成的判準是「產出對得上凍結的計畫」，不是「通過某個覆蓋率門檻」。

## 實作論文方程式時

1. Always reference the equation number in docstring
2. Include the mathematical formula as a comment above the implementation
3. Use variable names matching the paper notation where possible
4. Add a "Deviations from paper" comment if implementation differs
5. Write a simple unit test verifying the function against a known example

### 把公式寫進任務描述時

上面五條約束的是**程式碼**。這一節約束的是**任務描述** —— 交給 Claude Code
去實作之前，公式怎麼寫下來。

與上面五條重疊的部分不重複：引用方程式編號（第 1 條）、變數名沿用論文
記號（第 3 條）、偏離要標明（第 4 條），這裡不再說一次。互補的是這四點：

- **用純文字寫，不要 LaTeX。** 純文字的解析可靠得多，而任務描述的唯一
  用途就是被讀。
- **論文沒交代的地方標 `[UNKNOWN]`**，不要自己補一個看起來合理的值。
  補了就會變成沒人記得是猜的預設值 —— 見 `70-measurement.md`。
- **附變數表**：名稱、shape/型別、意義。shape 特別重要，它是實作時最常
  出錯、而讀論文最難還原的東西。
- **偏離標成 `[DEVIATION: 理由]`**，理由要寫在同一行，不要只標記號。

```
offset = mean(E(w) for w in target_words) - mean(E(w) for w in neutral_words)
# E(w): text-encoder embedding of word w, shape (D,)
# Source: 我們的設計，類比 <Paper> Eq.(4)  [DEVIATION: 用平均而非加權和，論文未給權重]

變數表：
  offset        (D,)       目標詞與中性詞的平均嵌入差
  target_words  list[str]  選出的詞
  D             int        [UNKNOWN] 論文未寫 encoder 維度
```

判準與整份規則一致：**產出對得上凍結的計畫**。任務描述就是那份計畫，
它含糊的地方會原封不動變成實作裡含糊的地方。

## 不要用相對層級計算定位專案根目錄

**不要寫 `Path(__file__).resolve().parents[N]`。** 目錄搬移時它會靜默壞掉且不報錯 ——
層數沒變但樹根變了，算出來的路徑指向不存在的位置，而且因為 import 常寫在
函式內部，`--help` 還是會過。

改用**向上尋找標記檔案**：

```python
_HERE = Path(__file__).resolve()
_REPO_ROOT = next(p for p in _HERE.parents if (p / "pyproject.toml").exists())
_METHOD_ROOT = next(p for p in _HERE.parents if (p / "src").is_dir())
```

這條規則約束新程式碼；既有的 `parents[N]` 至少確認一次目前指向正確。

## 量測與決策分離

任何量測模組都**不得自行做不可逆的丟棄決策**。所有模組輸出連續數值，
由下游的選擇層讀取完整量測表後統一決策。

理由：丟棄發生在量測階段時，後續要改判準就得重跑量測；而量測往往很貴
（GPU 生成、VLM 打分）。把決策留到最後，改判準只要重跑秒級的選擇層。

## 跨軸比較前先確認可比

任何跨條件、跨軸的比較，先確認基線可比 —— 不同場景類別的 noise floor
可能差三倍以上。分母不同類就不要直接比。
