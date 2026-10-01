---
name: exp-design-check
description: >-
  Check an experiment design before it is run: are the test's assumptions
  actually met, is there enough power to detect the effect you care about, and
  are the groups being compared on a comparable basis. Use when planning a
  sweep or ablation, when deciding how many seeds or prompts per cell, when a
  result is "not significant" and you need to know whether that means no effect
  or no power, and before any cross-condition comparison. Reports assumptions,
  required n, and achieved power. Does NOT produce APA-formatted reports and
  does NOT interpret results — interpretation stays with the main agent.
---

# exp-design-check

**只做假設檢查與檢定力分析**，不產出格式化的統計報告。要回答的是
「這個設計跑下去會不會白跑」。

## 三個問題，跑之前問

### 一、檢定的假設成立嗎

| 檢定 | 假設 | 不成立時 |
|---|---|---|
| t-test | 常態、變異數同質、獨立 | 改 Mann-Whitney U（不要求常態）|
| paired t-test | 差值常態 | 改 Wilcoxon signed-rank |
| Pearson r | 線性、常態 | 改 Spearman（只要求單調）|
| Spearman | 單調關係、序數以上 | 點數太少就不要報 |
| ANOVA | 常態、變異數同質 | 改 Kruskal-Wallis |

**巢狀結構的觀測值不獨立。** 例如每個輸入產生一整組條件（網格、多個 seed），
同一個輸入底下的多筆輸出不是獨立樣本。比較條件時**以最上層的單位
（輸入、受試者）聚合再比**，不要把底層的格點當獨立樣本。

### 二、檢定力夠嗎

**「不顯著」有兩種意思：沒有效果，或沒有檢定力。** 分不清就不要下結論。

跑之前先算：要偵測到你在意的效果量，需要多少樣本。

```python
from statsmodels.stats.power import TTestIndPower
# 例：要偵測 d=0.3 的差異，α=0.05，power=0.8
TTestIndPower().solve_power(effect_size=0.3, alpha=0.05, power=0.8)
```

跑完之後如果不顯著，回報**achieved power**，不要只寫 "n.s."。

### 三、要比的兩組可比嗎

見 `.claude/rules/70-measurement.md` 第 1 條。

- 兩個數字的分母、子集、基準相同嗎
- 跨類別比較之前，各類別的 noise floor 差多少（可能差好幾倍，要各自正規化）
- 不同來源的量測（例如同一個評分模型的兩種推論後端）混用了嗎

## 一定要算並回報的項目

**1. 有效樣本數**
同時回報「總筆數」與「最上層獨立單位數」，並說明差別。檢定力用後者算。

**2. 單調性所需的最少點數**
只有少數幾個條件點時（例如 5 點），Spearman 的 |ρ| 要多大才在 α=0.05 顯著？
（n=5 時約需 |ρ| ≥ 0.9。）**先算這個再決定要不要報單調性**，否則會得到一個
沒有檢定力的指標。

**3. 多重比較**
k 組兩兩比較就是 k(k−1)/2 次。要不要校正、校正之後還剩多少檢定力。

**4. 跨類別比較的可比性前提**
各類別的 noise floor 是否已各自正規化。沒有的話，這個比較不該跑。

<!-- 專案可在這裡加上自己的固定檢查項 -->

## 輸出

```
假設檢查
  <檢定名>：<假設> — 成立 / 不成立（<依據>）→ <替代方案>

檢定力
  目標效果量 d=<x>，α=<y>，需要 n=<z>，實際 n=<w> → power=<p>

可比性
  <兩組> 的分母：<同/不同源>
  noise floor：<已正規化/未正規化>

結論
  這個設計 可以跑 / 需要調整（<具體要調什麼>）
```

**不做結果判讀。** 這個 skill 回答「這樣跑合不合理」，不回答「結果代表
什麼」—— 後者是主 agent 的工作，見 `00-phase-routing.md` 的分析階段。
