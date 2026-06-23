# Zero-downtime recipes (any adapter) — expand → migrate → contract

The universal cause of migration outages: **old code runs against new schema
during every deploy** (and new code against old schema with rolling deploys).
Every recipe below is the expand/contract pattern applied.

## Rename a column (the canonical multi-deploy recipe)

```
Deploy 1 (EXPAND):   add_column :users, :handle, :string
                     Model: write to BOTH (alias or callback):
                       alias_attribute :handle, :username   # if pure rename
                       # or: before_save { self.handle = username }
Deploy 2 (MIGRATE):  backfill: User.in_batches.update_all("handle = username")
Deploy 3 (SWITCH):   code reads :handle everywhere; stop writing :username
                     Model: self.ignored_columns += ["username"]
Deploy 4 (CONTRACT): remove_column :users, :username
```
Rename a TABLE: same shape — create new table (or updatable VIEW pointing at
old), sync writes, backfill, switch reads, drop.

## Change a column type (dual-column)

```
1. add_column :orders, :total_cents_v2, :bigint
2. Dual-write (model callback or DB trigger for out-of-band writers):
   before_save { self.total_cents_v2 = total_cents }
3. Backfill batched: Order.in_batches.update_all("total_cents_v2 = total_cents")
4. Verify: Order.where("total_cents_v2 IS DISTINCT FROM total_cents").none?  # PG
5. Switch reads (alias_attribute or rename via the rename recipe)
6. ignored_columns → remove old column (two deploys)
```

## Backfill template (safe shape)

```ruby
class BackfillUsersStatus < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!     # PG/MySQL: each batch commits independently

  class User < ActiveRecord::Base; end   # inline stub — NEVER the app model

  def up
    User.unscoped.in_batches(of: 10_000) do |batch|
      batch.where(status: nil).update_all(status: "active")  # idempotent
      sleep(0.01)                                            # throttle hot tables
    end
  end

  def down = nil   # backfills don't roll back
end
```
For long/huge backfills prefer a rake task or maintenance job over a migration
(deploys shouldn't wait on hours of data movement). Idempotency is mandatory —
it WILL be interrupted and rerun.

## NOT NULL on existing column (cross-adapter summary)
- PG: check constraint NOT VALID → validate → change_column_null (see postgresql.md)
- MySQL: backfill to zero NULLs → MODIFY in low-traffic window or gh-ost (mysql.md)
- SQLite: backfill → accept the table rebuild in a window (sqlite.md)

## Deploy-order rules
- **Additive schema BEFORE the code that uses it** (deploy migration first).
- **Destructive schema AFTER the code that stops using it** (+ ignored_columns).
- Rolling deploys double the exposure window — every recipe assumes both
  versions run simultaneously.

## Verification commands
```bash
bin/rails db:migrate && bin/rails db:rollback && bin/rails db:migrate  # reversibility
git diff db/schema.rb        # only YOUR change, no drift noise
bin/rails db:migrate:status  # no orphaned migrations
```
