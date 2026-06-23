---
name: n-plus-one-audit
description: >
  Audit and resolve N+1 query and memory allocation bottlenecks in ActiveRecord and controllers.
  Use when analyzing SQL queries, checking performance, or debugging slow pages.
---

# Skill: N+1 Query & Memory Audit

Execute this diagnostic cycle when reviewing controller or database actions.

## Assessment Blueprint

1. **Subscribe to ActiveSupport Events**: Listen to `"sql.active_record"` hooks to collect query names:
   ```ruby
   ActiveSupport::Notifications.subscribe("sql.active_record") { |*args| ... }
   ```
2. **Analyze Loop Iterations**: Compare the number of database queries with the number of parent records. If queries scale as $O(n)$, an N+1 bug is active.
3. **Rewrite using Preloads**: Convert raw loops into batched queries using `.includes`, `.preload`, or `.joins`.
4. **Verify Allocation Footprint**: Run the action within an isolated benchmark and ensure standard deviation remains low across multiple runs.
