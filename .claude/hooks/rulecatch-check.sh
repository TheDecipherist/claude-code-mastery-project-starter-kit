#!/usr/bin/env bash
# RuleCatch Check Hook — Stop
# Runs when Claude finishes a turn — reports any rule violations detected.
# Guaranteed to run (stronger than CLAUDE.md command instructions).
#
# Based on Claude Code Mastery Guides V3-V5 by TheDecipherist

# Check if RuleCatch CLI is available
if ! command -v npx &>/dev/null; then
    exit 0
fi

# Check if @rulecatch/ai-pooler is available (quick check)
# If not installed, skip silently — don't block the user
if ! npx @rulecatch/ai-pooler@latest check --help &>/dev/null 2>&1; then
    exit 0
fi

# Run RuleCatch violation check for the current session
# --quiet: only output if violations found
# --format: short summary suitable for hook output
RESULT=$(npx @rulecatch/ai-pooler@latest check --quiet --format summary 2>/dev/null)

if [ -n "$RESULT" ] && [ "$RESULT" != "0 violations" ]; then
    echo "" >&2
    echo "📋 RuleCatch: $RESULT" >&2
    echo "   Run 'pnpm ai:monitor' for details or check your dashboard." >&2
    # Exit 0 = inform but don't block (violations are warnings, not blockers)
    exit 0
fi

exit 0
