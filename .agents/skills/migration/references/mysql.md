# MySQL / MariaDB — dangerous operations & safe recipes

Locking model differs from PG in your favor and against it:

- Table rewrites block **WRITES only** (reads continue) — milder than PG.
- BUT: no `CONCURRENTLY`, no transactional DDL (each DDL auto-commits — a
  failed multi-statement migration leaves PARTIAL state; keep migrations
  single-operation), and no `validate: false` two-phase for NOT NULL.
- The mitigations are **InnoDB Online DDL** (`ALGORITHM=INPLACE/INSTANT`) and,
  for huge tables, external tools (gh-ost, pt-online-schema-change).

## ✅ Safe (modern MySQL 8.0+ / MariaDB 10.3+)

- `add_column` (plain) — **ALGORITHM=INSTANT** in MySQL 8.0.12+ / MariaDB 10.3.2+
  (metadata-only, even with a default). Caveat: 8.0.29+ allows any position;
  before that, only appended (last) columns are INSTANT.
- `add_index` / `remove_index` — **INPLACE**: builds online, writes permitted
  (brief locks at start/end). No `algorithm: :concurrently` needed or available.
- `add_column ... default` — instant (unlike old MySQL 5.x lore)
- rename_column / rename_index — INPLACE metadata change in 8.0
  (BUT still app-breaking during deploy → two-phase recipe applies; the
  danger here is old code, not the lock)

## ❌ Dangerous → recipe

### change_column type (table COPY — blocks writes, can take hours)

No safe in-place type change for most conversions. Recipe:

- Normal tables → dual-column pattern (zero-downtime.md)
- Huge/hot tables → gh-ost or pt-online-schema-change (external gems/tools
  section; they replay binlog while copying)
  Safe-ish exceptions: extending VARCHAR length **within the same byte-length
  bucket** (≤255 stays ≤255) is INPLACE; crossing 255 forces a COPY.
  ENUM value APPEND is INSTANT; reorder/remove is a COPY.

### NOT NULL on existing column

MySQL `MODIFY ... NOT NULL` rebuilds (INPLACE but full rebuild — writes
blocked on metadata locks under load). Recipe:

1. Backfill NULLs in batches first.
2. MySQL 8.0+: add a CHECK constraint NOT ENFORCED is useless here — instead
   run the `change_column_null` during a low-traffic window with
   `lock_wait_timeout` set low, after verifying zero NULLs:
   `SELECT COUNT(*) FROM users WHERE email IS NULL;` must be 0.
3. Tables too hot for any window → gh-ost the change.

### add_check_constraint (8.0.16+; blocks writes while every row checks)

No `validate: false` equivalent that's later enforceable without a scan.
Backfill/clean data FIRST so the scan is fast, run in low-traffic window.

### Foreign keys

`add_foreign_key` requires an index on the referencing column (MySQL creates
one implicitly if missing — surprise index!). Add your own index explicitly
first. FK addition locks both tables briefly; on hot tables consider whether
you need DB-level FK at all vs app-level + periodic integrity check.

### Auto-increment / primary key changes — full table COPY, writes blocked

And with statement-based replication, can produce different values on
replicas. Treat like a rename: new table, sync, swap (or gh-ost).

## MySQL-specific gotchas Rails devs hit

- Index key length limit: utf8mb4 VARCHAR(255) index = 1020 bytes > 767-byte
  limit on old row formats → use `ROW_FORMAT=DYNAMIC` (8.0 default) or
  `length: { email: 191 }` on the index.
- No transactional DDL → migration files MUST be single-operation so a crash
  never leaves half-applied state you can't rerun.
- `utf8` is NOT UTF-8 — always `utf8mb4` + `utf8mb4_0900_ai_ci` (8.0).
- Explicit algorithm assertion (fails loudly instead of silently copying):

  ```ruby
  execute "ALTER TABLE users ADD COLUMN nick VARCHAR(50), ALGORITHM=INSTANT"
  # If INSTANT impossible, this RAISES instead of falling back to COPY
  ```

## Timeouts

```yaml
# config/database.yml
production:
  variables:
    lock_wait_timeout: 10 # seconds; metadata lock wait
    max_execution_time: 3600000 # ms; read-statement ceiling (8.0+)
```

## External tools (separate from base conventions — for huge tables only)

- **gh-ost** (GitHub): triggerless online schema change via binlog replay
- **pt-online-schema-change** (Percona): trigger-based equivalent
  Both: copy table + replay changes + atomic cutover. Reach for them when the
  dual-column recipe is impractical (very hot, very large tables).
