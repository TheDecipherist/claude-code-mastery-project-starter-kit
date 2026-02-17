#!/usr/bin/env bash
# Rybbit Pre-Deploy Check Hook — PreToolUse (Bash)
# Blocks deployment commands when Rybbit analytics is configured but not set up.
# Exit code 2 = block operation and tell Claude why.
#
# Based on Claude Code Mastery Guides V1-V5 by TheDecipherist

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Skip commands that are git operations — commits, adds, etc. are never deployments
if echo "$COMMAND" | grep -qE 'git\s+(commit|add|push|merge|rebase|checkout|branch|tag|log|diff|status)'; then
    exit 0
fi

# Only check actual deployment commands (not file writes that mention deployment keywords)
# - docker push: actual push to registry
# - vercel deploy/--prod: actual Vercel deploy
# - curl.*application.deploy: actual Dokploy API call
# Avoids false positives from heredocs, cat, echo, python file writes, etc.
if ! echo "$COMMAND" | grep -qEi '(docker\s+push|vercel\s+deploy|vercel\s+--prod|curl.*application\.deploy)'; then
    exit 0
fi

# Check if project uses Rybbit
CONF="claude-mastery-project.conf"
if [ ! -f "$CONF" ]; then
    exit 0
fi

if ! grep -q 'analytics\s*=\s*rybbit' "$CONF" 2>/dev/null; then
    exit 0
fi

# Project uses Rybbit — verify it's configured
if [ ! -f ".env" ]; then
    echo "BLOCKED: Rybbit analytics is configured in this project but .env file is missing." >&2
    echo "Create .env with NEXT_PUBLIC_RYBBIT_SITE_ID=<your-site-id> before deploying." >&2
    echo "Get your site ID from https://app.rybbit.io" >&2
    exit 2
fi

SITE_ID=$(grep -E '^NEXT_PUBLIC_RYBBIT_SITE_ID=' .env 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d ' "'"'"'')

if [ -z "$SITE_ID" ]; then
    echo "BLOCKED: NEXT_PUBLIC_RYBBIT_SITE_ID is missing from .env." >&2
    echo "Add NEXT_PUBLIC_RYBBIT_SITE_ID=<your-site-id> to .env before deploying." >&2
    echo "Get your site ID from https://app.rybbit.io" >&2
    exit 2
fi

# Check for placeholder values
if echo "$SITE_ID" | grep -qEi '(your_site|placeholder|changeme|your-site|example)'; then
    echo "BLOCKED: NEXT_PUBLIC_RYBBIT_SITE_ID appears to be a placeholder ('$SITE_ID')." >&2
    echo "Set a real site ID from https://app.rybbit.io before deploying." >&2
    exit 2
fi

exit 0
