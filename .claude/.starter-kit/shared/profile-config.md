<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## Profile System: claude-mastery-project.conf

If the user passes `default` (or any profile name), read `claude-mastery-project.conf` from the project root. This file defines reusable presets so users don't re-type preferences.

### claude-mastery-project.conf Format

```ini
# Claude Mastery Project Configuration
# Define profiles with preset options for /new-project

[default]
type = fullstack
framework = next
hosting = dokploy
package_manager = pnpm
database = mongo
options = seo, tailwind, docker, ci
mcp = playwright, context7, rulecatch

[api]
type = api
framework = fastify
hosting = dokploy
package_manager = pnpm
database = mongo
options = docker, ci
mcp = context7, rulecatch

[static-site]
type = webapp
framework = astro
hosting = static
package_manager = pnpm
options = seo, tailwind
mcp = context7

[quick]
type = webapp
framework = vite
hosting = vercel
package_manager = pnpm
options = tailwind
mcp = context7
```

### How Profiles Work

1. Read `claude-mastery-project.conf` from project root (or `~/.claude/claude-mastery-project.conf` for global defaults)
2. Parse the named profile section
3. Apply all settings from the profile
4. Any additional arguments OVERRIDE profile settings
5. Missing settings from profile = ask the user

Examples:
- `/new-project my-app default` — uses [default] profile for everything
- `/new-project my-app api` — uses [api] profile
- `/new-project my-app default vercel` — uses [default] but overrides hosting to Vercel
- `/new-project my-app` — no profile, asks all questions

### Create Default Config

When scaffolding the starter kit itself, create `claude-mastery-project.conf` with the profiles above as starting templates. Users customize to their preferences.

