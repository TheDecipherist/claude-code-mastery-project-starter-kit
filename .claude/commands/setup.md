---
description: Interactive project setup — configure .env, GitHub, Docker, analytics, and services
scope: project
argument-hint: [--reset]
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Project Setup

Walk the user through configuring all environment variables and project settings. Creates or updates the `.env` file with real values while keeping `.env.example` as the template.

**Arguments:** $ARGUMENTS

If `--reset` is passed, start fresh (re-ask all questions even if .env already has values).

## Step 0 — Check Current State

```bash
# Does .env exist?
ls .env 2>/dev/null

# Does .env.example exist?
ls .env.example 2>/dev/null

# Is .env in .gitignore?
grep -q "^\.env$" .gitignore 2>/dev/null && echo ".env is gitignored" || echo "WARNING: .env NOT in .gitignore"
```

If `.env` doesn't exist, create it from `.env.example`.
If `.env.example` doesn't exist, create a blank `.env`.
If `.env` is NOT in `.gitignore`, add it immediately before proceeding.

## Step 0.5 — Development Environment Check (WSL)

Detect the current environment:

```bash
# Check if running on WSL
uname -r 2>/dev/null | grep -qi "microsoft\|wsl" && echo "WSL_DETECTED=true" || echo "WSL_DETECTED=false"

# Check if running on Windows (not WSL)
uname -s 2>/dev/null | grep -qi "mingw\|msys\|cygwin" && echo "WINDOWS_NATIVE=true" || echo "WINDOWS_NATIVE=false"

# Check current working directory — is the project on the Windows filesystem from WSL?
pwd | grep -q "^/mnt/c\|^/mnt/d" && echo "PROJECT_ON_WINDOWS_FS=true" || echo "PROJECT_ON_WINDOWS_FS=false"
```

### If on Windows (native, not WSL):

Tell the user:

```
⚠️  You're running on Windows natively.

STRONGLY RECOMMENDED: Use WSL 2 (Windows Subsystem for Linux) instead.

Why this matters:
  • HMR (hot module replacement) is 5-10x faster in WSL
  • Playwright tests run significantly faster on native Linux
  • File watching (nodemon, tsx watch, next dev) is dramatically more reliable
  • Node.js filesystem operations avoid the NTFS translation layer
  • Claude Code itself runs faster with native Linux tools (grep, find, git)

Setup (one time):
  1. Open PowerShell as admin: wsl --install
  2. Restart your computer
  3. Install VS Code extension: "WSL" (ms-vscode-remote.remote-wsl)
  4. Open VS Code → click green "><" bottom-left → "Connect to WSL"
  5. Clone your projects INSIDE WSL: ~/projects/ (NOT /mnt/c/)

After setup, VS Code runs its backend inside WSL while the UI stays on Windows.
Everything just works — terminal, extensions, git, Node.js — all running natively in Linux.
```

### If on WSL but project is on the Windows filesystem (/mnt/c/ or /mnt/d/):

Tell the user:

```
⚠️  You're on WSL but your project is on the Windows filesystem (/mnt/c/...).

This kills most WSL performance benefits. File operations between WSL and the
Windows filesystem go through a slow translation layer — you get the worst of
both worlds.

MOVE YOUR PROJECT to the native WSL filesystem:
  mkdir -p ~/projects
  cp -r /mnt/c/Users/you/projects/my-app ~/projects/my-app
  cd ~/projects/my-app

Then open VS Code from WSL:
  code .

This alone can make HMR 5-10x faster and fix unreliable file watching.
```

### If on WSL with project on Linux filesystem:

```
✓ WSL detected with project on native Linux filesystem — optimal setup.
```

### If on macOS or native Linux:

Skip this check entirely — no action needed.

## Step 1 — Read .env.example for Categories

Read `.env.example` to understand what variables this project needs. Group them by category based on comments/sections.

## Step 2 — Interactive Configuration

Ask the user about each category. For each variable, show the current value (if set in .env) and ask if they want to change it. Skip variables that already have real values unless `--reset` was passed.

