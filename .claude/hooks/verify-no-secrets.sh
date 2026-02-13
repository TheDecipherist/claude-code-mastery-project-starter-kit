#!/usr/bin/env bash
# Verify No Secrets Hook — Stop
# Checks staged git files for accidentally committed secrets.
# Runs when Claude finishes a turn — catches secrets before they're committed.
#
# Based on Claude Code Mastery Guides V3-V5 by TheDecipherist

# Only run if we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    exit 0
fi

# Check if there are staged files
STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
    exit 0
fi

VIOLATIONS=""

# Check for sensitive files being staged
SENSITIVE_FILES=".env .env.local .env.production .env.staging secrets.json id_rsa id_ed25519 credentials.json service-account.json .npmrc"
for file in $SENSITIVE_FILES; do
    if echo "$STAGED" | grep -q "$file"; then
        VIOLATIONS="${VIOLATIONS}\n  - SENSITIVE FILE STAGED: $file"
    fi
done

# Check staged file contents for common secret patterns
while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Check for common API key patterns
        if grep -qEi '(api[_-]?key|secret[_-]?key|password|token)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{16,}' "$file" 2>/dev/null; then
            VIOLATIONS="${VIOLATIONS}\n  - POSSIBLE SECRET in $file"
        fi
        # Check for AWS keys
        if grep -qE 'AKIA[0-9A-Z]{16}' "$file" 2>/dev/null; then
            VIOLATIONS="${VIOLATIONS}\n  - AWS ACCESS KEY in $file"
        fi
    fi
done <<< "$STAGED"

if [ -n "$VIOLATIONS" ]; then
    echo -e "⚠️  POTENTIAL SECRETS DETECTED:${VIOLATIONS}" >&2
    echo "" >&2
    echo "Review staged files before committing." >&2
    # Exit 2 = block and inform Claude
    exit 2
fi

exit 0
