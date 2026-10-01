---
name: grill-me
description: >-
  Relentlessly interrogate a plan, experiment design, or decision one question
  at a time before any of it gets built. Use BEFORE entering implementation,
  when deciding what the next round of experiments should measure, when a
  frozen plan is about to be modified, and whenever a design discussion has
  produced agreement that has not actually been stress-tested. Also use on
  explicit request ("grill me", "拷問我", "stress-test this"). Do NOT use to
  answer factual questions — facts get looked up, not asked; this is only for
  decisions that belong to the human.
---

# grill-me

改寫自 [mattpocock/skills](https://github.com/mattpocock/skills) 的
`grill-me` / `grilling`（MIT）。

**與上游的差異：** 上游設 `disable-model-invocation: true`，只有明說
「grill me」才觸發。這裡放寬 —— **進實作前的拷問在這套工作流裡是流程
不是選配**。三個新增的觸發點：即將進入實作階段、要決定下一輪實驗測什麼、
要修改已凍結的計畫。

## 為什麼放寬

研究裡很多問題事後才發現出在計畫而不是實作：跑完整輪才發現效果只在一個
子集成立、把中途的檢查機制誤當成論文指標、憑猜測設定的門檻實測超出三倍。

這些的共同點是**計畫在凍結前沒有被質疑過**。實作階段再發現，成本是
好幾週的 GPU 時間。

## 程序

**一次只問一個問題。** 多問題並列會造成認知過載，而且人會挑好答的先答。

每個問題附上**你建議的答案**，讓對方有東西可以反駁 —— 空白的問題比帶
立場的問題更難回答。

**等回答再問下一題。** 不要預先列出全部問題。

**事實自己查，不要拿來問。** 能從程式碼、結果檔、文件裡查到的東西自己去查。
提問只保留給**需要人判斷的選擇**。這是這個 skill 的核心約束：
**事實可以被發現，選擇不能被代勞。**

**先解依賴。** 前置決策沒定，後續問題問了也是白問。

**停止條件：** 達成共識為止。**在明確確認對齊之前不要開始實作。**

## 這個工作流特有的必問項

進實作前，以下幾項沒有答案就不要放行：

1. **這一輪要測的假設是什麼，什麼結果會推翻它。** 答不出推翻條件的，
   表示這不是一個實驗而是一次生成。
2. **成功的判準在跑之前定案了嗎。** 判準必須在看到結果之前寫下來 ——
   事後定判準等於沒有判準。
3. **要比較的兩個數字同源嗎。** 分母、子集、基準相同嗎（`70-measurement.md`
   第 1 條）。
4. **這一輪的成本是多少，值得嗎。** GPU 時數、共用卡的排隊、以及失敗後
   要重跑多少。
5. **如果結果是 null，還有價值嗎。** 沒有價值的 null 表示實驗設計有問題 ——
   好的設計無論結果往哪邊都學到東西。

拷問完成後，把凍結的計畫寫進 `.context/plans/`，並在
`.context/current-focus.md` 記一行。
