---
name: mongodb-replica-sets
description: Production MongoDB replica-set operation: topology, durability, host tuning, and the container-specific gotchas Claude gets wrong. Use when setting up or configuring a replica set, writing its connection string, choosing read preference or write concern, running MongoDB in Docker or Swarm, or planning failover and upgrades. Covers odd-member quorum, connecting via the set rather than one node, WiredTiger cache sizing, the OS tuning MongoDB requires, why ingress-mode ports break a replica set, and oplog/failover discipline. Defers query and index shape to mongodb-rules and backup pipelines to mongodb-backups.
when_to_use: |
  - Setting up, configuring, or initializing a replica set, or writing its connection string
  - Choosing read preference or write concern, or reasoning about staleness and durability
  - Running MongoDB in Docker or Docker Swarm
  - Sizing the WiredTiger cache, tuning the host, sizing the oplog, or planning failover/upgrades
  - Do NOT use for query/aggregation/index shape (mongodb-rules) or backup pipelines (mongodb-backups)
---

# MongoDB Replica Sets in Production

How to run a replica set, not how to query it (that's mongodb-rules). These are the operational decisions Claude tends to get wrong.

## Topology: odd voting members, real hostnames, never localhost

Use an odd number of voting members, three, so a majority can still elect a primary when one is lost. A two-member set has no majority if either dies, it goes read-only. Avoid arbiters unless you truly must: an arbiter holds no data, so a three-node primary-secondary-arbiter set that loses its one data secondary can no longer satisfy `w:"majority"`. Address every member by a hostname that all other members and all clients can resolve and reach; `localhost` in the config is a classic break, the other members can't reach it. Initialize once, from a single member, after all members are up, and wait for the election before creating users.

```javascript
rs.initiate({ _id: "rs0", members: [
  { _id: 0, host: "mongo1.internal:27017", priority: 2 },
  { _id: 1, host: "mongo2.internal:27017", priority: 1 },
  { _id: 2, host: "mongo3.internal:27017", priority: 1 }
]})
```

## Connect to the set, not to one node

The connection string must list the seed members and name the set, so the driver can find the current primary and follow failover. Pointing the app at a single host throws away the high availability the replica set exists to provide.

```
mongodb://mongo1,mongo2,mongo3/db?replicaSet=rs0
```

## Durability and reads

Writes always go to the primary. `w:"majority"` means a majority of members acknowledged before the app gets the OK, that is durability, use it for data you can't lose; `w:1` (primary only) is fine for the regenerable. Add `wtimeoutMS` so a degraded set doesn't block writes forever. Reads default to the primary and are strongly consistent. Secondaries are eventually consistent, they lag, so only route reads to them (`secondaryPreferred`, `secondary`, or `nearest`) when stale data is acceptable, analytics and reporting, not a read-after-write the user just made.

## Authentication between members

A replica set needs internal auth or any host can join. Generate a keyfile (`openssl rand -base64 756`), share it across members, and enable `security.authorization: enabled` with the keyfile. Never expose 27017 to the internet, bind to the private network and firewall it. Use TLS for client and inter-node traffic when the network isn't fully trusted.

## OS tuning MongoDB actually requires (self-hosted)

These aren't optional polish, MongoDB warns about them and they cause real instability if skipped:

- **Disable Transparent Huge Pages (THP).** THP hurts database memory access patterns badly; set `enabled` and `defrag` to `never` at boot.
- **`vm.swappiness=1`.** Keep the working set in RAM instead of swapping out the cache.
- **Raise ulimits.** `nofile` and `nproc` to 64000/32000, the defaults are too low for a busy mongod's connections and threads.
- **XFS for the data volume.** MongoDB recommends XFS over ext4 for WiredTiger. Never put data on NFS or network storage, the latency wrecks it.

## WiredTiger cache, especially in a container

Set `--wiredTigerCacheSizeGB` explicitly from the container's memory limit, roughly half of it minus 1GB, and cap the container's memory in the deploy block. Don't rely on the default: it targets about half of system RAM, and the cache is only part of mongod's footprint (connections, aggregation, and sort buffers live outside it). An unset cache sized against the host plus those buffers will exceed a container limit and get the container OOM-killed. Leave headroom on purpose.

## Running it in Docker or Swarm

The replica-set-specific traps on top of the general docker and docker-swarm skills:

- **Publish the port in `mode: host`, never ingress.** The routing mesh load-balances `27017` across all three members, which breaks the replica set, clients and members must reach a specific member. Use `ports: [{ target: 27017, published: 27017, mode: host }]`.
- **Pin each member to its own node.** Without placement constraints all three can land on one host and you have zero fault tolerance. Label nodes and constrain each service (`node.labels.mongo.replica == 1`), one member per host.
- **Bind-mount the data directory to a host path.** Anonymous or named-without-bind volumes risk data loss on recreation and are hard to back up. Pre-create the dir and `chown 999:999` (the image runs as UID 999). XFS host filesystem.
- **Real healthcheck, with a start period.** `test: ["CMD","mongosh","--eval","db.adminCommand('ping')"]` and `start_period: 60s`, so a slow first start isn't read as unhealthy.
- **Keyfile and root password via Docker secrets**, not plaintext env (which shows in `docker inspect` and image history).

## Oplog and failover discipline

The oplog is your recovery window: a secondary that falls further behind than the oplog covers needs a full resync, and point-in-time recovery can only reach back as far as the oplog. Size it for your write volume (24h minimum, 48 to 72h is a safer target; `db.getReplicationInfo()` shows the current window). Test failover on a schedule with `rs.stepDown()`, don't discover at an outage that the app doesn't reconnect. Roll upgrades secondaries-first, one at a time, step the primary down last, and let each node resync before moving on.

---

This skill is built to grow. Add a rule when a real replica-set operation has a stable, defensible fix.
