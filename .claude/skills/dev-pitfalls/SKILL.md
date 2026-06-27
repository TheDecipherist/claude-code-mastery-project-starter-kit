---
name: dev-pitfalls
description: Common pitfalls that are slow to troubleshoot and that tend to get "fixed" by going in circles, because the error message points nowhere near the actual cause. Use before and during git, project, and WSL work, checking a repo is initialized and node_modules is ignored, putting WSL projects on the right filesystem, opening a browser from WSL for auth, normalizing line endings, and matching import case. Check the layer here first instead of debugging the wrong one.
when_to_use: |
  - Starting git work in a directory (is it even a repo? is node_modules ignored?)
  - A WSL project is slow, hot reload / file watchers miss changes, or chmod / ssh permissions misbehave
  - A CLI needs to open a browser from WSL for an OAuth / SSO (Okta, Entra) login
  - CRLF/LF symptoms: `^M`, `bad interpreter: /bin/bash^M`, a deploy failing with "expected string, got object" or unmarshal errors, YAML or shell scripts breaking on one platform only
  - An import works locally but fails in CI (case sensitivity)
  - Writing or editing Kubernetes, Helm, Terraform, or other structured config where a field name or path could be guessed wrong (`service.port` vs `spec.ports[0].port`)
  - A cryptic error whose message misleads: `ENOSPC` (really the file-watcher limit), `exec format error` (really CPU arch mismatch), `dubious ownership` (really a UID mismatch), `EADDRINUSE` (really a leftover process), heap OOM
  - Do NOT use for application-level config or secrets, this is dev-machine, repo, and project-state hygiene
---

# Common Dev Pitfalls (check the layer before debugging it)

These cost hours because the symptom points at the wrong thing, and they're easy to "fix" by going in circles. When something matches below, check the cause here before debugging the code.

## Check project state before acting

Claude's frequent miss is assuming project state instead of verifying it. Two checks, stated plainly to the user:

- **Is it even a git repo?** Before staging, committing, or diffing, confirm the repo exists (`git rev-parse --is-inside-work-tree`). If it doesn't, say so directly, "this directory isn't a git repository yet, run `git init` first", rather than running git commands that fail confusingly or silently acting on a parent repo.
- **Is `node_modules` ignored?** Before the first commit, confirm `.gitignore` exists and lists `node_modules/`. Create `.gitignore` BEFORE `npm install` so it is never tracked. If it isn't ignored yet, say so before anything gets committed.

**`.gitignore` only ignores UNtracked files.** If `node_modules` (or `.env`, or build output) was already committed, adding it to `.gitignore` changes nothing, git keeps tracking it, and this is a classic "my .gitignore isn't working" loop. Untrack it, then commit:

```bash
git rm -r --cached node_modules
git commit -m "Stop tracking node_modules"
```

Confirm a rule actually bites with `git check-ignore -v node_modules`. Committed `node_modules` bloats the repo and breaks CI, its platform-specific compiled binaries fail on Linux runners. Same fix for anything that "won't stop showing up" after you ignored it.

## WSL: put the project on the Linux filesystem, not /mnt/c

The single biggest WSL pitfall, and Claude rarely thinks to check it. A project under `/mnt/c` (any Windows drive) is reached from Linux over a 9P bridge, so:

- file operations run 10-100x slower, `npm install`, `git status`, and test runs crawl
- `inotify` is flaky across the bridge, so file watchers fire intermittently, hot reload and test watchers "work randomly" then silently stop, which becomes a circular debugging session if you chase it as a config problem
- Linux permission bits are only emulated, `chmod +x` can silently fail and ssh rejects keys as "bad permissions"
- editor integration breaks: Claude often can't see your active selection or the code you've highlighted, so it's working blind on what you're pointing at

Keep repos on the Linux side (`~/projects/...`, `~/code/...`) and open them with VS Code Remote-WSL. If a project sits on `/mnt/c` and shows any of the above, that location IS the bug, move it:

```bash
mv /mnt/c/Users/<you>/projects/my-app ~/projects/
```

