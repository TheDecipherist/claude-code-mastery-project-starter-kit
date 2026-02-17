#!/usr/bin/env bash
# Branch Protection Hook — PreToolUse (Bash)
# Blocks committing directly to main/master when auto_branch is enabled.
# Exit code 2 = block operation and tell Claude why.
#
# Based on Claude Code Mastery Guides V1-V5 by TheDecipherist

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
    exit 0
fi

# Detect target directory from git -C <path> in the command
# Only match real paths (starting with / ~ . or alphanumeric), not placeholders like <dir>
TARGET_DIR=""
if echo "$COMMAND" | grep -qE 'git\s+-C\s+[/~.\w]'; then
    TARGET_DIR=$(echo "$COMMAND" | sed -nE 's/.*git\s+-C\s+([^ ]+)\s+.*/\1/p' | head -1)
fi

# Resolve git dir — if git -C was used with a valid path, check THAT repo
if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
    if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
        exit 0
    fi
    BRANCH=$(git -C "$TARGET_DIR" branch --show-current 2>/dev/null)
    # Allow initial commits (no previous commits in the target repo)
    if ! git -C "$TARGET_DIR" rev-parse HEAD &>/dev/null 2>&1; then
        exit 0
    fi
else
    # CWD-based git check
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        exit 0
    fi
    BRANCH=$(git branch --show-current 2>/dev/null)
    # Allow initial commits (no previous commits yet)
    if ! git rev-parse HEAD &>/dev/null 2>&1; then
        exit 0
    fi
fi

# Only care about main/master
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
    exit 0
fi

# Check auto_branch setting (default: true)
AUTO_BRANCH="true"
CONF="claude-mastery-project.conf"
if [ -f "$CONF" ]; then
    SETTING=$(grep -E '^\s*auto_branch\s*=' "$CONF" 2>/dev/null | head -1 | sed 's/.*=\s*//' | sed 's/\s*#.*//' | tr -d ' ')
    if [ -n "$SETTING" ]; then
        AUTO_BRANCH="$SETTING"
    fi
fi

if [ "$AUTO_BRANCH" = "true" ]; then
    echo "BLOCKED: You're committing directly to '$BRANCH' with auto_branch enabled." >&2
    echo "Create a feature branch first:" >&2
    echo "  git checkout -b feat/<feature-name>" >&2
    echo "  Or use: /worktree <name>" >&2
    exit 2
fi

# auto_branch is explicitly false — user chose to work on main
exit 0
