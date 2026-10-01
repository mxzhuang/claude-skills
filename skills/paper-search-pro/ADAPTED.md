# 與上游的差異

上游：https://github.com/O0000-code/paper-search-pro （Apache-2.0，本份基於 v2.3.0）

**只改 `SKILL.md` 的 `description`，body 與 `scripts/` 原樣保留。**

上游的 description 涵蓋中文原生檢索（NSSD、中華醫學期刊）與期刊分區篩選。
這裡收窄成五個英文來源與深度分級，並劃清與 `paper-analyst` / `paper-digest`
的界線：**這支負責找，那兩支負責讀。** description 是 skill 路由的依據，
塞進用不到的觸發詞會降低它與其他 skill 的區辨度。需要中文檢索的話，改回上游的
description 即可。

## 設定

設定檔在 `~/.paper-search-pro/config.yaml`（見 `references/setup.md`）。
OpenAlex、CrossRef、PubMed 填 email 即可使用；arXiv 不需認證；
Semantic Scholar 匿名使用偶爾被限流，申請免費 key 可以穩定下來。
