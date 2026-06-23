---
name: migration
description: >
  Write safe, zero-downtime Rails migrations WITHOUT the strong_migrations gem —
  the safety rules are encoded here natively, per database adapter (PostgreSQL,
  MySQL/MariaDB, SQLite). Use whenever creating or reviewing a migration, adding
  columns/indexes/constraints, changing column types, renaming, backfilling data,
  or removing columns. ALWAYS use before running `rails generate migration`.
---

# Safe migrations, natively (no strong_migrations gem)

## Step 0 — Detect the adapter (rules differ per database)

```bash
scripts/detect_adapter.sh    # reads config/database.yml + Gemfile.lock
```

Then load ONLY the matching reference:
- PostgreSQL → `references/postgresql.md`
- MySQL/MariaDB (mysql2/trilogy) → `references/mysql.md`
- SQLite → `references/sqlite.md`
- Multi-step recipes (any adapter) → `references/zero-downtime.md`

## The danger test (strong_migrations' classification, applied manually)

An operation is dangerous if it either:
1. **Blocks reads or writes for more than a few seconds** (after acquiring a lock), or
2. **Has the potential to cause application errors** (cached columns, old code
   running against new schema during deploy).

Before writing ANY migration, classify each operation against the adapter
reference. If dangerous → use the safe recipe. Never "it's a small table" your
way past it — tables grow.

## Universal rules (all adapters)

1. **Generators first**: `bin/rails generate migration AddXToY x:type` — then edit.
2. **One concern per migration.** Index in its own migration (Postgres:
   `disable_ddl_transaction!` requires it). Constraint validation separate from
   constraint addition.
3. **Schema changes and data changes NEVER mix.** Backfills go in a separate
   migration (or a job/task) AFTER the schema migration deploys.
4. **Never reference models in migrations** — model code drifts; define an
   inline stub if needed:
   ```ruby
   class AddStatusBackfill < ActiveRecord::Migration[7.1]
     class User < ActiveRecord::Base; end   # frozen snapshot, no callbacks/validations
     def up = User.in_batches.update_all(status: "active")
   end
   ```
5. **Reversible always**: `change` when AR can invert it; explicit `up`/`down`
   otherwise; `raise ActiveRecord::IrreversibleMigration` honestly.
6. **Removing a column is a TWO-DEPLOY operation** (AR caches columns):
   - Deploy 1: `self.ignored_columns += ["legacy_field"]` in the model
   - Deploy 2: migration with `remove_column`
7. **Backfills**: `in_batches.update_all` (no instantiation, no callbacks),
   sleep between batches on hot tables, `disable_ddl_transaction!` so each
   batch commits independently.
8. **NOT NULL on existing column**: add check constraint with `validate: false`
   → validate in second migration → then `change_column_null` (adapter details
   in references).
9. **Renames (column OR table) are NEVER safe in one step** — old code runs
   against new schema during every deploy. Use the duplicate→sync→swap recipe
   in `references/zero-downtime.md`.

## Timeouts — set these regardless of gem usage

```ruby
# config/database.yml (postgresql) — short lock wait, generous statement time
production:
  variables:
    lock_timeout: 10s            # give up fast if blocked → retry later
    statement_timeout: 1h        # but let legit long ops finish
# MySQL: lock_wait_timeout / max_execution_time — see references/mysql.md
```

## Safety checklist (paste into every migration PR — vep-agents style)

```
Migration Safety:
- [ ] Adapter rules consulted (references/<adapter>.md)
- [ ] No dangerous op without its safe recipe
- [ ] Index changes isolated (+ algorithm: :concurrently on PG)
- [ ] No data changes mixed with schema changes
- [ ] No app models referenced (inline stub if needed)
- [ ] Reversible (or explicitly irreversible)
- [ ] Column removal: ignored_columns deployed FIRST
- [ ] Backfill batched, throttled, idempotent
- [ ] bin/rails db:migrate && db:rollback && db:migrate passes locally
```

## External gems (OPTIONAL — separate from these base conventions)

These rules make strong_migrations unnecessary, but if a project already uses
it, don't fight it — it enforces the same rules automatically. Related external
gems, evaluate per the gem policy (maintenance/weight/removability):
`strong_migrations` (automated enforcement), `online_migrations` (adds safe
helpers), `maintenance_tasks` (Shopify; interactive backfills), `gh-ost`/
`pt-online-schema-change` (MySQL external tools for huge tables).
