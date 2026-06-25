---
id: 15-mdd-waves
title: MDD Waves — Initiative & Wave Planning System
edition: claude-code-mastery-project-starter-kit
depends_on: [12, 14]
source_files:
  - .claude/commands/mdd.md
  - /home/tim_carter81/projects/mdd/src/types/index.ts
  - /home/tim_carter81/projects/mdd/src/reader/initiatives.ts
  - /home/tim_carter81/projects/mdd/src/commands/dashboard.ts
  - /home/tim_carter81/projects/mdd/src/ui/app.ts
  - /home/tim_carter81/projects/mdd/src/ui/content.ts
routes: []
models: []
test_files:
  - /home/tim_carter81/projects/mdd/src/reader/initiatives.test.ts
data_flow: greenfield
last_synced: 2026-04-16
status: complete
phase: all
mdd_version: 1
tags: [mdd, initiatives, waves, planning, milestones, plan-mode, hierarchy, roadmap]
path: MDD Workflow / Planning
known_issues: []
---

# 15 — MDD Waves: Initiative & Wave Planning System

## Purpose

Adds a three-level planning hierarchy to MDD: **Initiatives** (long-running goals), **Waves** (demo-able milestones), and **Features** (existing MDD docs). Introduces six new sub-commands (`plan-initiative`, `plan-wave`, `plan-execute`, `plan-sync`, `plan-remove-feature`, `plan-cancel-initiative`), extends three existing commands (`status`, `scan`, `graph`), and adds an Initiatives page + status bar additions to the MDD TUI dashboard.

## Architecture

```
.mdd/
  initiatives/<slug>.md     ← initiative-level doc (new)
  waves/<slug>-wave-N.md    ← wave-level doc (new)
  docs/<NN>-<feature>.md    ← feature docs (existing, unchanged)

mdd.md command
  Step 0b mode detection    ← extended: new plan-* dispatch block
  PLAN-INITIATIVE MODE      ← new
  PLAN-WAVE MODE            ← new
  PLAN-EXECUTE MODE         ← new
  PLAN-SYNC MODE            ← new
  PLAN-REMOVE-FEATURE MODE  ← new
  PLAN-CANCEL-INITIATIVE MODE ← new
  STATUS MODE               ← updated: initiatives block added
  SCAN MODE                 ← updated: wave context on drift output
  GRAPH MODE                ← updated: initiative/wave hierarchy block

~/projects/mdd TUI
  src/types/index.ts        ← Initiative, Wave, WaveFeature types; MddWorkspace extended
  src/reader/initiatives.ts ← NEW: reads .mdd/initiatives/ and .mdd/waves/
  src/commands/dashboard.ts ← loadWorkspace() extended
  src/ui/app.ts             ← Initiatives section in left panel, tree expand/collapse, i key
  src/ui/content.ts         ← buildInitiativeContent(), buildWaveContent(), buildStatusBar() extended
```

## Data Model

### Initiative doc frontmatter (`.mdd/initiatives/<slug>.md`)
```yaml
id: auth-system                   # slugified title — lowercase, hyphens, no special chars
title: Auth System
status: active                    # planned | active | complete | cancelled
version: 1                        # integer, auto-incremented on every update
hash: a3f5b2c1                    # hash of file content excluding the hash line
created: 2026-04-15
```

### Wave doc frontmatter (`.mdd/waves/<initiative>-wave-N.md`)
```yaml
id: auth-system-wave-1
title: "Wave 1: Auth Foundation"
initiative: auth-system
initiative_version: 1             # which initiative version this wave was planned against
status: active                    # planned | active | complete
depends_on: none                  # or: auth-system-wave-1 (same-initiative only)
demo_state: "User signs up, logs in, sees an empty dashboard."
created: 2026-04-15
hash: b4d7e3f2
```

### Feature doc additions (optional, non-breaking)
```yaml
initiative: auth-system           # which initiative this belongs to
wave: auth-system-wave-1          # which wave this belongs to
wave_status: planned              # planned | active | complete
```

### TUI types (`src/types/index.ts` additions)
```typescript
export type WaveStatus = 'planned' | 'active' | 'complete';
export type InitiativeStatus = 'planned' | 'active' | 'complete' | 'cancelled';

export interface WaveFeature {
  number: number;
  slug: string;
  docPath: string | null;        // null if not yet created
  waveStatus: WaveStatus;
  dependsOn: string[];           // feature slugs
}

export interface Wave {
  filename: string;
  id: string;
  title: string;
  initiative: string;
  initiativeVersion: number;
  status: WaveStatus;
  dependsOn: string | null;      // wave id or null
  demoState: string;
  created: string;
  hash: string;
  features: WaveFeature[];
  openResearch: string[];
}

export interface Initiative {
  filename: string;
  id: string;
  title: string;
  status: InitiativeStatus;
  version: number;
  hash: string;
  created: string;
  overview: string;
  openProductQuestions: string[];  // raw checkbox lines
  waves: Wave[];                   // populated after waves are read
}
```

