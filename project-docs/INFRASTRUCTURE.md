# Infrastructure

> **Always check this file before making infrastructure or deployment decisions.**

---

## Environment Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     PRODUCTION                               │
│   • URL: https://yourapp.com                                │
│   • API: https://api.yourapp.com                            │
│   • Hosting: (your provider)                                │
└─────────────────────────────────────────────────────────────┘
                              ↑
                         deploy / CI
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   LOCAL DEVELOPMENT                           │
│   • Website:    http://localhost:3000                        │
│   • API:        http://localhost:3001                        │
│   • Dashboard:  http://localhost:3002                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Environment Variables

| Variable | Required | Where | Purpose |
|----------|----------|-------|---------|
| `DATABASE_URL` | Yes | API | Database connection string |
| `JWT_SECRET` | Yes | API | Token signing |
| `PORT` | No | All | Service port (has defaults) |

See `.env.example` for the complete list with placeholder values.

---

## Deployment

### Prerequisites
- [ ] All tests passing
- [ ] No TypeScript errors
- [ ] Environment variables set in production
- [ ] Database migrations run

### Steps
1. (Your deployment steps here)
2. ...
3. ...

### Rollback
1. (Your rollback steps here)

---

## Monitoring

| What | Tool | URL |
|------|------|-----|
| Uptime | (your tool) | (url) |
| Errors | (your tool) | (url) |
| Logs | (your tool) | (url) |

---

## Changelog

| Date | Change |
|------|--------|
| (today) | Created INFRASTRUCTURE.md |
