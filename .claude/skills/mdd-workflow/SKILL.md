---
name: mdd-workflow
description: Use in any project that uses MDD (a `.mdd/` directory exists) when editing source code, building a feature, fixing a bug, requesting an audit, or editing `.mdd/docs` files. Keeps feature docs in sync the moment their controlled source files change, recommends the `/mdd` workflow for substantial tasks, and conforms to `.mdd` doc conventions. Installed globally, so it self-gates: it does nothing in projects that don't use MDD.
when_to_use: |
  - About to edit source code in a project that has a `.mdd/` directory (drift check)
  - User asks for a feature, a real bug fix, a meaningful refactor, or an audit (recommend `/mdd`)
  - Editing a `.mdd/docs/*.md` file directly, outside a `/mdd` run (conventions)
  - Do NOT act at all if the project has no `.mdd/` directory and no `/mdd` command — stay silent
allowed-tools: "Read, Edit, Grep, Glob, Bash"
---

# MDD Workflow Companion

This skill complements the `/mdd` command. The command **owns** the workflow; this skill keeps things honest **between** command runs. Its single most valuable job is preventing documentation drift the moment it would happen, before it accumulates.

## Step 1 — Gate (do this first, every time)

Act only if **this project uses MDD**. Check for any of:
- a `.mdd/` directory in the project root, or
- a resolvable `/mdd` command (`.claude/mdd/`, `~/.claude/mdd/`, `.claude/commands/mdd.md`).

If none exist, **stop silently**. Do nothing, say nothing, never mention MDD. This skill is installed globally and will activate in projects that have never adopted MDD; in those projects it must be invisible.

Two hard rules that hold for everything below:
- **Never run the workflow yourself.** No branching, no `.mdd/` bootstrap, no phase execution. You recommend `/mdd` and let the user confirm. The command performs all side effects.
- **Silence is the default.** When you activate but there is nothing controlled to sync and nothing substantial to recommend, produce no MDD output at all. Never narrate the gate or the check.

## Step 2 — Job 1: Prevent doc drift when editing controlled code (priority)

Feature docs declare the source they own in frontmatter (`source_files`, plus `routes` and `models`). When that source is edited outside a `/mdd` run, the doc silently goes stale. Catch it at the edit, not weeks later in `/mdd scan`.

When you are about to edit (or have just edited) a source file in an MDD project:

1. **Cheap controlled-file check.** Grep `.mdd/docs/*.md` for the file's path in `source_files` (and `routes`/`models` if the change adds or alters a route or model):
   ```bash
   grep -rl "<relative/path/to/file>" .mdd/docs/*.md
   ```
   No match → the file is not controlled. Stay silent and proceed normally.

2. **If a doc controls the file**, name it and keep it in sync:
   - Read `.mdd/docs/00-frontmatter-spec.md` first so any frontmatter edit conforms to the schema.
   - Make the **lightweight, factual** updates inline: bump `last_synced` to today; add a new endpoint to `routes`; add a new model to `models`; append a genuinely new defect to `known_issues` (append-only — never remove entries).
   - Tell the user in one line:
     `📝 Edited <file>, controlled by .mdd/docs/<id>.md — synced last_synced and routes.`
   - **If the change is structural** (behavior, business rules, contracts, or data flow changed, not just a field), don't try to re-derive the doc body yourself. Recommend the command that does a full resync:
     `This change affects how <id> behaves. Run \`/mdd update <id>\` (or \`/mdd audit\`) for a full doc resync.`

3. **If the user is mid-flow and declines the sync**, don't block their work. Note it once so it isn't lost:
   `Leaving .mdd/docs/<id>.md unsynced — \`/mdd scan\` will flag it later.`

This is real-time and pre-commit, which is precisely what `/mdd status` and `/mdd scan` cannot do (they detect drift retrospectively, from git history, only when invoked). Defer batch and historical drift detection to those commands; this skill catches the single edit as it lands.

## Step 3 — Job 2: Recommend the workflow for substantial tasks (recommend, never run)

When the user asks for work MDD is built for **and** it would genuinely benefit, offer the matching mode once, then defer to the user.

**Nudge when** the task is a new feature, a real (non-trivial) bug, a meaningful refactor, or an audit — and **especially** when it will touch code controlled by an existing feature doc that would drift if done ad-hoc.

**Do not nudge** for typos, formatting, renames, config tweaks, one-liners, or plain questions. Anything too small to deserve a doc is too small to nudge.

The offer is one line, in the user's words, and waits:

> You have MDD installed and this looks like a task that would benefit from it — `/mdd <feature>` documents it first, then builds against the doc. Want me to use it, or just proceed here?

Pick the right invocation: feature → `/mdd <feature-slug>`; bug → `/mdd bug`; audit → `/mdd audit`; existing-doc drift → `/mdd update <id>`.

**One offer per task.** If the user declines or says "just do it," proceed ad-hoc and don't ask again this task. Never run `/mdd` without an explicit yes — but Job 1 still applies, so keep any controlled doc in sync even while working ad-hoc.

## Step 4 — Job 3: Keep `.mdd/docs` conventions correct

When editing a `.mdd/docs/*.md` file directly (not through `/mdd`), read `.mdd/docs/00-frontmatter-spec.md` first and conform:
- All required frontmatter fields present and correctly typed.
- `satisfies_contracts` entries use the `from` / `function` / `when` / `status` (`pending`|`done`) / `verified_at` shape — the field is `verified_at`, not `verified`.
- `relates` is symmetric: if doc A relates B, ensure B relates A.
- `known_issues` is append-only.
- Tags are domain concepts, technology names, or feature names — never file paths or generic words.

## What this skill does NOT do

- It does not execute, branch, bootstrap, or run any MDD phase — `/mdd` does that.
- It does not re-derive doc bodies or do full resyncs — `/mdd update`, `/mdd audit`, and `/mdd scan` do that.
- It does not act, or mention MDD, in projects that don't use MDD.
