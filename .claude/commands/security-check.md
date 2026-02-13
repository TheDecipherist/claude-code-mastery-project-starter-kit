---
description: Scan project for security issues — exposed secrets, missing .gitignore entries, unsafe patterns
allowed-tools: Read, Grep, Glob, Bash(git:*), Bash(grep:*), Bash(find:*)
---

# Security Check

Scan this project for security vulnerabilities.

## Checks to Perform

### 1. Secrets in Code
```bash
# Search for common secret patterns in tracked files
git grep -n -E '(api[_-]?key|secret[_-]?key|password|token)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{8,}' -- ':!*.lock' ':!node_modules' 2>/dev/null || echo "No secrets found in code"

# Search for AWS keys
git grep -n 'AKIA[0-9A-Z]\{16\}' 2>/dev/null || echo "No AWS keys found"

# Search for hardcoded URLs with credentials
git grep -n -E '(https?://[^:]+:[^@]+@)' 2>/dev/null || echo "No credential URLs found"
```

### 2. .gitignore Coverage
Verify these entries exist in .gitignore:
- [ ] `.env`
- [ ] `.env.*`
- [ ] `.env.local`
- [ ] `node_modules/`
- [ ] `dist/`
- [ ] `CLAUDE.local.md`
- [ ] `*.log`

### 3. Sensitive Files Check
```bash
# Check if any sensitive files are tracked by git
for f in .env .env.local .env.production secrets.json credentials.json id_rsa .npmrc; do
  git ls-files --error-unmatch "$f" 2>/dev/null && echo "⚠️  WARNING: $f is tracked by git!"
done
echo "Sensitive file check complete."
```

### 4. .env File Verification
- [ ] `.env` exists but is NOT in git
- [ ] `.env.example` exists and IS in git
- [ ] `.env.example` has NO real values (only placeholders)

### 5. Dependency Audit
```bash
# Check for known vulnerabilities (if npm project)
[ -f "package.json" ] && npm audit --production 2>/dev/null | head -20 || echo "Not an npm project"
```

## Output Format

| Check | Status | Details |
|-------|--------|---------|
| Secrets in code | ✅/❌ | ... |
| .gitignore coverage | ✅/❌ | ... |
| Sensitive files tracked | ✅/❌ | ... |
| .env handling | ✅/❌ | ... |
| Dependencies | ✅/❌ | ... |

**Overall: PASS / FAIL**

List any specific remediation steps needed.
