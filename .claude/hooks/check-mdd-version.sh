#!/usr/bin/env bash
# MDD Version Check Hook — PreToolUse (Bash)
# If .claude/commands/mdd.md is staged in a git commit, ensures mdd_version
# was incremented compared to the last committed version.
# Exit code 2 = block the commit and explain why.

INPUT=$(cat)

# Only intercept git commit commands
if command -v jq &>/dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
else
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//')
fi

if [ -z "$COMMAND" ]; then exit 0; fi
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then exit 0; fi

# Detect target repo (git -C <path> or cd <path> && git)
TARGET_DIR=""
if echo "$COMMAND" | grep -qE 'git\s+-C\s+[/~.\w]'; then
    TARGET_DIR=$(echo "$COMMAND" | sed -nE 's/.*git\s+-C\s+([^ ]+)\s+.*/\1/p' | head -1)
fi
if [ -z "$TARGET_DIR" ] && echo "$COMMAND" | grep -qE '^cd\s+[^ ]+'; then
    CD_DIR=$(echo "$COMMAND" | sed -nE 's/^cd\s+([^ &;]+).*/\1/p' | head -1)
    CD_DIR="${CD_DIR/#\~/$HOME}"
    [ -n "$CD_DIR" ] && [ -d "$CD_DIR" ] && TARGET_DIR="$CD_DIR"
fi

GIT_DIR="${TARGET_DIR:-.}"

# Only applies to the starter kit repo (must have .claude/commands/mdd.md)
if [ ! -f "${GIT_DIR}/.claude/commands/mdd.md" ]; then exit 0; fi

# Check if mdd.md is staged
if ! git -C "$GIT_DIR" diff --cached --name-only 2>/dev/null | grep -q "^\.claude/commands/mdd\.md$"; then
    exit 0
fi

# Get current staged version
STAGED_VERSION=$(git -C "$GIT_DIR" show ":$( git -C "$GIT_DIR" diff --cached --name-only | grep 'mdd\.md')" 2>/dev/null \
    | grep "^mdd_version:" | head -1 | awk '{print $2}')

# Get last committed version (0 if file is new)
COMMITTED_VERSION=$(git -C "$GIT_DIR" show HEAD:.claude/commands/mdd.md 2>/dev/null \
    | grep "^mdd_version:" | head -1 | awk '{print $2}')
COMMITTED_VERSION=${COMMITTED_VERSION:-0}

if [ -z "$STAGED_VERSION" ]; then exit 0; fi

if [ "$STAGED_VERSION" -le "$COMMITTED_VERSION" ] 2>/dev/null; then
    echo "BLOCKED: .claude/commands/mdd.md is staged but mdd_version was not incremented." >&2
    echo "  Committed version: $COMMITTED_VERSION" >&2
    echo "  Staged version:    $STAGED_VERSION" >&2
    echo "" >&2
    echo "Bump mdd_version in .claude/commands/mdd.md (line 6) before committing." >&2
    echo "  Current: mdd_version: $COMMITTED_VERSION" >&2
    echo "  Change to: mdd_version: $((COMMITTED_VERSION + 1))" >&2
    exit 2
fi

exit 0
