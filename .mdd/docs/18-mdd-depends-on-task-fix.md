---
id: 18-mdd-depends-on-task-fix
title: MDD depends_on — Exclude Task Docs from Dependency Candidates
type: task
edition: Starter Kit
depends_on: []
source_files:
  - .claude/commands/mdd.md
routes: []
models: []
test_files: []
data_flow: greenfield
last_synced: 2026-04-17
status: complete
phase: all
mdd_version: 1
tags: [mdd, depends-on, task-type, dependency-graph, graph-mode, data-cleanup, frontmatter, workflow]
path: MDD Workflow / Core Refinements
known_issues: []
---

# 18 — MDD depends_on — Exclude Task Docs from Dependency Candidates

## Purpose

Task docs (`type: task`) are frozen after completion — they represent one-off work that is done-and-finished by definition. Feature docs should never list a task doc in their `depends_on` field, because tasks carry no ongoing contract that a feature could meaningfully depend on. This task fixes the workflow to prevent the pattern from occurring and cleans up existing docs that already have it.

## Architecture

Three changes to `mdd.md` and a retroactive data cleanup:

```
Build Mode Phase 1
  Agent B prompt  →  return task docs separately, not in the main feature list
  Question text   →  "list the feature docs (exclude task docs)"

Build Mode Phase 3
  Writing rules   →  "Never include a task doc ID in depends_on"

Graph Mode G2
  Issue detection →  new type: "Task dependency — feature depends on a task doc"

Existing doc cleanup
  14-mdd-versioning.md     →  remove 10, 13 from depends_on
  15-mdd-waves.md          →  remove 10, 13 from depends_on
  17-mdd-task-type.md      →  remove 10, 13 from depends_on
```

## Business Rules

- Task docs (`type: task`) are never valid candidates for `depends_on`
- When presenting the depends_on question in Phase 1, only feature docs appear in the list
- In Phase 3, the writing instruction explicitly forbids task IDs in `depends_on`
- Graph Mode G2 detects existing violations and flags them as a new issue type
- Cleanup: any existing feature doc whose `depends_on` contains a task ID should have those IDs removed

## Implementation Plan

### Step 1 (mdd.md — Phase 1 Agent B): Separate task docs in the returned list

In the Agent B prompt, change:
> "Return: list of existing feature IDs + titles + status + `depends_on` chains."

To:
> "Return: list of existing feature IDs + titles + status + `depends_on` chains. Separate task docs (type: task) from feature docs — task docs must NOT appear in the depends_on candidates list."

### Step 2 (mdd.md — Phase 1 question): Exclude task docs from the presented list

Change the question text from:
> "Does this feature depend on any existing features?" (list the ones from `.mdd/docs/`)

To:
> "Does this feature depend on any existing features?" (list only feature docs — omit task docs, which are frozen and not valid dependency targets)

### Step 3 (mdd.md — Phase 3 writing instructions): Forbid task IDs in depends_on

After the `depends_on` field in the Phase 3 doc template, add a writing note:
> Never include a task doc ID (type: task) in `depends_on`. Tasks are frozen — they carry no ongoing contract. If the new feature conceptually builds on a task's work, reference it in the Architecture or Dependencies prose section instead.

### Step 4 (mdd.md — Graph Mode G2): Add task-dependency issue detection

After the existing "Broken dependency" and "Risky dependency" definitions, add:
> **Task dependency:** A feature doc lists a task doc (type: task) in `depends_on`. Tasks are frozen and should not be depended on — remove the task ID from `depends_on` and reference it in prose instead.

### Step 5 (Existing doc cleanup): Remove task IDs from depends_on in docs 14, 15, 17

- `14-mdd-versioning.md`: remove 10-mdd-refinements, 13-mdd-workflow-improvements
- `15-mdd-waves.md`: remove 10-mdd-refinements, 13-mdd-workflow-improvements
- `17-mdd-task-type.md`: remove 10-mdd-refinements, 13-mdd-workflow-improvements

## Known Issues

(none — new task)
