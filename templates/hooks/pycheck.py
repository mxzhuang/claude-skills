#!/usr/bin/env python3
"""PostToolUse: syntax-check a .py file after Edit/Write.

Reads tool_input.file_path from the stdin JSON payload (Claude Code does not set
a FILE_PATH environment variable, so a hook that tests one never checks anything).

Contract: exit 2 blocks/reports and stderr is fed back to Claude. A clean file
is silent — a hook that comments on every successful edit gets switched off.
Anything unexpected fails open (exit 0) rather than wedging every edit.
"""

import json
import subprocess
import sys
from pathlib import Path

import os

# Set PYCHECK_CONDA_ENV to check inside a conda env; otherwise the current interpreter is used.
ENV = os.environ.get("PYCHECK_CONDA_ENV", "")


def target_path(data: dict) -> str:
    tool_input = data.get("tool_input") or {}
    return tool_input.get("file_path") or tool_input.get("notebook_path") or ""


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception as exc:
        print(f"[pycheck] could not parse hook input: {exc}", file=sys.stderr)
        return 0

    try:
        path = target_path(data)
        if not path.endswith(".py") or not Path(path).is_file():
            return 0

        # compile() rather than py_compile: same syntax check, no __pycache__
        # left behind next to the file being edited.
        probe = (
            "import sys,pathlib;"
            "compile(pathlib.Path(sys.argv[1]).read_text(),sys.argv[1],'exec')"
        )
        result = subprocess.run(
            (["conda", "run", "-n", ENV, "python"] if ENV else [sys.executable]) + ["-c", probe, path],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode == 0:
            return 0

        # conda run echoes its own "ERROR conda.cli.main_run:execute" wrapper
        # line after the real traceback. It says nothing the traceback does not.
        detail = "\n".join(
            line
            for line in (result.stderr or result.stdout).strip().splitlines()
            if not line.startswith("ERROR conda.cli")
        )
        print(f"[SYNTAX ERROR] {path}\n{detail}", file=sys.stderr)
        return 2
    except Exception as exc:
        print(f"[pycheck] check skipped: {exc}", file=sys.stderr)
        return 0


if __name__ == "__main__":
    sys.exit(main())
