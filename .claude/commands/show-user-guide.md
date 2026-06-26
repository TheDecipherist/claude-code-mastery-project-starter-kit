---
description: Open the comprehensive User Guide in your browser
scope: project
allowed-tools: Bash
---

Open the User Guide for the Claude Code Mastery Project Starter Kit.

## Steps

1. **Open the User Guide** — try the GitHub Pages URL first, then fall back to a local copy if one exists:

   **Primary (online):**
   ```
   https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/user-guide.html
   ```

   **Local fallback** (only if the repo was cloned):
   ```
   docs/user-guide.html
   ```

2. **Detect the environment** and use the correct open command:
   - **WSL:** `wslview <url>`
   - **macOS:** `open <url>`
   - **Linux:** `xdg-open <url>`

## Detection Logic

```bash
URL="https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/user-guide.html"
LOCAL="$(pwd)/docs/user-guide.html"

open_url() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    wslview "$1" 2>/dev/null
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "$1" 2>/dev/null
  else
    xdg-open "$1" 2>/dev/null
  fi
}

# Always try online first
if open_url "$URL"; then
  echo "Opened online User Guide."
elif [ -f "$LOCAL" ] && open_url "$LOCAL"; then
  echo "Opened local User Guide."
else
  echo "Could not open browser. Visit: $URL"
fi
```

## Output

After opening, tell the user:

> User Guide opened.
> - **Online:** https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/user-guide.html
> - **Tip:** Use `/help` to see all available commands at any time.
