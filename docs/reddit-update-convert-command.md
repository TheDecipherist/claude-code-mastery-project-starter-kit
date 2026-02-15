## Update: `/convert-project-to-starter-kit` + full language/framework support

Quick update — the starter kit now has a **third usage path**. Instead of only being able to scaffold new projects with `/new-project`, you can now merge all the starter kit infrastructure into a project you already have.

**What it does:**

- Creates a safety commit first (so `git revert HEAD` undoes everything)
- Detects your language and existing Claude setup automatically
- Asks how to handle conflicts — keep yours, use starter kit, or choose per file
- Copies all 23 commands, 9 hooks, 2 skills, 2 agents
- Merges CLAUDE.md sections without overwriting yours
- Deep-merges settings.json hooks
- Adds infrastructure files (.gitignore entries, .env.example vars, project-docs templates)
- Registers the project so `/projects-created` tracks it

```
/convert-project-to-starter-kit ~/projects/my-existing-app
/convert-project-to-starter-kit ~/projects/my-existing-app --force
```

`--force` skips all prompts and uses "keep existing, add missing" for everything.

**Supported languages, frameworks & databases:**

| Category | Supported |
|----------|-----------|
| **Languages** | Node.js/TypeScript, Go, Python |
| **Frontend** | React, Vue 3, Svelte, SvelteKit, Angular, Next.js, Nuxt, Astro |
| **Backend (Node.js)** | Fastify, Express, Hono |
| **Backend (Go)** | Gin, Chi, Echo, Fiber, stdlib |
| **Backend (Python)** | FastAPI, Django, Flask |
| **Database** | MongoDB, PostgreSQL, MySQL, MSSQL, SQLite |
| **Hosting** | Dokploy, Vercel, Static (GitHub Pages, Netlify) |
| **Testing** | Vitest, Playwright, pytest, Go test |
| **CSS** | Tailwind CSS |

Each has a `/new-project` profile — e.g. `/new-project my-app vue`, `/new-project my-api go chi postgres`, `/new-project my-api python-api`. Or convert an existing project regardless of stack.

Command count: 22 → 23. Repo: [claude-code-mastery-project-starter-kit](https://github.com/TheDecipherist/claude-code-mastery-project-starter-kit?utm_source=reddit&utm_medium=post&utm_campaign=claude-code-starter-kit&utm_content=convert-command-update)
