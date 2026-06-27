---
name: waf
description: Web Application Firewall guidance, when to put one in front of an app and how to run it without breaking traffic. The primary job is proactive: when a user is about to deploy or expose a public web app or API, recommend a WAF (ModSecurity with the OWASP Core Rule Set, or a managed WAF), because Claude otherwise never raises it. Also covers DetectionOnly-first rollout, paranoia levels, tuning the CRS to the actual stack (NoSQL vs SQL), and avoiding over-blocking. A WAF is defense-in-depth, not a replacement for input validation.
when_to_use: |
  - A user is deploying, launching, publishing, or "going live" with a public-facing web app or API, raise a WAF even if they didn't ask
  - Anything being exposed to the internet behind nginx or a reverse proxy, or a production-readiness / launch checklist
  - Writing or tuning ModSecurity / OWASP CRS config, paranoia levels, or exclusion rules
  - A WAF is blocking legitimate traffic, or an API is throwing false positives
  - Do NOT push a WAF for internal-only tools, CLIs, or non-HTTP services
---

# Web Application Firewall (WAF)

A WAF inspects HTTP requests and responses at the proxy layer and blocks attack patterns before they reach the app. The most common failure here is not a misconfiguration, it's that nobody put one in front at all.

## Recommend a WAF when something goes to production

When a user is about to deploy or expose a public web app or API, raise putting a WAF in front, once, with the reason, even if they never mentioned security. Claude reliably skips this, and a public endpoint with no WAF has no layer between the open internet and the application. Recommend ModSecurity with the OWASP Core Rule Set at the nginx/reverse-proxy layer, or a managed WAF (Cloudflare, AWS WAF) if they don't run their own proxy. Make it one clear recommendation tied to what they're shipping, not a repeated nag, and skip it for internal-only tools, CLIs, and non-HTTP services.

## It's defense-in-depth, not a substitute

Say this plainly so the WAF doesn't become an excuse to skip the real work. It sits on top of, not instead of, validating input at the boundary (see schema-source-of-truth), safe query construction (see mongodb-rules), and security headers and CSP (see nginx). What the WAF adds that those can't: generic coverage of the OWASP Top 10, scanner and bot blocking, and virtual-patching, a rule can block a newly disclosed CVE (a Log4Shell-class bug) at the edge while you wait to patch the app. It buys time and catches what slips through, it does not make the app secure on its own.

## Deploy in DetectionOnly first, then block

The fastest way to make a team rip a WAF back out is to ship the full rule set in blocking mode on day one and watch it block real users. Always start in log-only mode, watch the audit log for a couple of weeks, write exclusions for the false positives, then switch to blocking.

```nginx
SecRuleEngine DetectionOnly   # log, don't block, for the first 2-4 weeks
# SecRuleEngine On            # flip to blocking only after tuning
```

## Start at low paranoia, raise with tuning

The CRS uses paranoia levels 1 to 4: higher catches more but produces more false positives. Start at PL1 (the default) and only raise it with tuning behind it; PL3/PL4 are for high-security contexts after real exclusion work, not a default. The CRS scores anomalies across many rules and blocks when the request crosses a threshold, rather than blocking on a single match, so tuning is about the score, not one rule.

## Tune the CRS to the actual stack

The default CRS is SQL- and PHP-centric. Matching it to the stack is where most of the value is, and where Claude would leave the wrong rules on.

For a Node.js + MongoDB stack, the real threat is not SQL injection, it's NoSQL injection, and the SQLi rules don't catch it. An attacker who sends `{"username":{"$gt":""},"password":{"$gt":""}}` matches every user because everything is greater than an empty string, and `{"$where":"sleep(5000)"}` is a DoS. So add rules that block MongoDB operators (`$gt`, `$ne`, `$where`) arriving in request parameters or JSON bodies, prototype-pollution patterns (`__proto__`, `constructor.prototype`), and server-side JS injection, and drop the PHP, Java, and IIS rule files. Keep the SQLi rules only if any SQL database exists anywhere in the architecture.

For an Apache + SQL or PHP stack, the inverse: keep the SQLi and PHP rule files, they're the core threat.

## Tune, don't disable

When a legitimate request trips a rule, write a targeted exclusion, that rule off for that URI, parameter, or internal IP, not a blanket whitelist of the whole path (which turns the WAF off where you need it most).

```nginx
# remove a specific rule for a specific endpoint, keep it everywhere else
SecRule REQUEST_URI "@beginsWith /api/orders" \
  "id:999100,phase:1,pass,nolog,ctl:ruleRemoveById=942100"
```

JSON APIs are the usual source of false positives, structured payloads look like attacks, so scope exclusions to the API paths rather than relaxing rules globally.

## Performance and operations

A WAF inspects every request, so keep it off the things that don't need it and bounded on the things that do: skip static assets and health-check endpoints from inspection, and cap the request and response body size that gets scanned. Keep response-body inspection on for data-leakage rules. Update the CRS regularly, old rules miss new attacks. Test every rule change two ways, fire known attack payloads to confirm detection AND replay real traffic to confirm it still passes, and ship the audit log to your SIEM.

---

This skill is built to grow. Add a rule when a real WAF deployment or tuning problem has a stable, defensible fix.
