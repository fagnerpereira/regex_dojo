---
name: database
description: >
  Database design and query optimization for Rails — indexing strategy,
  constraints over validations, EXPLAIN analysis, data types per adapter
  (PostgreSQL, MySQL, SQLite), and multi-database setup. Use when designing
  schemas, choosing column types, diagnosing slow queries, adding indexes,
  or configuring databases. (Schema CHANGES → use the /migration skill.)
---

# Database design & optimization

Division of labor: THIS skill = what the schema/queries should BE.
The /migration skill = how to GET there safely. Adapter quirks for both live
in the migration skill's references/{postgresql,mysql,sqlite}.md — reuse them.

## Constraints over validations (the DHH/37signals rule)

AR validations are advisory (skipped by update_all, upsert, racing requests).
The database is the last line of defense — encode invariants there:

```ruby
create_table :orders do |t|
  t.references :user, null: false, foreign_key: true   # presence + integrity
  t.string  :status, null: false, default: "pending"
  t.integer :total_cents, null: false, default: 0
  t.timestamps
end
add_check_constraint :orders, "total_cents >= 0", name: "orders_total_nonneg"
add_index :orders, [:user_id, :status]
add_index :users, "lower(email)", unique: true          # PG; MySQL: collation handles it
```
Rule: every AR validation that protects data integrity (presence on FK,
uniqueness, numericality bounds, inclusion) gets a DB twin (null: false,
unique index, check constraint, FK/enum). Uniqueness WITHOUT a unique index
is a race condition, not a validation.

## Indexing strategy

1. **Always index**: every FK (`references` does it by default — verify),
   every column in WHERE/ORDER BY of a real query, polymorphic pairs
   (`[:imageable_type, :imageable_id]`).
2. **Composite order matters**: leftmost-prefix rule — `[:user_id, :status]`
   serves `user_id` alone and `user_id+status`, NOT `status` alone.
   Equality columns first, range/sort columns last.
3. **Don't over-index**: each index taxes every write and competes for
   buffer cache. Find unused (PG):
   `SELECT indexrelname, idx_scan FROM pg_stat_user_indexes WHERE idx_scan = 0;`
4. **Specialized** (PG, details in migration refs): partial
   (`where: "deleted_at IS NULL"`), expression (`lower(email)`),
   covering (`include:`), GIN (jsonb/arrays/full-text).
5. Adding ANY index → /migration skill (concurrently on PG).

## Reading EXPLAIN

```ruby
User.where(email: e).joins(:orders).explain          # AR helper
User.where(...).explain(:analyze, :buffers)          # Rails 7.1+: real execution (PG)
```
Red flags: `Seq Scan` on a large table inside a filter (missing/unusable
index); rows estimate wildly off actual (stale stats → ANALYZE); `Filter`
removing most rows AFTER an index scan (index doesn't cover the predicate);
Nested Loop over big sets (missing join index). MySQL: `EXPLAIN ANALYZE`
(8.0.18+), watch `type: ALL` (full scan) and `Using filesort`.

## Query-layer rules

- N+1: `includes`/`preload`/`eager_load` decision + `strict_loading` in
  dev/test (see field manual Part 7); `.load_async` (7.0+) for parallel
  independent queries in one action.
- Batch everything unbounded: `find_each`/`in_batches`, never `.all.each`.
- `pluck`/`pick` over instantiating models for scalar reads;
  `exists?` over `present?`; `update_all`/`upsert_all` for bulk (knowing
  they skip callbacks/validations — that's the point AND the danger).
- Write-time over read-time: counter caches, denormalized roll-ups
  maintained by the writer, not computed per-read.

## Data type decisions (cross-adapter defaults)

| Need | Use | Never |
|---|---|---|
| Money | integer cents (+ currency col) | float |
| Timestamps | datetime (Rails = UTC) + iso8601 out | strings |
| Enum-ish status | integer + AR enum (or PG native enum) | bare strings everywhere |
| Flexible blob | jsonb (PG) / json (MySQL) + store_accessor | serialized YAML |
| IDs at scale | bigint (Rails 5.1+ default) | int (2.1B ceiling) |
| Public IDs | uuid (PG native) or prefixed token (has_secure_token) | exposing sequential ids when enumeration matters |
| Text search | PG tsvector+GIN; MySQL FULLTEXT | LIKE '%...%' on big tables |
Adapter-specific types: see /migration references (PG: jsonb/arrays/ranges/
enums/EXCLUDE; MySQL: utf8mb4 mandatory, index byte limits; SQLite: type
affinity — lengths unenforced).

## Multi-database (Rails 6+, the Solid-era default shape)

```yaml
production:
  primary:  { <<: *default }
  queue:    { <<: *default, database: app_queue, migrations_paths: db/queue_migrate }
  cache:    { <<: *default, database: app_cache, migrations_paths: db/cache_migrate }
  replica:  { <<: *default, replica: true }
```
- Solid Queue/Cache/Cable each get their own db (SQLite: separate files) —
  keeps their write volume and migration locks off the primary.
- Replicas: `connects_to database: { writing: :primary, reading: :replica }`
  + automatic role switching; remember replica lag for read-after-write.

## Database checklist (schema design PR)

```
- [ ] Every integrity validation has a DB twin (null/unique/check/FK)
- [ ] FKs indexed; composite indexes ordered equality-first
- [ ] Money in cents; timestamps UTC; status as enum
- [ ] No unbounded queries (batching/pagination at every collection)
- [ ] EXPLAIN run on the new query paths
- [ ] Schema change routed through /migration skill
```

## External gems (separate from base conventions)

`pghero` (PG dashboard: slow queries, unused indexes, bloat),
`database_consistency` (audits validation↔constraint mismatches — runs in CI),
`activerecord-import` (bulk insert pre-7.0; native insert_all/upsert_all now),
`scenic` (versioned SQL views), `fx` (functions/triggers as Ruby migrations),
`timescaledb` (PG extension gem — hypertables/continuous aggregates, only for
genuine time-series volume), `online_migrations`/`gh-ost` (see /migration).