Use `/mnt/c` only when a file genuinely needs to live on the Windows side for a Windows GUI app.

**Don't chase this through settings.** The circular trap is treating intermittent watchers or a blind editor as a config problem and tweaking watcher polling, exclude globs, and a pile of VS Code settings. On a Windows machine showing these symptoms, check the path FIRST. If it's `/mnt/c`, the answer is almost always "you're on the Windows filesystem, open the folder in WSL (Remote-WSL) and move it to `~/`", say that before suggesting a single setting.

## Opening a browser from WSL (auth / SSO)

A CLI runs an OAuth/SSO login, tries to open a browser from WSL, and either nothing opens or it opens a browser that isn't signed into the corporate IdP (Okta, Entra), so the login fails. Why your own browser matters: the SSO session lives in your real Chrome profile, a fresh or other browser context doesn't have it.

**Default to launching your real Chrome** via an executable shim on PATH (`~/.local/bin/chrome`, `chmod +x`):

```sh
#!/bin/sh
exec "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" "$@"
```

```bash
export BROWSER=chrome   # in ~/.bashrc
```

That opens your actual browser, your bookmarks and your live Okta session, which is what you want about 99% of the time.

`wslview` (from the `wslu` package) is the alternative, but in a corporate setup the browser it routes to may not carry your IdP session, so the login page loads unauthenticated. Offer it as a fallback, not the default. If neither is configured, ask the user which they want (own Chrome vs wslview) before wiring it in.

**Check `$BROWSER` hasn't been hijacked.** `BROWSER` has two unrelated meanings: the desktop convention (which browser opens URLs, used by auth flows) and Playwright's test-runner convention, where `BROWSER=chromium` selects which browser to run tests in. If a Playwright project exports `BROWSER=chromium` globally (in `~/.bashrc` or a sourced `.env`) instead of setting it inline on the test command, it overrides your desktop browser, so auth flows either fail outright (no executable named `chromium` on PATH) or open Playwright's bundled Chromium, a clean isolated context with none of your sessions. Same class of problem as VS Code's built-in browser. Diagnose with `echo $BROWSER`: if it shows `chromium`, `firefox`, or `webkit`, that's the hijack. Keep `BROWSER=chrome` (your shim) for desktop and auth, and scope Playwright's to the command only: `BROWSER=chromium npx playwright test`.

**Use a shim, not a bash `alias`.** An alias exists only in interactive shells, so when a program execs `$BROWSER` it never sees the alias and the open silently fails, which is the exact programmatic case auth needs.

## Line endings: LF everywhere (CRLF is the silent killer)

Windows CRLF breaks things in ways that take forever to trace: YAML parsing wrong, shell scripts dying with `bad interpreter: /bin/bash^M`, Docker entrypoints not executing, diffs showing every line changed when nothing did. YAML and `.sh` scripts are the usual victims because a stray `\r` rides along invisibly.

**The symptom that wastes the most time: a deploy failing with a type error.** A Kubernetes apply (or any YAML-driven deploy) that throws "expected a string, got a map/object" or "cannot unmarshal object into ... string" usually has nothing wrong with the field it names. A stray `\r` from CRLF has broken how the parser reads the value, so a scalar gets read as a structure. The manifest looks correct because the `\r` is invisible, which is exactly why this eats hours: the error points at the data, not the line ending. Before debugging the field, the schema, or the value, check the file's line endings, normalize to LF and re-apply.

Make the repo LF-only with `.gitattributes` at the root:

```
* text=auto eol=lf
```

`text=auto` lets git detect text vs binary (binaries untouched); `eol=lf` forces LF in both the committed blob and the working tree, regardless of anyone's local `core.autocrlf`. For a repo that already committed CRLF, the attribute alone won't rewrite it, renormalize once: `git add --renormalize . && git commit -m "Normalize line endings to LF"`. Set `.editorconfig` `end_of_line = lf` so files are authored as LF too.

## Case sensitivity: Linux is strict, Windows and macOS usually aren't

