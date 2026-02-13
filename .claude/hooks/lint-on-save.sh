#!/usr/bin/env bash
# Lint on Save Hook — PostToolUse
# Runs linter after Claude writes/edits a file.
# Keep hooks FAST (<5 seconds) or Claude may not wait (V5 lesson).
#
# Based on Claude Code Mastery Guides V3-V5 by TheDecipherist

# Read the tool input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

EXTENSION="${FILE_PATH##*.}"

case "$EXTENSION" in
    ts|tsx)
        # TypeScript — run type check on the specific file if tsc is available
        if command -v npx &> /dev/null && [ -f "tsconfig.json" ]; then
            npx tsc --noEmit --pretty "$FILE_PATH" 2>&1 | head -20
        fi
        ;;
    js|jsx)
        # JavaScript — run eslint if available
        if command -v npx &> /dev/null && [ -f ".eslintrc*" ] || [ -f "eslint.config.*" ]; then
            npx eslint --no-error-on-unmatched-pattern "$FILE_PATH" 2>&1 | head -20
        fi
        ;;
    py)
        # Python — run ruff or flake8 if available
        if command -v ruff &> /dev/null; then
            ruff check "$FILE_PATH" 2>&1 | head -20
        elif command -v flake8 &> /dev/null; then
            flake8 "$FILE_PATH" 2>&1 | head -20
        fi
        ;;
esac

exit 0
