---
id: 17-mdd-task-type
title: MDD Task Doc Type — Frozen Workflow Docs
edition: Starter Kit
depends_on: [16-mdd-commands]
source_files:
  - .claude/commands/mdd.md
  - claude-mastery-project.conf
routes: []
models: []
test_files: []
data_flow: greenfield
last_synced: 2026-04-16
status: complete
phase: all
mdd_version: 1
tags: [mdd, task-type, frontmatter, drift-detection, frozen-docs, workflow, doc-types, scan-mode]
path: MDD Workflow / Core Refinements
known_issues: []
---

# 17 — MDD Task Doc Type — Frozen Workflow Docs

## Purpose

Adds a `type: task` distinction to MDD feature docs. A task doc follows the full MDD Build Mode workflow (documentation, test skeletons, implementation, verification) but is permanently frozen after completion — it never shows as drifted in scan results. This serves work that is done-and-finished by definition: one-off investigations, refactors tied to a specific commit, tooling sessions, or any improvement that has no ongoing source files to stay in sync with.

## Architecture

A single new frontmatter field `type` on MDD docs, with two values:

```
type: feature   ← default (implicit when field absent)
type: task      ← frozen — excluded from drift detection
```

The field participates in three parts of the workflow:

```
Invocation  →  Build Mode (Phase 3 sets type)
                          ↓
                   .mdd/docs/<NN>-<slug>.md  (type: task in frontmatter)
                          ↓
Scan Mode   →  frozen section (never drifted)
Status Mode →  task count displayed separately
```

## Data Model

No database. New frontmatter field only:

```yaml
type: task   # optional field — absence implies 'feature'
```

**Field position** (canonical frontmatter order):
```yaml
---
id: ...
title: ...
type: task       ← insert after title, before edition
edition: ...
depends_on: [...]
...
---
```

## Business Rules

### Invocation — When is `type: task` set?

**Rule 1 — Explicit keyword prefix:**
If `/mdd` arguments start with `task`, Build Mode runs immediately with `type: task`. No question is asked.

```
/mdd task refactor db-query script         → type: task, no question
/mdd add user auth system                  → type: feature (default, no question)
```

**Rule 2 — Conf-controlled prompt:**
If `ask_task_on_build = true` in `claude-mastery-project.conf`, Build Mode asks during Phase 1:
> "Is this a one-off task (frozen after done) or an ongoing feature (drift-tracked)?"

Default: `ask_task_on_build = false` — no question unless explicitly enabled.

**Rule 3 — Upgrade compatibility:**
Existing docs without a `type` field are implicitly `feature`. `/mdd upgrade` does NOT add `type: feature` to existing docs — absence is sufficient.

### Scan Mode behavior

Task docs are excluded from drift classification. They appear in a separate **Tasks** section with status `frozen`:

```
Tasks (frozen — drift not tracked):
  ❄️  10-mdd-refinements        — task (frozen)
  ❄️  13-mdd-workflow-improvements — task (frozen)
```

They are not counted in the Summary line (which only counts features).

### Status Mode behavior

Task docs are counted separately from feature docs:

```
Feature docs:  12 files in .mdd/docs/
Task docs:      4 files (frozen — not drift-tracked)
```

### Other modes

- **Audit:** tasks participate in audits (code quality applies regardless of type)
- **Update:** allowed — user can run `/mdd update` on a task to refresh its doc; this updates `last_synced` but does NOT change `type`
- **Deprecate:** allowed — tasks can be deprecated like any other doc
- **Graph:** tasks appear in the dependency graph with a `[task]` label

## Implementation Plan

### Step 1 (Conf Setting): Add `ask_task_on_build` to `claude-mastery-project.conf`

Add the setting to the `[settings]` section (or global settings block) with a comment:

```ini
# ask_task_on_build: During /mdd Build Mode, ask whether this is a one-off task
#                    (frozen after done) or an ongoing feature (drift-tracked).
#                    Set to true to enable the prompt. Default: false
ask_task_on_build = false
```

### Step 2 (mdd.md — Mode Detection): Add `task` keyword to Step 0b

In the mode dispatch table, add before "Otherwise → Build Mode":

```
- If arguments start with `task` → **Build Mode** with `type: task` flag set
  (strip the `task` keyword from the description before passing to Phase 1)
```

### Step 3 (mdd.md — Build Mode Phase 1): Add task prompt (conf-gated)

After the parallel agent synthesis in Phase 1, before asking the user questions, add:

```
**Task vs Feature check (only if ask_task_on_build = true in conf AND type not already set):**
Ask: "Is this a one-off task (frozen after done) or an ongoing feature (drift-tracked)?"
  - Task → set type: task
  - Feature → set type: feature (or omit field)
```

### Step 4 (mdd.md — Build Mode Phase 3): Stamp `type` in frontmatter

In Phase 3 doc template, add `type` field after `title`:

```yaml
---
id: <NN>-<feature-name>
title: <Feature Title>
type: task          ← only include if type: task; omit entirely for features
edition: ...
```

In the writing instructions: "If `type: task` is set, include `type: task` after `title`. For features, omit the field entirely."

### Step 5 (mdd.md — Scan Mode Phase SC2): Skip tasks in drift checks

Before the agent receives the feature list, filter out docs with `type: task`. These go into a separate `frozen_tasks` list.

Classification note: task docs are never passed to the git-check agent.

### Step 6 (mdd.md — Scan Mode Phase SC3): Add frozen Tasks section

After the main drift table, append:

```
Tasks (frozen — drift not tracked):
  ❄️  <id>   — task (frozen)
  ...         (one line per task doc)

(omit this section entirely if no task docs exist)
```

Update the Summary line to exclude tasks:
```
Summary: N in sync · N drifted · N broken · N untracked  (tasks: N frozen)
```

### Step 7 (mdd.md — Status Mode): Show task count separately

Change the Feature docs line:

```
Feature docs:  N files in .mdd/docs/
Task docs:     N files (frozen — not drift-tracked)
```

Task docs are also excluded from the Drift check counts.

## Known Issues

(none — new feature)
