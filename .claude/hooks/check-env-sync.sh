#!/usr/bin/env bash
# Env Example Sync Hook — Stop
# Warns if .env has keys that .env.example doesn't document.
# SECURITY: Only reads key NAMES, never values.
#
# Based on Claude Code Mastery Guides V1-V5 by TheDecipherist

# Both files must exist
if [ ! -f ".env" ] || [ ! -f ".env.example" ]; then
    exit 0
fi

# Extract sorted key names from a file (ignoring comments, blank lines, export prefix)
extract_keys() {
    grep -E '^(export\s+)?[A-Za-z_][A-Za-z0-9_]*=' "$1" 2>/dev/null \
        | sed 's/^export\s*//' \
        | cut -d'=' -f1 \
        | sort -u
}

ENV_KEYS=$(extract_keys .env)
EXAMPLE_KEYS=$(extract_keys .env.example)

# Find keys in .env that are missing from .env.example
MISSING=""
while IFS= read -r key; do
    if [ -n "$key" ] && ! echo "$EXAMPLE_KEYS" | grep -qx "$key"; then
        MISSING="${MISSING}\n  - $key"
    fi
done <<< "$ENV_KEYS"

if [ -n "$MISSING" ]; then
    echo "" >&2
    echo "ENV SYNC: Keys in .env missing from .env.example:" >&2
    echo -e "$MISSING" >&2
    echo "" >&2
    echo "Other developers won't know these variables exist." >&2
    echo "Add them to .env.example with placeholder values." >&2
fi

exit 0
