#!/usr/bin/env bash
# session-context.sh
# Fires on: SessionStart (startup, clear, compact)
# Injects .mdd/.startup.md into Claude's context so every session
# starts oriented without burning tokens reading the codebase.
# If .startup.md does not exist yet, prints a one-line hint instead.

STARTUP_FILE=".mdd/.startup.md"

if [ -f "$STARTUP_FILE" ]; then
  cat "$STARTUP_FILE"
else
  echo "## MDD Startup Context"
  echo "No .mdd/.startup.md found. Run \`/mdd status\` to generate it."
fi
