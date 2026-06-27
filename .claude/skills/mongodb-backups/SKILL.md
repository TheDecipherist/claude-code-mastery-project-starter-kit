---
name: mongodb-backups
description: Production MongoDB backup and restore practices that the documentation gets wrong. Use when writing a mongodump/mongorestore pipeline, a backup cron job, an S3 backup, or a selective restore, or when planning recovery. Covers streaming to object storage with no temp file, saving a collection inventory, the --nsInclude trap on gzipped archives, collection tiering for fast restores, and matching write concern to data criticality. Defers replica-set topology and tuning to mongodb-replica-sets, and query patterns to mongodb-rules.
when_to_use: |
  - Writing or reviewing a mongodump / mongorestore pipeline or backup cron job
  - Streaming a backup to S3 or other object storage
  - Doing a selective restore (only some collections) from a gzipped archive
  - Planning recovery, retention, or what to restore first during an incident
  - Do NOT use for replica-set setup or tuning (mongodb-replica-sets) or query shape (mongodb-rules)
---

# MongoDB Backups and Restore

From running thousands of production backups. The defaults and the docs leave out the parts that bite during an actual restore.

## Dump from a secondary, stream straight to object storage

Point mongodump at a secondary so the backup doesn't add load to the primary, and pipe the archive directly to S3 with no intermediate file on disk. On a replica set, `--oplog` captures a consistent point-in-time snapshot.

```bash
mongodump --host mongodb-secondary.internal:27017 \
  --username "$U" --password "$P" --authenticationDatabase admin \
  --db "$DB" --oplog --gzip --archive \
  | aws s3 cp - "s3://bucket/$DB/$(date +%Y%m%d_%H%M%S).dump.gz"
```

Keep a `latest.dump.gz` alias next to the timestamped file so restore scripts always know where to look.

## Save a collection inventory with every backup

You cannot inspect a `--gzip --archive` after the fact. There is no list, peek, or inspect flag, it's an opaque binary blob, and `--dryRun` finishes before the archive is demuxed so it tells you nothing. So write the collection list at backup time, right beside the dump:

```bash
mongosh --quiet --host "$HOST" -u "$U" -p "$P" --authenticationDatabase admin \
  --eval "db.getSiblingDB('$DB').getCollectionNames().forEach(c => print(c))" \
  | aws s3 cp - "s3://bucket/$DB/$(date +%Y%m%d_%H%M%S).collections.txt"
```

Six months later when you need a selective restore, you read the file instead of trying to remember what was in the archive.

## The `--nsInclude` trap on gzipped archives

The docs say `--nsInclude` filters a restore to specific collections. It does, from a directory dump (one `.bson` per collection). But from a `--gzip --archive`, which is what almost every production pipeline uses, `--nsInclude` (and `--nsFrom`/`--nsTo`) silently restore everything anyway and throw duplicate-key errors on the collections you never asked for. The archive is a single multiplexed stream that mongorestore can't seek, so the namespace filter doesn't hold. This is real and long-standing (JIRA TOOLS-2023, open over six years).

The reliable approach is the inverse: `--nsExclude` every collection you don't want, generated from the inventory file. Don't hand-build 100+ exclude flags at 2 AM, script it to read the inventory and emit the restore command.

## Tier collections so restore is a command, not improvisation

Decide ahead of time what gets restored, and keep the lists in the restore script:

- **Tier 1, critical business data** (orders, customers, products, inventory): always restore.
- **Tier 2, regenerable** (sessions, caches, tokens, search indexes): never restore. Restoring stale sessions is worse than having none, you log people back into dead state.
- **Tier 3, historical/analytical** (audit logs, history, analytics rollups): restore only on demand. This is the bulk of the exclude list.

When the incident hits you want to run a command, not write one.

## A replica set is only a backup at `w:"majority"`

Write concern quietly decides whether replication is durability or just a live mirror. `w:1` acknowledges on the primary alone, so a write lost before it replicates never existed anywhere else. `w:"majority"` means the data is on a majority of members before the app gets the OK. Match it to data criticality rather than setting one value globally: `w:"majority"` for data you can't lose, `w:1` for the regenerable and the disposable. See mongodb-replica-sets for the full read/write semantics.

## Test the restore before you need it

A backup you've never restored is a hypothesis. Practice the selective restore in staging, and time how long a replica-set member rebuilds from zero (delete a secondary's data dir, restart, and watch `db.adminCommand({ replSetGetStatus: 1, initialSync: 1 }).initialSyncStatus`). That number is what tells you, at 2 AM, whether to wait for self-healing or restore from backup. Point-in-time recovery needs `--oplog` backups plus `mongorestore --oplogReplay --oplogLimit "<ts>:<inc>"`.

One adjacent footgun that kills backups: unrotated MongoDB diagnostic logs fill the disk and the primary goes read-only. Set `systemLog.logRotate: rename` with rotation and alert on disk at 80%.

---

This skill is built to grow. Add a rule when a real restore surprise has a stable, defensible fix.
