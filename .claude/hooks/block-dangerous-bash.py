#!/usr/bin/env python3
"""PreToolUse (Bash) — block destructive or unsafe shell commands.

Covers the gaps the other Bash hooks don't: rm -rf, curl|sh (the remote-script-
into-a-shell pattern), force-pushing to main/master, chmod 777, and database
drops. Secrets at commit time are handled by verify-no-secrets.sh, and direct
commits to main by check-branch.sh, so this stays focused on irreversible damage.
Exit 2 blocks; run it yourself if you truly mean it.
"""
import json
import re
import sys

DANGER = [
    (re.compile(r"\brm\s+.*-[a-z]*r[a-z]*f", re.I), "rm -rf (recursive force-remove)"),
    (re.compile(r"\brm\s+.*-[a-z]*f[a-z]*r", re.I), "rm -fr (recursive force-remove)"),
    (re.compile(r"\b(curl|wget)\b[^|]*\|\s*(sudo\s+)?(ba)?sh\b", re.I),
     "piping a remote script straight into a shell (curl | sh)"),
    (re.compile(r"\bgit\s+push\b.*--force(-with-lease)?\b.*\b(main|master)\b", re.I),
     "force-pushing to main/master"),
    (re.compile(r"\bgit\s+push\b.*\b(main|master)\b.*--force", re.I),
     "force-pushing to main/master"),
    (re.compile(r"\bchmod\s+-?R?\s*777\b", re.I), "chmod 777"),
    (re.compile(r"\bDROP\s+(DATABASE|TABLE|COLLECTION)\b", re.I),
     "a destructive database drop"),
    (re.compile(r"\.drop(Database)?\(\s*\)", re.I), "dropping a MongoDB database/collection"),
]


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    cmd = (data.get("tool_input", {}) or {}).get("command", "") or ""
    if not cmd:
        sys.exit(0)

    for rx, label in DANGER:
        if rx.search(cmd):
            sys.stderr.write(
                "Blocked: " + label + " is not allowed by the kit's safety hook. "
                "If this is genuinely intended, run it yourself outside the agent.\n"
            )
            sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
