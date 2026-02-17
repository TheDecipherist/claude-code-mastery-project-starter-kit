---
description: Set the default profile for /new-project
scope: starter-kit
allowed-tools: Read, Edit, AskUserQuestion
---

# Set Project Profile Default

Set which profile `/new-project` uses by default when no profile is specified.

**Arguments:** $ARGUMENTS

## Usage

```
/set-project-profile-default go              → sets default_profile = go
/set-project-profile-default clean           → sets default_profile = clean
/set-project-profile-default default         → sets default_profile = default
/set-project-profile-default python-api      → sets default_profile = python-api
/set-project-profile-default mongo next tailwind docker
  → creates/updates [user-default] profile with those settings
  → sets default_profile = user-default
/set-project-profile-default (no args)
  → shows current default, asks what to change
```

## Steps

### 1. Read the config file

Read `claude-mastery-project.conf` from the project root. If not found, check `~/.claude/claude-mastery-project.conf`.

Extract:
- All `[section]` names (these are the available profiles)
- Current `default_profile` value from `[global]` (if set)

### 2. Parse arguments

**$ARGUMENTS** can be:

**A) No arguments** — show current state and ask:
- Display the current `default_profile` value (or "not set" if absent)
- List all available profiles with a one-line summary of each
- Ask via AskUserQuestion: "Which profile should be the default?"
  - Options: list all profile section names from the conf file
- After selection, proceed to Step 3

**B) Single argument matching an existing `[section]` name** (e.g., `go`, `clean`, `default`, `api`, `vue`, `python-api`):
- Proceed to Step 3 with that profile name

**C) Multiple arguments** (e.g., `mongo next tailwind docker`):
- Parse as shorthand options using the same parser as `/new-project`:
  - **Languages:** `node`, `go`, `python`
  - **Frameworks:** `vite`, `react`, `next`, `vue`, `nuxt`, `svelte`, `sveltekit`, `angular`, `astro`, `fastify`, `express`, `hono`, `gin`, `chi`, `echo`, `fiber`, `stdlib`, `fastapi`, `django`, `flask`
  - **Database:** `mongo`, `postgres`, `mysql`, `mssql`, `sqlite`
  - **Hosting:** `dokploy`, `vercel`, `static`
  - **Package managers:** `pnpm`, `npm`, `bun`, `pip`, `uv`, `poetry`
  - **Options:** `seo`, `ssr`, `tailwind`, `prisma`, `docker`, `ci`, `multiregion`
  - **Analytics:** `rybbit`
  - **MCP:** `playwright`, `context7`, `rulecatch`
- Create or update a `[user-default]` section in the conf file with the parsed settings
- Set `default_profile = user-default` in `[global]`
- Proceed to Step 4 (confirmation)

### 3. Set default_profile in `[global]`

In the `[global]` section:
- If `default_profile` already exists → change its value to the chosen profile
- If `default_profile` does not exist → add it after the last line in `[global]` (before the next `[section]`)

### 4. Confirm

Read the file back and confirm the change was applied. Show the updated `[global]` section to the user.

Tell the user:

> Done. `/new-project PROJECTNAME` will now use the `<profile>` profile by default. You can still override with `/new-project PROJECTNAME <other-profile>` or any other profile name.

If the user used multiple shorthand arguments (option C), also show the `[user-default]` section that was created/updated.
