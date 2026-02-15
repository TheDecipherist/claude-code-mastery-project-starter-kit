# Screenshots — Documentation Assets

> Capture these screenshots and recordings to complete the visual documentation.
> Place all files in this directory (`docs/screenshots/`).

---

## Static Screenshots (8 needed)

### 1. `/help` Command Output
- **File:** `help-command.png`
- **How:** Run `/help` in Claude Code, capture the full grouped command list
- **Shows:** All 23 commands organized by category

### 2. `/review` Catching Violations
- **File:** `review-violations.png`
- **How:** Run `/review` on a file with intentional issues (hardcoded secret, `any` type, swallowed error)
- **Shows:** Severity-rated findings with file:line references and fix suggestions

### 3. Auto-Branching on Commit
- **File:** `auto-branch.png`
- **How:** Attempt `/commit` while on main branch with `auto_branch = true`
- **Shows:** Hook blocking the commit and suggesting a feature branch

### 4. Hooks Firing (lint-on-save)
- **File:** `hooks-lint-on-save.png`
- **How:** Write a `.ts` file with a type error, capture the PostToolUse lint output
- **Shows:** TypeScript error caught immediately after file write

### 5. `/diagram architecture` Output
- **File:** `diagram-architecture.png`
- **How:** Run `/diagram architecture` on a project with services, handlers, and adapters
- **Shows:** ASCII box-drawing diagram with data flow arrows

### 6. `/setup` Interactive Flow
- **File:** `setup-flow.png`
- **How:** Run `/setup` and capture the interactive question/answer flow
- **Shows:** Category-by-category configuration with prompts and confirmations

### 7. `/what-is-my-ai-doing` Monitor
- **File:** `ai-monitor.png`
- **How:** Run `pnpm ai:monitor` in a separate terminal while Claude works
- **Shows:** Live tool calls, token usage, cost, and violation stream

### 8. E2E Test Assertions (Good vs Bad)
- **File:** `e2e-assertions.png`
- **How:** Show side-by-side code: a test with proper assertions vs one with none
- **Shows:** The difference between a real test and a "page loads" non-test

---

## Animated Recordings (3 suggested)

Use [asciinema](https://asciinema.org/) for terminal recordings and [agg](https://github.com/asciinema/agg) to convert to GIF.

### 1. Full Setup Demo
- **File:** `demo-setup.gif`
- **Commands:** `git clone ... → /install-global → /new-project → /setup → pnpm dev`
- **Duration:** ~60 seconds

### 2. Code Review + Commit Flow
- **File:** `demo-review-commit.gif`
- **Commands:** Edit a file → `/review` → fix issues → `/commit`
- **Duration:** ~45 seconds

### 3. Diagram Generation
- **File:** `demo-diagram.gif`
- **Commands:** `/diagram all` → show generated architecture diagram
- **Duration:** ~30 seconds

---

## Recording Tips

```bash
# Record a terminal session
asciinema rec demo.cast

# Convert to GIF (install agg: cargo install agg)
agg demo.cast demo.gif --theme monokai --font-size 14

# Optimize GIF size
gifsicle -O3 --lossy=80 demo.gif -o demo-optimized.gif
```

## Where Screenshots Are Used

- `README.md` — "See It In Action" section
- `docs/index.html` — Gallery section
- GitHub repository social preview
