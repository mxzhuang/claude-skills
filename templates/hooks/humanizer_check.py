#!/usr/bin/env python3
"""繁中研究寫作的機械可查項目。只報告，不改寫。

只查三類確定性高的：壓縮縮略詞、單字詞、內部代號首次出現未附說明。
斷句自然度與語氣強弱需要判斷上下文，交給人或主 agent，不在這裡猜。

偽陽性優於漏報，但反覆誤報的代號應加進文件開頭的詞彙表。
"""
import re
import sys
from pathlib import Path

COMPRESSED = {
    "全量": "完整測試", "人眼": "人工確認",
    "偏鬆": "判定標準較寬鬆", "換 seed": "更換 random seed",
}
SINGLE_CHAR = {"詞": "詞彙", "換": "更換"}
# 專案的內部代號清單：一行一個，放在 .claude/hooks/codenames.txt（沒有就不查這一項）
_CN_FILE = Path(__file__).with_name("codenames.txt")
_CN = [l.strip() for l in _CN_FILE.read_text().splitlines() if l.strip() and not l.startswith("#")] if _CN_FILE.exists() else []
CODENAMES = re.compile(r"\b(" + "|".join(map(re.escape, _CN)) + r")\b") if _CN else re.compile(r"(?!x)x")
# 這一行附近有這些字就當作已經解釋過了
EXPLAINED = re.compile(r"[（(].{4,}[）)]|——|即|也就是|指的是")

def check(path: Path) -> list[str]:
    try:
        lines = path.read_text(errors="ignore").split("\n")
    except OSError:
        return []
    out, seen = [], set()
    in_code = False
    for i, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            continue
        if in_code or line.lstrip().startswith(">"):
            continue
        for bad, good in COMPRESSED.items():
            if bad in line:
                out.append(f"{path}:{i} 壓縮縮略詞「{bad}」→ 建議「{good}」")
        for bad, good in SINGLE_CHAR.items():
            if re.search(rf"(?<![\w一-鿿]){bad}(?![\w一-鿿])", line):
                out.append(f"{path}:{i} 單字詞「{bad}」→ 建議「{good}」")
        for m in CODENAMES.finditer(line):
            name = m.group(1)
            if name in seen:
                continue
            seen.add(name)
            if not EXPLAINED.search(line):
                out.append(f"{path}:{i} 內部代號「{name}」首次出現，未附白話說明")
    return out

def main() -> int:
    findings: list[str] = []
    for arg in sys.argv[1:]:
        p = Path(arg)
        if p.is_file():
            findings += check(p)
    if not findings:
        return 0
    for f in findings[:25]:
        print(f"[humanizer] {f}", file=sys.stderr)
    if len(findings) > 25:
        print(f"[humanizer] …還有 {len(findings) - 25} 處", file=sys.stderr)
    print(f"[humanizer] 共 {len(findings)} 處，只報告未改寫", file=sys.stderr)
    return 0

if __name__ == "__main__":
    sys.exit(main())
