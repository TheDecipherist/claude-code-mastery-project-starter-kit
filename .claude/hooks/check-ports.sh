#!/usr/bin/env bash
# Port Conflict Check Hook — PreToolUse (Bash)
# Blocks starting a server when the target port is already in use.
# Exit code 2 = block operation and tell Claude why.
#
# Based on Claude Code Mastery Guides V1-V5 by TheDecipherist

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if [ -z "$COMMAND" ]; then
    exit 0
fi

PORT=""

# 1. Explicit port flags: -p 3000, --port 3000, --port=3000
if echo "$COMMAND" | grep -qoE '(-p|--port[= ])\s*[0-9]+'; then
    PORT=$(echo "$COMMAND" | grep -oE '(-p|--port[= ])\s*[0-9]+' | grep -oE '[0-9]+' | head -1)
fi

# 2. PORT= environment variable prefix
if [ -z "$PORT" ] && echo "$COMMAND" | grep -qE 'PORT=[0-9]+'; then
    PORT=$(echo "$COMMAND" | grep -oE 'PORT=[0-9]+' | head -1 | cut -d'=' -f2)
fi

# 3. Known pnpm script names -> known ports
if [ -z "$PORT" ]; then
    case "$COMMAND" in
        *dev:test:website*)   PORT=4000 ;;
        *dev:test:api*)       PORT=4010 ;;
        *dev:test:dashboard*) PORT=4020 ;;
        *dev:website*)        PORT=3000 ;;
        *dev:api*)            PORT=3001 ;;
        *dev:dashboard*)      PORT=3002 ;;
    esac
fi

# No port detected — nothing to check
if [ -z "$PORT" ]; then
    exit 0
fi

# Check if lsof is available
if ! command -v lsof &>/dev/null; then
    exit 0
fi

# Check if port is in use
PID=$(lsof -ti:"$PORT" 2>/dev/null | head -1)

if [ -n "$PID" ]; then
    PROC=$(ps -p "$PID" -o comm= 2>/dev/null || echo "unknown")
    echo "BLOCKED: Port $PORT is already in use by $PROC (PID: $PID)." >&2
    echo "Kill it first: lsof -ti:$PORT | xargs kill -9" >&2
    exit 2
fi

exit 0
