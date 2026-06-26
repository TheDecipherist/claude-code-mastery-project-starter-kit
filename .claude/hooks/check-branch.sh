#!/usr/bin/env bash
# Branch Protection Hook — PreToolUse (Bash)
# Blocks committing directly to main/master when auto_branch is enabled.
# Exit code 2 = block operation and tell Claude why.
#
# Based on Claude Code Mastery Guides V1-V5 by TheDecipherist

INPUT=$(cat)

# Extract command from JSON — try jq first, fall back to grep/sed (no Python needed)
if command -v jq &>/dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
else
    # Lightweight fallback: extract "command" value from JSON via grep/sed
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//')
fi

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

# Also detect: cd /some/path && git commit (common cross-repo pattern)
# Extract the first cd target from commands like "cd /path && git ..."
if [ -z "$TARGET_DIR" ] && echo "$COMMAND" | grep -qE '^cd\s+[^ ]+'; then
    CD_DIR=$(echo "$COMMAND" | sed -nE 's/^cd\s+([^ &;]+).*/\1/p' | head -1)
    # Expand leading tilde — [ -d "~/path" ] doesn't expand tilde inside quotes
    CD_DIR="${CD_DIR/#\~/$HOME}"
    if [ -n "$CD_DIR" ] && [ -d "$CD_DIR" ]; then
        TARGET_DIR="$CD_DIR"
    fi
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
# Look for claude-mastery-project.conf in the target repo first, then CWD.
# If neither has the conf file, this is not a starter kit project — skip the check.
AUTO_BRANCH="true"
CONF_FOUND=false
CONF="claude-mastery-project.conf"

# Determine where to look for the conf — target dir or CWD
CONF_SEARCH_DIR=""
if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
    CONF_SEARCH_DIR="$TARGET_DIR"
else
    CONF_SEARCH_DIR="."
fi

if [ -f "${CONF_SEARCH_DIR}/${CONF}" ]; then
    CONF_FOUND=true
    SETTING=$(grep -E '^\s*auto_branch\s*=' "${CONF_SEARCH_DIR}/${CONF}" 2>/dev/null | head -1 | sed 's/.*=\s*//' | sed 's/\s*#.*//' | tr -d ' ')
    if [ -n "$SETTING" ]; then
        AUTO_BRANCH="$SETTING"
    fi
elif [ -z "$TARGET_DIR" ] && [ -f "$CONF" ]; then
    # Fallback: conf exists in CWD — only when no cross-repo target was detected
    CONF_FOUND=true
    SETTING=$(grep -E '^\s*auto_branch\s*=' "$CONF" 2>/dev/null | head -1 | sed 's/.*=\s*//' | sed 's/\s*#.*//' | tr -d ' ')
    if [ -n "$SETTING" ]; then
        AUTO_BRANCH="$SETTING"
    fi
fi

# If no starter-kit conf found anywhere, this isn't a starter-kit project — allow commit
if [ "$CONF_FOUND" = false ]; then
    exit 0
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
