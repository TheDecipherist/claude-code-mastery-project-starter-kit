---
name: docker-swarm
description: Production Docker Swarm deployment rules: what changes when a compose file goes from a single node to a multi-node Swarm. Use when writing or reviewing a stack file, a deploy block, an overlay network, or anything deployed with docker stack deploy. Covers the directives Swarm silently ignores, why fixed IPs and bind mounts break, the deploy orchestration block, and the exit-code and healthcheck discipline that Swarm self-healing depends on. Complements the docker skill, which covers writing the image and compose file itself.
when_to_use: |
  - Writing or reviewing a stack file or a `deploy:` block, or running `docker stack deploy`
  - Moving a compose file that works locally onto a multi-node Swarm
  - A service behaves differently deployed than it did with `docker compose up`
  - A rolling update hangs, a replica can't get an IP, or a service is "running" but dead
  - Designing overlay networks, placement, rolling updates, or rollback
  - Do NOT use for single-node Compose or image building, that is the docker skill
---

# Docker Swarm: Single Node to Multi-Node

Compose and Swarm read the same file and interpret it differently. The trap is that Swarm fails silently: the stack deploys, containers start, and something just doesn't work the way it did locally. Write the compose file for the multi-node world from day one and the single-node case still works.

## The mental model: a container is a process, not a computer

Swarm tears down and recreates containers constantly, on every update, node failure, scale, and rebalance. The new container has a new ID, a new IP, a new hostname, and a blank filesystem. Treat the container as disposable and keep all state outside it: a database or Redis for sessions, a named volume or object storage for files, env or Docker secrets/configs for configuration, stdout/stderr for logs. The test: if Swarm kills this container right now and starts a new one, does the app work identically? If not, state is leaking into the container.

## Directives Swarm silently ignores

`docker stack deploy` reads these and skips them with no error. If you relied on one locally, you debug for hours before realizing Swarm never read it.

`build` (Swarm only runs pre-built registry images), `container_name` (names collide with replicas), `depends_on` (no startup ordering, services start in parallel), `links`, `restart` (use `deploy.restart_policy`), `networks.ipv4_address` / `ipv6_address`, `network_mode`, `cap_add` / `cap_drop`, `devices`, `tmpfs`, `extra_hosts`, `sysctls`, `security_opt`, `cgroup_parent`, `userns_mode`. Capabilities, sysctls, and security options are set at the engine level on each node instead.

## Directives that change behavior in Swarm

- **`ports`** publish through the routing mesh: the port opens on every node, and traffic to any node is routed to a container wherever it runs. Publish the container port only (`- "61339"`) and let the mesh assign a host port, your reverse proxy reaches the service by name and never needs to know the host port.
- **`volumes`**: named volumes work everywhere; bind mounts to host paths break the moment a container is scheduled on a different node, because that path doesn't exist there. Use named volumes for data and Docker configs/secrets for files.
- **`networks`**: Compose defaults to `bridge` (single host). Swarm needs `overlay` (multi-host). A bridge network in a stack means services can't talk across nodes.

## Never hardcode an IP, the service name is the identity

Container IPs change on every restart, scale, and update. The service name is the one thing that never changes; Docker DNS resolves it to wherever the container currently lives. Hardcoding an IP breaks replicas, load balancing, and multi-node, but the worst case bites with a single replica during a routine rolling update: the new container needs an IP the dying old container hasn't released yet, and you can deadlock, the new one waits for the IP, the old one waits to be healthy, the update hangs, and rollback hits the same conflict. Connect by name (`mongodb://mongo:27017/mydb`) and none of it happens. A reverse proxy in the mesh needs a Docker-aware DNS resolver with a short TTL so it re-resolves names, see the nginx skill.

## The deploy block (Swarm-only orchestration)

These keys do nothing in plain Compose (except resource limits) but are what Swarm runs on:

```yaml
deploy:
  mode: replicated
  replicas: 6
  placement:
    max_replicas_per_node: 3        # 6 replicas then need 2+ nodes, spreads for HA
    constraints:
      - node.role == worker
  update_config:
    parallelism: 2
    delay: 10s
    order: start-first              # start new before stopping old, or stop-first
    failure_action: rollback        # bad deploy rolls itself back
  rollback_config:
    parallelism: 2
    delay: 10s
  restart_policy:
    condition: on-failure
    delay: 5s
    max_attempts: 3
    window: 120s
  resources:
    limits:                         # cap so a runaway container can't starve the node
      cpus: '0.50'
      memory: 400M
    reservations:                   # guarantee, scheduler places only where it fits
      cpus: '0.20'
      memory: 150M
```

## No `depends_on`, so the app must retry

Swarm starts services in parallel with no ordering. The app must connect to its dependencies with retry and exponential backoff rather than assuming the database is up. This is good engineering anyway, databases restart and connections drop in any production system.

## Self-healing depends on you, get exit codes and healthchecks right

Swarm (like Kubernetes) is blind to a service it can't measure. The four failures that actually kill production are the same on both, and both depend entirely on you:

- **Exit codes.** `restart_policy: on-failure` only restarts on a non-zero exit. An app that crashes but calls `exit(0)` is "success" and stays dead. Exit non-zero on failure.
- **Meaningful healthchecks.** A `/health` that always returns 200 even when the database is down reports healthy while serving errors. The check must verify real dependencies. Without any healthcheck, Swarm treats a hung or deadlocked container as healthy and keeps routing traffic to it.
- **Warm-up.** Use `start_period` so a slow-starting container isn't killed before it's ready.

Write the healthcheck and set the exit codes; the orchestrator does exactly what you tell it and nothing you don't.

## Overlay network and stack workflow

Pre-create an encrypted overlay, and pick a subnet that won't clash with your cloud VPC or default Docker ranges:

```bash
docker network create --opt encrypted --attachable --driver overlay \
  --subnet 172.240.0.0/24 awsnet
```

Reference it as `external: true` in the stack. Open Swarm ports between nodes: 2377/tcp (management), 7946/tcp+udp (node comms), 4789/udp (overlay). Note that `--opt encrypted` can fight cloud NAT, use internal VPC IPs when you enable it. Then build and push to a registry first (Swarm won't build), and deploy:

```bash
docker stack deploy -c docker-compose.yaml mystack
docker stack services mystack
docker service ps mystack_app --no-trunc   # full error text when a task won't start
```

---

This skill is built to grow. Add a rule when a real Swarm deployment surprise has a stable, defensible fix.
