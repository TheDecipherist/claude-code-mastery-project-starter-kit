#!/usr/bin/env bash
# E2E Test Check Hook — PreToolUse (Bash)
# Warns before pushing to main if no real E2E tests exist.
# Exit code 2 = block operation and tell Claude why.
#
# Based on Claude Code Mastery Guides V1-V5 by TheDecipherist

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Only check git push commands
if ! echo "$COMMAND" | grep -qE 'git\s+push'; then
    exit 0
fi

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    exit 0
fi

# Determine if pushing to main/master
BRANCH=$(git branch --show-current 2>/dev/null)
PUSHING_TO_MAIN=false

# Check if command explicitly targets main/master
if echo "$COMMAND" | grep -qE 'git\s+push\s+\S+\s+(main|master)'; then
    PUSHING_TO_MAIN=true
fi

# Check if current branch is main/master (push without explicit branch)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    if ! echo "$COMMAND" | grep -qE 'git\s+push\s+\S+\s+\S+'; then
        # No explicit branch in command — pushing current branch
        PUSHING_TO_MAIN=true
    fi
fi

if [ "$PUSHING_TO_MAIN" = "false" ]; then
    exit 0
fi

# Check for real E2E test files (excluding the example template)
E2E_DIR="tests/e2e"
if [ ! -d "$E2E_DIR" ]; then
    echo "WARNING: No tests/e2e/ directory found." >&2
    echo "Consider creating E2E tests: /create-e2e <feature>" >&2
    exit 0
fi

# Count .spec.ts and .test.ts files, excluding the example template
REAL_TESTS=$(find "$E2E_DIR" -name "*.spec.ts" -o -name "*.test.ts" 2>/dev/null \
    | grep -v "example-homepage.spec.ts" \
    | wc -l | tr -d ' ')

# Also check for Go test files
GO_TESTS=$(find "$E2E_DIR" -name '*_test.go' 2>/dev/null | wc -l | tr -d ' ')
if [ "$REAL_TESTS" -eq 0 ] && [ "$GO_TESTS" -gt 0 ]; then
    REAL_TESTS=$GO_TESTS
fi

if [ "$REAL_TESTS" -eq 0 ]; then
    echo "WARNING: No E2E tests found (only the example template exists)." >&2
    echo "Consider creating E2E tests: /create-e2e <feature>" >&2
    exit 0
fi

exit 0
