---
name: nodejs
description: Node.js backend runtime and process-lifecycle rules that Claude reliably gets wrong. Use when writing a Node server or long-running script, an Express app, worker threads, or process signal handling, and when choosing packages. Covers correct graceful shutdown, crash-on-fault instead of swallowing errors, not blocking the event loop, loading instrumentation first, securing the session cookie, and replacing deprecated packages with built-ins. Defers MongoDB to mongodb-rules, schema/validation to schema-source-of-truth, and image/deploy to docker and docker-swarm.
when_to_use: |
  - Writing a Node server (`server.js`, Express) or a long-running script or worker
  - Adding or reviewing process signal handling, graceful shutdown, or error handling
  - CPU-heavy work that might block the event loop
  - Choosing an HTTP client, UUID lib, date lib, or any dependency with a modern built-in
  - Do NOT use for Mongo query shape (mongodb-rules), validation schemas (schema-source-of-truth), or Dockerfiles (docker)
---

# Node.js: Process Lifecycle and Runtime Rules

Claude writes Node services that work in a demo and fall over in production, almost always around the process lifecycle. These are the parts to get right.

## Graceful shutdown, done correctly

A server must shut down cleanly on `SIGTERM` (what `docker stop`, Swarm, and Kubernetes send) and `SIGINT` (Ctrl-C). Claude usually omits this entirely, so the orchestrator waits the grace period and then SIGKILLs, dropping in-flight requests. The correct sequence is: stop accepting new connections, drain in-flight ones, close dependencies, exit 0, with a hard timeout so a stuck connection can't block shutdown forever.

```javascript
const server = app.listen(port);
let shuttingDown = false;

async function shutdown(signal) {
  if (shuttingDown) return;                 // ignore repeat signals
  shuttingDown = true;
  logger.info("shutting down", { signal });

  const force = setTimeout(() => {           // drain hung? force it
    logger.error("shutdown timed out, forcing exit");
    process.exit(1);
  }, 10_000);
  force.unref();

  try {
    await new Promise((r) => server.close(r)); // stop new conns, let in-flight finish
    await db.close();                          // then close DB, redis, change streams
    clearTimeout(force);
    process.exit(0);
  } catch (err) {
    logger.error("error during shutdown", { err });
    process.exit(1);
  }
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT",  () => shutdown("SIGINT"));
```

Two things that look fine but are bugs: do not put async cleanup in a `process.on("exit", ...)` handler, the event loop is already stopped so nothing async runs, `exit` is for synchronous work only. And do not trap `SIGUSR1`, Node uses it for the debugger. This only works if the process actually receives the signal, which means an exec-form `ENTRYPOINT` so Node is PID 1 (see the docker skill) and `init: true` so signals are forwarded (see docker-swarm).

## Let it crash, never swallow a fault

On `uncaughtException` or `unhandledRejection` the process is in an unknown, possibly corrupt state. Log it and exit non-zero, let the orchestrator restart a clean process. Do not catch-and-continue. Modern Node already terminates on an unhandled rejection by default, so code that relies on swallowing one is both wrong and fragile.

```javascript
process.on("uncaughtException", (err) => {
  logger.error("uncaught exception", { err });
  process.exit(1);            // exit non-zero so restart_policy: on-failure restarts
});
process.on("unhandledRejection", (reason) => {
  logger.error("unhandled rejection", { reason });
  process.exit(1);
});
```

The non-zero exit is what makes Swarm/K8s self-healing fire, an `exit(0)` on a crash reads as success and the dead service is never restarted (see docker-swarm). You can route these through `shutdown()` to drain first, but never let the process keep serving after one.

## Don't block the event loop

Node runs your JavaScript on a single thread. A CPU-bound stretch, parsing a huge payload, hashing, image work, a tight loop over a large array, freezes every concurrent request until it finishes. I/O is already async and is not the problem. For real CPU work, offload to `worker_threads`, not `child_process` (for in-process JS) and not "just make it async" (await doesn't yield during a synchronous loop).

```javascript
const { Worker } = require("node:worker_threads");
new Worker("./workers/process.js", {
  workerData,
  resourceLimits: { maxOldGenerationSizeMb: 512 },  // cap so one worker can't OOM the host
});
```

## Load instrumentation before anything else

APM and tracing libraries (`dd-trace`, the OpenTelemetry SDK) work by monkey-patching `http`, `express`, and your DB driver. They can only patch modules loaded after them, so the init call must be the very first thing in the entry file, before any `require("express")`. Required late, it silently instruments nothing.

```javascript
// server.js, line 1
require("dd-trace").init({ /* ... */ });
const express = require("express");   // now traced
```

## Lock down the session cookie

When Claude sets up sessions it usually sets `httpOnly` and stops. Set all three: `httpOnly` (no JS access), `secure` in production (HTTPS only), and `sameSite` (CSRF defense), which is the one that gets missed.

```javascript
cookie: { httpOnly: true, secure: isProd, sameSite: "lax", maxAge: 86_400_000 }
```

Related CORS gotcha: `credentials: true` cannot be combined with `origin: "*"`, the browser rejects it. Echo a specific allowed origin instead.

## Reach for built-ins, replace deprecated packages

Claude's training pulls in libraries that are now deprecated or unnecessary. Prefer the platform:

- `crypto.randomUUID()` over the `uuid` package for a v4 id, and `uuid` over `node-uuid`
- native `fetch` (Node 18+) or `axios` over `request` (unmaintained since 2020)
- `node:test` + `node:assert` for simple suites, `structuredClone()` over a deep-clone dep
- the Intl APIs or `date-fns`/Temporal over `moment` (in maintenance mode)
- `@aws-sdk/client-*` v3 (modular) over the monolithic `aws-sdk` v2
- `sass` (dart-sass) over the deprecated `node-sass`

Use the `node:` prefix on built-in imports (`require("node:fs")`) so there's no ambiguity with a same-named package.

## Two smaller ones

- **Logging:** a structured logger (pino or winston) emitting JSON to stdout in production, never `console.log` in a hot path. stdout because the container's logging driver collects it (see docker).
- **PM2:** cluster mode is for using all cores on a VM or bare-metal host. Inside a Swarm or K8s container, run one Node process and scale with replicas plus `init: true`, don't stack two process managers that both try to own restarts.

---

This skill is built to grow. Add a rule when a real Node production failure has a stable, defensible fix.
