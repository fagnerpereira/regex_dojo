# PostgreSQL — dangerous operations & safe recipes

PG locking model: DDL takes ACCESS EXCLUSIVE; a **table rewrite blocks READS
AND WRITES** for its duration. The win: PG has `CONCURRENTLY` for indexes and
`NOT VALID` for constraints — use them.

## ✅ Safe on PostgreSQL (modern versions)
- `add_column` without default — metadata only, instant
- `add_column` WITH constant default — **PG 11+**: instant (no rewrite).
  Volatile defaults (`gen_random_uuid()`) still rewrite → add then backfill.
- `drop_table` / `remove_column` (locking-wise; the danger is cached columns → two-deploy rule)
- `add_reference ... index: false` then concurrent index separately

## ❌ Dangerous → recipe

### add_index (blocks WRITES while building)
```ruby
class AddIndexToUsersEmail < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!    # REQUIRED for concurrently
  def change
    add_index :users, :email, algorithm: :concurrently
  end
end
```
- One index per migration (DDL transaction disabled).
- If a concurrent build fails it leaves an INVALID index: drop and retry
  (`remove_index :users, :email, algorithm: :concurrently` then re-add).
- `add_reference`: pass `index: false`, add the index concurrently after.
- remove_index: also supports `algorithm: :concurrently` (rarely needed).

### change_column type (TABLE REWRITE — blocks reads+writes)
Safe exceptions (metadata-only, no rewrite): varchar(n)→varchar(bigger n) or
varchar→text; decimal precision increase (same scale); timestamp→timestamptz
ONLY when session TZ is UTC (PG 12+).
Everything else → dual-column recipe in zero-downtime.md.

### NOT NULL on existing column
```ruby
# Migration 1 — instant, doesn't check existing rows
add_check_constraint :users, "email IS NOT NULL", name: "users_email_null", validate: false
# Migration 2 — validates while allowing reads/writes (SHARE UPDATE EXCLUSIVE)
validate_check_constraint :users, name: "users_email_null"
# Migration 3 (PG 12+) — instant, uses the validated constraint as proof
change_column_null :users, :email, false
remove_check_constraint :users, name: "users_email_null"
```

### add_check_constraint / add_foreign_key (validation scans whole table, blocks writes)
```ruby
# Step 1: instant
add_check_constraint :orders, "price > 0", name: "orders_price_check", validate: false
add_foreign_key :orders, :users, validate: false
# Step 2: separate migration — non-blocking validation
validate_check_constraint :orders, name: "orders_price_check"
validate_foreign_key :orders, :users
```

### Adding a column with a VOLATILE default (uuid, now() per-row)
```ruby
add_column :users, :token, :uuid                       # 1. no default
change_column_default :users, :token, from: nil, to: -> { "gen_random_uuid()" }  # 2. for new rows
# 3. backfill existing in batches (separate migration/task)
# 4. then NOT NULL via the recipe above if needed
```

### Adding a JSON column → use :jsonb
`json` has no equality operator (breaks SELECT DISTINCT etc.); `jsonb` is
binary, indexable (GIN), and what you want every time.

### Primary key int→bigint (the classic capacity migration)
Full recipe is the dual-column pattern (zero-downtime.md) applied to id +
every referencing FK column. Plan this WAY before 2.1B rows.

## PostgreSQL-only powers (use them)
- Partial indexes: `add_index :cards, :board_id, where: "closed_at IS NULL", algorithm: :concurrently`
- Covering: `add_index :orders, :user_id, include: [:total_cents]` (PG 11+)
- Expression: `add_index :users, "lower(email)", unique: true`
- GIN for jsonb/arrays/full-text: `add_index :events, :payload, using: :gin`
- EXCLUDE constraints (e.g. no overlapping ranges), `tsrange`/`daterange` types
- `create_enum` + `t.enum` (Rails 7+) for true PG enums

## Operational
- Active locks during a stuck migration:
  `SELECT pid, state, wait_event_type, query FROM pg_stat_activity WHERE state != 'idle';`
- After adding an index, planner stats: `ANALYZE users;` (or analyze: true conventions)
- `EXPLAIN (ANALYZE, BUFFERS) SELECT ...` to verify the index is used
