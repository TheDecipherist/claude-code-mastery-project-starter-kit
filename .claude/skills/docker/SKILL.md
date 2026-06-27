---
name: docker
description: Production Docker best practices for writing Dockerfiles, Compose files, and Swarm stacks. Use whenever creating or editing a Dockerfile, a docker-compose / compose.yaml, or a stack file, or building and optimizing an image. Fixes the handful of things Claude reliably gets wrong: multi-stage builds, layer-cache ordering, exec-form ENTRYPOINT for correct signals and exit codes, init:true, keeping secrets and env out of the image, non-root users, and healthchecks. From production, not defaults.
when_to_use: |
  - Writing or editing a Dockerfile, a Compose file, or a Swarm stack file
  - Building, slimming, or speeding up an image
  - Debugging containers that won't stop gracefully, leave zombie processes, or ignore SIGTERM
  - Deciding how config, env, and secrets reach a container
  - Do NOT use for orchestration choices unrelated to packaging (cluster sizing, cloud provider selection)
---

# Docker: Production Image and Compose Rules

From production, not defaults. Claude's Dockerfiles tend to be wrong in the same few ways. Fix them here.

## Dockerfile

- **Multi-stage builds, always.** Build in a stage that has the compilers and dev dependencies, then `COPY --from=build` only the artifacts into a slim runtime stage. The runtime image carries no build tools, which cuts size hard (a real build went from ~2GB to ~200MB) and removes a pile of CVEs.
```dockerfile
FROM node:22 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-slim AS runtime
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
USER node
ENTRYPOINT ["node", "dist/server.js"]
```

- **Order layers by how often they change: stable first, source last.** Docker caches each layer and rebuilds every layer after the first one whose inputs changed. So copy the dependency manifest and install deps BEFORE copying source: `COPY package*.json ./` then `RUN npm ci` then `COPY . .`. Copy source first and a one-line code change reinstalls every dependency, every build.

- **The runtime command is `ENTRYPOINT`/`CMD` in exec form, never `RUN`.** `RUN` executes at build time; the container's process belongs in `ENTRYPOINT ["node","server.js"]` (a JSON array). Use exec form, not shell form (`ENTRYPOINT node server.js`): shell form runs your app under `/bin/sh -c`, so `sh` is PID 1, it swallows `SIGTERM`, and your app never shuts down gracefully (Docker waits out the grace period then SIGKILLs it) and its exit code is lost. Exec form makes your process PID 1 so signals and exit codes propagate. `ENTRYPOINT` for the executable, `CMD` for default args.

- **Pin base image versions.** `FROM node:22.3.0-slim`, not `node:latest`. `latest` makes builds non-reproducible and shifts under you silently. Pin a tag (or a digest for full reproducibility), and expose it as an `ARG` so it's easy to bump deliberately.

- **Add a `.dockerignore`.** Exclude `node_modules`, `.git`, `.env`, `dist`, and local junk. Without it the whole directory ships as build context (slow), busts the cache on unrelated changes, and can bake a stale `node_modules` or a secret file into the image.

- **Run as non-root.** Containers run as root by default. Add a `USER` (for example `USER node`) before the entrypoint so a container escape isn't root on the host.

- **Add a `HEALTHCHECK`.** Swarm and Compose use it to know a container is actually ready, which is what makes rolling updates and automatic rollback work. Without it, "running" only means the process started, not that it serves traffic.

- **Combine and clean in one `RUN`.** `apt-get update && apt-get install -y ... && rm -rf /var/lib/apt/lists/*` in a single layer. A separate `update` layer goes stale behind the cache, and the cleanup only shrinks the image if it happens in the same layer that added the files.

## Compose and Swarm

- **`init: true` on every service.** The one always missed. It runs a tiny init (tini) as PID 1 that forwards signals to your process and reaps zombie children. Without it, signal handling and zombie reaping become your app's problem and `docker stop` often hangs to the timeout. Pair it with an exec-form ENTRYPOINT.

- **Set resource `limits` AND `reservations`.** Reservations make the scheduler place the container only where the resources exist; limits cap it so a runaway container can't take down the node. Both, not one.

- **Configure rolling updates and rollback.** `update_config` with `parallelism: 1`, a `delay`, `order: stop-first` (or `start-first` for blue-green), and `failure_action: rollback`. Combined with a HEALTHCHECK, a bad deploy rolls itself back instead of taking the service down.

- **Reference services by name, never by IP.** Container IPs change on every restart, scale, and update. Use the service name and let Docker DNS resolve it (`backend-service:8080`). A hardcoded IP is a guaranteed future outage.

- **Substitute env with defaults.** `replicas: ${NGINX_REPLICAS:-2}` and `image: registry/app:${BUILD_VERSION:-latest}` keep one file working across environments through `.env`.

## Secrets and config

- **Never bake secrets into the image.** `ARG` and `ENV` values are stored in image layers and show up in `docker history`, so a secret written into the Dockerfile is a leaked secret. Use BuildKit build secrets (`RUN --mount=type=secret,id=...`) for build time, and Docker secrets (mounted at `/run/secrets/<name>`) or runtime env for run time. Docker secrets are encrypted at rest, never appear in `docker inspect`, and are scoped to the services that mount them.

- **Secrets for sensitive, configs for the rest.** Docker `secret` for certs, keys, and passwords (encrypted); Docker `config` for non-sensitive files like an IP blocklist (not encrypted, but versioned and injected the same way). Neither goes in the image, both are injected at deploy.

- **Log to stdout/stderr, not to files inside the container.** Write to `/dev/stdout` and `/dev/stderr` so Docker's logging driver and your aggregator collect them. Logging to a file inside the container hides the output and fills the writable layer.

---

This skill is built to grow. Add a rule when a real Dockerfile or stack failure has a stable, defensible fix.
