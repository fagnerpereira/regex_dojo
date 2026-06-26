# SQLite — dangerous operations & safe recipes

Different threat model: SQLite locks the WHOLE DATABASE on write (one writer
at a time). With Rails 7.1+/8 defaults (WAL mode, busy_timeout, IMMEDIATE
transactions) it's production-viable for the right apps — but migrations
have unique constraints because SQLite's ALTER TABLE is minimal.

## What ALTER TABLE actually supports

- ADD COLUMN — instant (with restrictions below)
- RENAME COLUMN / RENAME TABLE — instant (3.25+)
- DROP COLUMN — instant-ish (3.35+) with restrictions (not if indexed/PK/unique)
- **EVERYTHING ELSE** (change type, change null, change default, add
  constraint to existing column) → Rails transparently does the
  **12-step table rebuild**: new table → copy ALL rows → drop → rename.
  On large tables this is a long full-database write lock.

## ✅ Safe

- `add_column` — but the default must be a CONSTANT (no functions); column
  can't be UNIQUE/PRIMARY KEY when added via ADD COLUMN; NOT NULL requires a
  non-null default.
- `add_index` — locks writes while building, but SQLite apps are typically
  small enough; no concurrent option exists.
- `rename_column`/`rename_table` — lock-wise instant; the TWO-DEPLOY app-code
  rule still applies (old code during deploy).

## ❌ Effectively dangerous (full table rebuild + db write lock)

- `change_column` (any type/null/default change on existing column)
- `remove_column` when the column is indexed or in a constraint
- `add_check_constraint` to an existing table (rebuild)
  Recipe: accept the rebuild during a deploy window (SQLite apps usually can),
  OR dual-column pattern if the table is genuinely large.

## Rails + SQLite production configuration (8.x style)

```yaml
# config/database.yml
production:
  adapter: sqlite3
  database: storage/production.sqlite3
  # Rails 8 defaults these; be explicit on 7.x:
  pragmas:
    journal_mode: wal # readers don't block writer
    synchronous: normal # safe with WAL, much faster
    busy_timeout: 5000 # wait instead of SQLITE_BUSY raise
    cache_size: 2000
    foreign_keys: true # OFF by default in SQLite!
```

- `foreign_keys: true` is critical — SQLite ignores FKs unless enabled per-connection.
- Rails 7.1+ uses IMMEDIATE transactions to reduce SQLITE_BUSY under write contention.

## SQLite-specific gotchas

- Type affinity, not types: `t.string limit: 50` is NOT enforced (no varchar
  truncation/validation) — enforce length in AR validations + CHECK constraints.
- No ALTER to add a FK to an existing table → rebuild path; declare FKs at
  create_table time.
- `disable_ddl_transaction!` is meaningless (and migrations run in a
  transaction is fine — SQLite DDL IS transactional, a failed migration
  rolls back cleanly — better than MySQL here).
- Backups: `sqlite3 prod.sqlite3 ".backup backup.sqlite3"` or Litestream for
  continuous replication. ALWAYS snapshot before a rebuild-class migration.
- Multi-database is the scaling pattern (Rails 8 style): separate sqlite
  files for cache/queue/cable keep migration locks off your primary db.

## When migrating away (SQLite → PG/MySQL)

Boolean storage (0/1), datetime formats, and case-insensitive LIKE differ.
Verify with the target adapter's reference file and a full spec run against
the target adapter BEFORE the switch.