`MddWorkspace` extended:
```typescript
export interface MddWorkspace {
  // ... existing fields unchanged ...
  initiatives: Initiative[];      // NEW
}
```
Waves are nested inside `Initiative.waves` — no top-level `waves` array needed.

## Business Rules

### Slug format
All slugs follow: **lowercase, hyphens, no special characters.**
- `"Auth System"` → `auth-system`
- Wave slugs are always prefixed with initiative slug: `auth-system-wave-1`, `auth-system-wave-2`
- MDD auto-generates slugs from user-provided names. User can override when prompted.

### Initiative gates
- `plan-wave` and `plan-execute` both run a **hash check** at startup — hard stop if initiative or wave file has been manually edited since last sync. Message: *"Initiative file has been manually edited since last sync. Run `/mdd plan-sync` first."*
- Before `plan-wave` on any wave: ALL open product questions must be checked off (`- [x]`). MDD quotes unchecked questions back.
- Before `plan-execute`: `depends_on` wave must be `complete`.
- Initiative collision: if `plan-initiative` is run with a name that resolves to an existing slug → hard stop. Check for active feature docs (wave_status not `complete`/`archived`/`deprecated`) — if found, block with: *"This initiative has active feature docs. Deprecate them first."*

### Cross-initiative dependencies
`depends_on` on wave docs references same-initiative waves only. Cross-initiative coordination is documented manually in Open Research.

### plan-execute interaction modes
At the start of each `plan-execute` run, MDD asks:
- **(a) Automated** — data flow shown but not gated, build plan shown but not gated, green gate runs silently. On 5-iteration failure or integration failure: **pause and surface to user** (same prompt as interactive). Does not fail the whole wave.
- **(b) Interactive** — full MDD gates on every feature. Maximum control.

### Wave completion
- Wave only moves to `complete` after user manually confirms demo-state has been verified (honour system).
- Wave status updated in real time as each feature completes — wave doc is single source of truth.
- If all waves `complete`: MDD prompts to mark initiative `complete`.

### plan-remove-feature dependency guard
Before removing a feature from a wave, check if any other feature in the wave lists it in `Depends on`. If so: hard stop — *"`auth-login` depends on `auth-signup`. Remove or reassign that dependency first."*
Renumbering the `#` column after removal is cosmetic only — `Depends on` uses slugs, not numbers.

### plan-cancel-initiative
Sets initiative `status: cancelled`. Optionally archives wave docs to `.mdd/waves/archive/`. Optionally adds `known_issues` warning to associated feature docs.

### Git branching
One branch per feature — unchanged from existing MDD behaviour. Waves are a planning concept only, not reflected in git.

### plan-initiative and plan-wave — guided vs template mode
Both commands offer a mode choice at the start:
- **(a) Guided** — interactive Q&A, MDD builds the file from answers
- **(b) Template** — asks for slug/title only, generates a blank file with all sections as placeholders for manual editing in any editor

Template mode output:
- `plan-initiative --template`: creates `initiatives/<slug>.md` with placeholder sections. Message: *"Fill it out in your editor, then run `/mdd plan-wave <wave-slug>` when ready."*
- `plan-wave --template`: creates `waves/<slug>.md` with placeholder feature table and open research section. Message: *"Fill it out in your editor, then run `/mdd plan-execute <wave-slug>` when ready."*

After manual editing, user must run `/mdd plan-sync` first — this registers the hash so subsequent plan-wave/plan-execute don't hard-stop on a hash mismatch.

### Backward compatibility
All new frontmatter fields (`initiative`, `wave`, `wave_status`) are optional. If absent, MDD treats feature docs exactly as today. Existing 14 docs require no changes.

## API Endpoints

N/A — tooling feature.

## Data Flow

**mdd.md command:**
- User runs `/mdd plan-initiative` → mode detection dispatches to PLAN-INITIATIVE MODE → questions asked → `initiatives/<slug>.md` created → optionally chains to `plan-wave`
- User runs `/mdd plan-wave <wave-slug>` → reads parent initiative fresh from disk → hash check → questions → `waves/<slug>.md` created
- User runs `/mdd plan-execute <wave-slug>` → reads wave doc → automated/interactive choice → runs MDD build flow per feature → updates `wave_status` in wave doc after each feature

**TUI:**
- `loadWorkspace(mddDir)` → `readInitiatives(mddDir)` → `Initiative[]` with nested `Wave[]` → stored in `MddWorkspace.initiatives`
- `buildEntries(ws)` → new INITIATIVES section added to left panel tree
- User selects initiative → `buildInitiativeContent(initiative)` → right panel
- User selects wave → `buildWaveContent(wave)` → right panel
- `buildStatusBar(ws)` → new segment: `INITIATIVES N  │  WAVES N active`

## Dependencies

- **10 (MDD Refinements)** — existing `status`, `scan`, `graph` modes being extended
- **12 (MDD CLI Dashboard)** — TUI project receiving new Initiatives page
- **13 (MDD Workflow Improvements)** — TDD gates and block structure that `plan-execute` builds on
- **14 (MDD Command Versioning)** — versioning conventions used by initiative/wave docs

## Known Issues

(none — new feature)