### Category: Application Basics
- `NODE_ENV` — Usually `development` (default, don't ask unless --reset)
- `PORT` — Which port? (show current value)

### Category: GitHub
- GitHub username — for git remote URLs and PR creation
- SSH or HTTPS — which auth method for git?

Ask: "What's your GitHub username?"
Ask: "Do you use SSH or HTTPS for git?"

### Category: Analytics (Rybbit)
Ask: "Do you use Rybbit analytics?" (yes/no)
If yes:
- `NEXT_PUBLIC_RYBBIT_SITE_ID` — "What's your Rybbit site ID for this project? (Find it at https://app.rybbit.io)"
- `NEXT_PUBLIC_RYBBIT_URL` — Default `https://app.rybbit.io`

### Category: Multi-Region

**Ask first:** "Single-server or multi-region? (Most projects use single-server.)"

Default: **single-server**. If the user picks single-server, skip to the Database category below.

If the user picks **multi-region**, show this complexity warning BEFORE proceeding:

```
⚠️  Multi-region adds significant complexity:

  • Separate VPS, database, and Dokploy instance PER region
  • Suffixed environment variables (_US, _EU) for every service
  • Region-tagged Docker images (:latest for US, :eu for EU)
  • Region routing logic in your application code
  • Every deployment must update ALL regions to stay in sync

Most projects don't need this. Single-server handles significant traffic
and you can always add regions later.
```

**After showing the warning, ask:** "Continue with multi-region setup? (yes/no)"

If they say no, fall back to single-server. If they confirm yes, proceed with multi-region.

If **yes (confirmed)** — ask: "Which regions?" (default: US + EU). Then EVERY region-specific service gets its own suffixed variables. The `.env` file becomes the **region map** — Claude must ALWAYS check it to know which region is which.

**CRITICAL MULTI-REGION RULES (written to project CLAUDE.md):**

```markdown
## Multi-Region Architecture

This project deploys to multiple regions. EVERY region has isolated infrastructure.

### Region Map (from .env)
- `_US` suffix = US region (e.g., MONGODB_URI_US, DOKPLOY_URL_US)
- `_EU` suffix = EU region (e.g., MONGODB_URI_EU, DOKPLOY_URL_EU)
- No suffix = default/shared (e.g., DOCKER_IMAGE_NAME applies to all regions)

### ABSOLUTE RULES
- US containers NEVER connect to EU databases. EU containers NEVER connect to US databases.
- DEPLOY_REGION env var tells the container which region it's in at runtime.
- When deploying: ALWAYS deploy to ALL regions. Never leave them out of sync.
- When pushing Docker images: `:latest` for US, `:eu` tag for EU.
- Each region has its own Dokploy instance, its own VPS, its own database.
- If you're unsure which region a variable belongs to, READ .env and check the suffix.
```

### Category: Database

If single-region:
- Ask: "What database are you using?" (MongoDB / PostgreSQL / SQLite / None)
- If MongoDB: ask for connection string or offer to build from parts (username, password, cluster, db name)
- If PostgreSQL: ask for connection string
- Writes: `MONGODB_URI=...` or `DATABASE_URL=...`

If multi-region:
- Ask for EACH region's database separately:
  - "What's the MongoDB connection string for **US**?" → `MONGODB_URI_US`
  - "What's the MongoDB connection string for **EU**?" → `MONGODB_URI_EU`
  - Also set `MONGO_DB_NAME` (shared — same db name in both regions)
- Offer to build from parts for each region:
  - US: username, password, cluster → `MONGODB_URI_US=mongodb+srv://user:pass@us-cluster/dbname`
  - EU: username, password, cluster → `MONGODB_URI_EU=mongodb+srv://user:pass@eu-cluster/dbname`

**NEVER display connection strings back.** Just confirm "US database configured ✓" / "EU database configured ✓"

### Category: Docker
If the project has a Dockerfile or docker-compose.yml:
- `DOCKER_HUB_USER` — "What's your Docker Hub username?"
- `DOCKER_IMAGE_NAME` — Suggest `<docker-user>/<project-name>` (shared across regions)

If multi-region, explain the tagging convention:
```
US deployment: docker push $DOCKER_IMAGE_NAME:latest
EU deployment: docker tag $DOCKER_IMAGE_NAME:latest $DOCKER_IMAGE_NAME:eu && docker push $DOCKER_IMAGE_NAME:eu
```

### Category: Deployment (Dokploy / Hostinger VPS)

Ask: "Are you using Dokploy on Hostinger VPS for deployment?" (yes/no)

If single-region:
- `DOKPLOY_URL` — "What's your Dokploy URL? (e.g., http://your-vps-ip:3000/api)"
- `DOKPLOY_API_KEY` — "What's your Dokploy API key?"
- `DOKPLOY_APP_ID` — "What's your Dokploy application ID?"
- `DOKPLOY_REFRESH_TOKEN` — "What's your webhook refresh token? (for automated deploys)"
- `VPS_IP` — "What's your Hostinger VPS IP address?"

If multi-region — ask for EACH region separately:

**US Region:**
- `VPS_IP_US` — "What's your US Hostinger VPS IP?"
- `DOKPLOY_URL_US` — Auto-suggest `http://<VPS_IP_US>:3000/api`
- `DOKPLOY_API_KEY_US` — "Dokploy API key for US?"
- `DOKPLOY_APP_ID_US` — "Dokploy application ID for US?"
- `DOKPLOY_REFRESH_TOKEN_US` — "Webhook refresh token for US?"

**EU Region:**
- `VPS_IP_EU` — "What's your EU Hostinger VPS IP?"
- `DOKPLOY_URL_EU` — Auto-suggest `http://<VPS_IP_EU>:3000/api`
- `DOKPLOY_API_KEY_EU` — "Dokploy API key for EU?"
- `DOKPLOY_APP_ID_EU` — "Dokploy application ID for EU?"
- `DOKPLOY_REFRESH_TOKEN_EU` — "Webhook refresh token for EU?"

After collecting, explain:
```
Region routing:
  US VPS (<VPS_IP_US>) → Dokploy US → pulls :latest → connects to MONGODB_URI_US
  EU VPS (<VPS_IP_EU>) → Dokploy EU → pulls :eu    → connects to MONGODB_URI_EU

Each container gets DEPLOY_REGION=us or DEPLOY_REGION=eu at runtime.
The app reads DEPLOY_REGION and picks the right database URI.
```

### Category: RuleCatch
Ask: "Do you use RuleCatch for AI monitoring?" (yes/no)
If yes:
- `RULECATCH_API_KEY` — "What's your RuleCatch API key? (starts with dc_)"
- `RULECATCH_REGION` — "Which region?" (us / eu)

### Category: Authentication
If `JWT_SECRET` is in .env.example:
- Offer to generate a random JWT secret: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`
- Or let the user provide their own

### Category: Other Variables
For any remaining variables in `.env.example` that weren't covered above:
- Show the variable name and placeholder value
- Ask for the real value

## Step 3 — Write .env

Write all configured values to `.env`. Format with category comments matching `.env.example`.

**CRITICAL RULES:**
- NEVER display secrets back to the user after they enter them
- NEVER commit the .env file
- Confirm .env is in .gitignore after writing
- Show a summary of what was configured (category names only, NOT values)

## Step 4 — Update .env.example

If the user added any NEW variables that aren't in `.env.example`, add them with placeholder values so the template stays in sync.

## Step 5 — Write Multi-Region Rules to CLAUDE.md

If multi-region was selected, append the multi-region architecture rules (from the Category section above) to the project's `CLAUDE.md`. This ensures Claude ALWAYS knows the region map for this project.

Also write a region reference comment block at the top of `.env`:

```bash
# ==========================================
# REGION MAP
# ==========================================
# _US suffix = US region infrastructure
# _EU suffix = EU region infrastructure
# No suffix  = shared across all regions
#
# US: VPS_IP_US → DOKPLOY_URL_US → MONGODB_URI_US
# EU: VPS_IP_EU → DOKPLOY_URL_EU → MONGODB_URI_EU
# ==========================================
```

## Step 6 — Report

**Single-region report:**
```
Project Setup Complete
======================
✓ Application basics (NODE_ENV, PORT)
✓ GitHub (username: <username>)
✓ Analytics (Rybbit configured)
✓ Database (MongoDB connected)
✓ Docker (image: <user>/<project>)
✓ Deployment (Dokploy on Hostinger)
✓ RuleCatch (region: us)
✗ Multi-region (single region)

.env is gitignored: ✓
.env.example updated: ✓
```

**Multi-region report:**
```
Project Setup Complete
======================
✓ Application basics (NODE_ENV, PORT)
✓ GitHub (username: <username>)
✓ Analytics (Rybbit configured)
✓ Multi-region (US + EU)
✓ Database US (MongoDB connected)
✓ Database EU (MongoDB connected)
✓ Docker (image: <user>/<project>, tags: :latest for US, :eu for EU)
✓ Deployment US (Dokploy on Hostinger — <VPS_IP_US>)
✓ Deployment EU (Dokploy on Hostinger — <VPS_IP_EU>)
✓ RuleCatch (region: us)

Region routing:
  US: <VPS_IP_US> → Dokploy US → :latest → MONGODB_URI_US
  EU: <VPS_IP_EU> → Dokploy EU → :eu     → MONGODB_URI_EU

.env is gitignored: ✓
.env.example updated: ✓
CLAUDE.md updated with region map: ✓
```

Show ✓ for configured categories, ✗ for skipped ones.
