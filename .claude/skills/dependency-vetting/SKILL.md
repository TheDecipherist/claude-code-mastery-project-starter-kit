---
name: dependency-vetting
description: Vet an npm (or other) package for supply-chain risk before it's added to a project. Use when asked whether a package is safe, trustworthy, or worth adding, when about to install an unfamiliar dependency, or when something about a package feels off. Runs isolated and read-only, reports an evidence-backed risk verdict, does not install anything.
when_to_use: |
  - User asks "is this package safe", "should I add X", "can I trust this dependency"
  - About to install an unfamiliar or low-profile package
  - A package's downloads, stars, or behavior look suspicious
  - Do NOT use for known-good, widely-used packages where the answer is obvious
context: fork
allowed-tools: "Read, Grep, Bash, WebFetch"
---

# Vet a Dependency

`npm audit` catches known CVEs in packages you already trust. This is the other problem: deciding whether to trust a package in the first place. The goal is an evidence-backed verdict, not a vibe.

## What to gather

Pull the facts before judging. Use `npm view <pkg>`, the npm and GitHub pages, and the published tarball.

- **Downloads vs. stars vs. dependents.** A package with thousands of weekly downloads, single-digit stars, and no dependents is a mismatch worth explaining. Real adoption shows up in all three. Check the download *shape* too: organic growth is a curve; isolated single-day spikes with dead baseline around them are manufactured.
- **Install scripts.** Read `package.json` for `preinstall`, `install`, `postinstall`. Anything that runs on install is the highest-risk surface, read exactly what it does.
- **`curl | sh` and friends.** Any install step that pipes a remote script into a shell, or `npx`-runs a second package, or registers a persistent MCP server, is a red flag. The package should do what its README says and nothing the README doesn't.
- **What it actually does vs. claims.** Read the real entry points. Network calls, child_process, filesystem writes outside its own dir, env/credential reads, and telemetry that the README doesn't disclose are all findings.
- **Obfuscation.** Minified-only source with no readable repo, `eval`, base64 blobs, or dynamic `require` of constructed strings. Legitimate packages ship readable code.
- **Maintainer and provenance.** Account age, other packages, repo activity, whether the npm package's repo link actually matches a real, public repo. A brand-new author with one oddly-popular package warrants more scrutiny.
- **Typosquatting.** Is the name one character off a popular package? Is it impersonating a known scope?
- **License sanity.** Missing, contradictory, or relicensed-from-someone-else (a file marked MIT that's actually CC-BY upstream) is both a legal and a trust signal.

## How to judge, and how to phrase it

Separate what the evidence supports from what it doesn't. This is the discipline that keeps a verdict defensible:

- You can say a package **behaves in ways that warrant caution** and point at the exact behavior (an undisclosed postinstall, a downloads/stars mismatch, an undisclosed network call). That's an evidence claim.
- You generally **cannot** say it "is malware" or attribute it to a specific actor or coordinated scheme. Intent and authorship usually aren't provable from the artifact. Don't claim what you can't show.
- Stars and dependents are a truer adoption signal than downloads, which are cheap to manufacture. Weight accordingly.

## Output

A short report:

- **Verdict**: Safe to add / Add with caution / Avoid.
- **Evidence**: the specific findings, each tied to what you observed, in order of severity.
- **If "caution" or "avoid"**: what would have to change to trust it, or a safer, more-adopted alternative.

Never soften a real finding to be agreeable, and never inflate a thin one into an accusation. Report what the artifact shows.
