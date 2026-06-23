---
description: QA, performance verification, and benchmarking standards
globs: spec/**/*_spec.rb, test/**/*_test.rb
---
# Test Suite Conventions & Complexity Audits

Enforce thorough, lightweight testing using RSpec or Minitest.

## 1. Big-O Complexity Verification
- For computational utilities or processing loops, include benchmark assertions to verify execution bounds remain linear ($O(n)$) or constant ($O(1)$) [6, 1]:
  ```ruby
  it "runs within linear performance bounds" do
    expect { |n, _i| process_data(n) }.to perform_linear.in_range(100, 10_000) [6, 1]
  end
  ```

## 2. Database Query Limits
- Ensure associations are preloaded. Write query tracking tests to count SQL executions and raise errors on N+1 failures :
  ```ruby
  it "only executes two database queries" do
    queries = track_queries { get "/" }
    expect(queries.count).to eq(2)
  end
  ```

## 3. Dry Test Runs
- Clean up database test tables in between test examples using active transactions and clean rollbacks to prevent database footprint growth.
