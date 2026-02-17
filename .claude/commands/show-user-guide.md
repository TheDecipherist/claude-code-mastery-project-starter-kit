---
description: Open the comprehensive User Guide in your browser
scope: project
allowed-tools: Bash
---

Open the User Guide for the Claude Code Mastery Project Starter Kit.

## Steps

1. **Check for the HTML file** at `docs/user-guide.html` in the project root.

2. **Open in browser** — try the GitHub Pages URL first, fall back to local file:

   **Primary (online):**
   ```
   https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/user-guide.html
   ```

   **Fallback (local):**
   ```
   docs/user-guide.html
   ```

3. **Detect the environment** and use the correct open command:
   - **WSL:** `wslview <url>`
   - **macOS:** `open <url>`
   - **Linux:** `xdg-open <url>`

4. **Also mention** the markdown version is available at `USER_GUIDE.md` in the project root for reading directly in GitHub or a text editor.

## Detection Logic

```bash
# Detect platform and open URL
URL="https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/user-guide.html"
LOCAL="docs/user-guide.html"

if grep -qi microsoft /proc/version 2>/dev/null; then
  # WSL
  wslview "$URL" 2>/dev/null || wslview "$LOCAL" 2>/dev/null || echo "Could not open browser. Visit: $URL"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  open "$URL" 2>/dev/null || open "$LOCAL" 2>/dev/null || echo "Could not open browser. Visit: $URL"
else
  # Linux
  xdg-open "$URL" 2>/dev/null || xdg-open "$LOCAL" 2>/dev/null || echo "Could not open browser. Visit: $URL"
fi
```

## Output

After opening, tell the user:

> User Guide opened in your browser.
> - **Online:** https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/user-guide.html
> - **Markdown:** `USER_GUIDE.md` (project root)
> - **Tip:** Use `/help` to see all available commands at any time.