`import './Button'` resolves on a case-insensitive Windows/macOS filesystem even when the file is `button.tsx`, then fails on Linux and CI with "module not found." Match import casing to the real filename exactly. The same trap hits two files differing only in case (`README.md` vs `Readme.md`): they coexist on Linux but collide or shadow each other on Windows/macOS.

## Don't guess config field names, look them up (especially Kubernetes)

Structured config (Kubernetes, Helm, Terraform, cloud CLIs) is a typed, nested schema of objects and arrays, not flat `KEY=VALUE`. Guessing a field path is how an hour disappears into `service.port` vs `spec.ports[0].port`. The exact path is one command away, so query it instead of guessing.

- **`kubectl explain <resource>.<path>`** returns the real schema, including whether a field is an object or an array. `kubectl explain service.spec.ports` shows `ports` is a list, so the value lives at `spec.ports[0].port`, not `spec.port`. Add `--recursive` for the full nested tree.
- **`kubectl get <resource> <name> -o yaml`** shows the actual structure and values of a live object. Read the path off that, then pull a value precisely with `-o jsonpath='{.spec.ports[0].port}'`.
- **`KEY=VALUE` is not how Kubernetes models things.** Env vars are a list of objects, `env: [{name: FOO, value: bar}]`, not a map `env: {FOO: bar}`. Ports, containers, and volumes are arrays too (`spec.containers[0].image`). Flat-config instincts break here.
- **Helm values are chart-specific.** `service.port` can be valid in one chart's `values.yaml` and meaningless in another, that structure is defined by the chart, not by Kubernetes. Run `helm show values <chart>` and read the real keys instead of carrying an assumed path between charts.

General rule: when a tool ships an introspection command (`kubectl explain`, `kubectl get -o yaml`, `helm show values`, `terraform state show`, `aws ... describe-*`, `gh api`), use it to get the exact names the first time. A two-second lookup beats an hour on a path that "looked right."

## Errors that lie about their cause

The worst time-sinks are errors whose message points at the wrong thing, so you debug what the text says for hours. When you see one of these, check the real cause first.

- **`ENOSPC: no space left on device`** from a dev server, `npm start`, Vite, nodemon, or VS Code is almost never disk space. It's the Linux inotify file-watcher limit (default ~8192), exhausted by a large project's file count. Confirm disk is fine with `df -h`, check the limit with `cat /proc/sys/fs/inotify/max_user_watches`, then raise it: `echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p`. Inside a container, set `CHOKIDAR_USEPOLLING=true` instead.
- **`exec format error`** (`exec /entrypoint.sh: exec format error`, or `standard_init_linux.go: ... exec format error`) means the binary's CPU architecture doesn't match the host: an arm64 image on an amd64 host or the reverse. Common now that dev laptops are ARM (Apple Silicon) while prod or CI is x86 (or ARM Graviton). Image metadata can claim the right arch while the binary inside doesn't, so trust `file <binary>` run inside the container over `docker inspect`. Fix: pull/run with `--platform linux/amd64`, or build multi-arch with `docker buildx build --platform linux/amd64,linux/arm64`. Second possible cause: CRLF in the entrypoint script (see line endings above), check that too.
- **`fatal: detected dubious ownership in repository`** is a UID mismatch, not corruption: the repo files are owned by a different user than the one running git. Classic on `/mnt/c` (Windows files look root-owned to WSL) and in containers (host UID does not match container UID). Git offers the band-aid (`git config --global --add safe.directory <path>`), but the durable fix is matching ownership: `chown -R $(whoami) <repo>`, moving the repo to `~/`, or running the container with `--user $(id -u):$(id -g)`.
- **`EADDRINUSE: address already in use`** is a leftover process holding the port, usually a dev server that didn't exit. Find and kill it: `lsof -t -i:3000 | xargs kill`, or use another port. Don't reconfigure the app.
- **`JavaScript heap out of memory`** is V8's default heap ceiling, not always a leak. For a heavy build, raise it: `NODE_OPTIONS=--max-old-space-size=4096`. If it recurs at low memory, then look for a real leak.

---

This skill is built to grow. Each new pitfall is another short section: the symptom you actually see, the cause, and the fix that ends the loop.
