#!/usr/bin/env python3
"""PostToolUse (Write|Edit) — enforce the 300-line file limit.

The write already happened (PostToolUse can't undo it), so exit 2 feeds the file
back to Claude as a "split this now" instruction before it moves on. Only counts
real source files; skips generated and vendored paths.
"""
import json
import os
import sys

LIMIT = 300
CODE_EXT = (".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".py", ".go", ".rs", ".java")
SKIP_SUBSTR = ("/node_modules/", "/dist/", "/build/", "/.next/", "/coverage/", "/.git/")


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    path = (data.get("tool_input", {}) or {}).get("file_path", "") or ""
    if not path or not path.endswith(CODE_EXT):
        sys.exit(0)
    if any(s in path for s in SKIP_SUBSTR):
        sys.exit(0)

    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            n = sum(1 for _ in f)
    except OSError:
        sys.exit(0)

    if n > LIMIT:
        sys.stderr.write(
            os.path.basename(path) + " is now " + str(n) + " lines, over the "
            + str(LIMIT) + "-line limit. Split it by concern (one responsibility "
            "per file) before moving on.\n"
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
