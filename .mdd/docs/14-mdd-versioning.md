---
id: 14-mdd-versioning
title: MDD Command Versioning
edition: Starter Kit
depends_on: []
source_files:
  - .claude/commands/mdd.md
  - .claude/commands/install-mdd.md
  - .claude/commands/install-global.md
routes: []
models: []
test_files: []
data_flow: greenfield
last_synced: 2026-04-16
status: complete
phase: all
tags: [mdd, versioning, frontmatter, mdd-version, install-mdd, install-global, metadata, compatibility]
path: MDD Workflow / Core Refinements
known_issues: []
---

# 14 — MDD Command Versioning

## Purpose

Add `mdd_version` as a cross-cutting metadata field across all MDD-created files (feature docs, audit reports, and future initiative/wave docs). Every file MDD creates is stamped with the version of MDD that created it. This makes it immediately visible which files were created under an older version of MDD, enabling `install-mdd`, `install-global`, and `/mdd status` to surface outdated files.

`mdd_version` is distinct from the `version` field used on initiative/wave docs (which tracks content revisions) — no collision.

## Architecture

```
mdd.md frontmatter
  mdd_version: 2          ← single source of truth for current MDD version

        ↓ stamped at creation time on every MDD-created file

.mdd/docs/01-signup.md    → mdd_version: 1  (created under old MDD)
.mdd/docs/02-login.md     → mdd_version: 2  (created under current MDD)
.mdd/audits/report-*.md   → mdd_version: 2
.mdd/initiatives/*.md     → mdd_version: 2  (future)
.mdd/waves/*.md           → mdd_version: 2  (future)

        ↓ detected by

install-mdd / install-global mdd
  → compare mdd_version in source mdd.md vs installed mdd.md
  → prompt to update if behind

/mdd status
  → scan all .mdd/ files for mdd_version
  → report: "3 files on mdd_version 1, current is 2"
```

## Business Rules

- `mdd_version` is an integer, incremented manually by 1 each time `mdd.md` is meaningfully updated
- Starts at `1` (first versioned release)
- `mdd.md` frontmatter is the single source of truth — all other files read their stamp FROM this value at creation time
- An installed `mdd.md` with no `mdd_version` field = version 0 = always outdated
- A `.mdd/` file with no `mdd_version` field = version 0 = created before versioning existed
- Version comparison: installed < source → prompt to update
- If equal → "already up to date", no prompt
- MDD never auto-updates files — always prompts
- Any MDD command that writes to a file (create OR update) must update that file's `mdd_version` to the current version — including audit fixes, doc updates, and status rebuilds

## mdd_version Read Logic

```bash
# Read mdd_version from any MDD file (returns empty if absent)
grep "^mdd_version:" /path/to/file.md | awk '{print $2}'

# Treat missing as 0
INSTALLED=$(grep "^mdd_version:" "$FILE" 2>/dev/null | awk '{print $2}')
INSTALLED=${INSTALLED:-0}
```

## Affected Files and Changes

### mdd.md — frontmatter
Add `mdd_version: 1` to YAML frontmatter.

### mdd.md — Phase 3 (Write Feature Doc)
When creating `.mdd/docs/<NN>-<feature>.md`, include `mdd_version: <current>` in frontmatter.

### mdd.md — Phase 7 (Verify + Report)
When updating `known_issues` or any other field in a feature doc, update its `mdd_version` to current.

### mdd.md — Audit phases (A2, A3, A5)
When writing `.mdd/audits/*.md` files, include `mdd_version: <current>` in frontmatter or as a metadata comment at the top.
When A5 (Fix) edits any `.mdd/docs/*.md` to remove a known issue, update that doc's `mdd_version` to current.

### mdd.md — Status Mode (.startup.md rebuild)
When rebuilding `.mdd/.startup.md`, update its `mdd_version` to current.

**Rule: any MDD write = mdd_version update. No exceptions.**

### mdd.md — Status Mode
Add to `/mdd status` output:
```
MDD version: 2
  Files on older versions:
    mdd_version 1: 3 files (run /install-mdd to update)
    mdd_version 0: 2 files (created before versioning)
```

### install-mdd.md — Step 2 (MDD already installed)
Read `mdd_version` from source and installed `mdd.md`. Surface mismatch alongside existing prompt.

### install-mdd.md — Step 5 (Copy mdd.md)
Replace generic overwrite prompt with:
`"mdd.md already exists (installed: v1, available: v2). Update? (yes / keep existing)"`

### install-global.md — MDD-Only Install
Add version comparison before overwriting. Show:
`"mdd.md: v1 → v2 (update available)"` or `"mdd.md: v1 — already up to date"`

### install-global.md — Step 3B (Optional MDD global install)
Same version-aware prompt as install-mdd Step 5.

### README.md
Add MDD versioning to the feature description — mention `mdd_version` field, what it does, and how to use `install-mdd` / `install-global mdd` to update.

### docs/index.html
Update the GitHub Pages site to reflect the versioning addition in the relevant MDD section.

## Known Issues

(none)
