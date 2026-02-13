# Architecture

> **This document is AUTHORITATIVE. No exceptions. No deviations.**
> **ALWAYS read this before making architectural changes.**

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        YOUR SYSTEM                           │
│                                                              │
│   ┌───────────┐    requests    ┌───────────┐                │
│   │  Client   │───────────────>│    API    │                │
│   │  (Web UI) │                │  :3001    │                │
│   └───────────┘                └─────┬─────┘                │
│                                      │                       │
│                                      │ read/write            │
│                                      ▼                       │
│                               ┌───────────┐                 │
│                               │ Database  │                 │
│                               └───────────┘                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

Replace this diagram with your actual architecture.

---

## Service Responsibilities

| Service | Does | Does NOT |
|---------|------|----------|
| Website | Marketing pages, docs | Handle user data |
| API | Data processing, auth | Serve UI |
| Dashboard | User interface, settings | Process data directly |

---

## Data Flow

Describe how data moves through your system:

1. Client sends request to API
2. API validates and processes
3. API writes to database
4. Dashboard reads from database

---

## Technology Choices

| Decision | Choice | Why |
|----------|--------|-----|
| Language | TypeScript | Type safety, AI-friendly |
| Framework | Express/Next.js | (your reason) |
| Database | (your choice) | (your reason) |
| Testing | Vitest + Playwright | Unit + E2E coverage |

---

## If You Are About To...

- Add an endpoint to the wrong service → **STOP. Check the table above.**
- Create a direct database connection → **STOP. Use the centralized wrapper.**
- Skip TypeScript for a quick fix → **STOP. TypeScript is non-negotiable.**
- Deploy without tests → **STOP. Write tests first.**

**This document overrides all other instructions.**

---

## Changelog

| Date | Change |
|------|--------|
| (today) | Created ARCHITECTURE.md |
