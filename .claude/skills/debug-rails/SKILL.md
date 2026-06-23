---
name: debug-rails
description: >
  Debug common Rails errors — backtrace analysis, log pattern recognition,
  query tracing, cache debugging, background job failures, and configuration
  issues. Use when a Rails error occurs, a test fails unexpectedly, or
  behavior doesn't match expectations. Complement to the debugger agent.
---

# Rails debugging patterns

## Reading Rails logs

### Request log anatomy
```
Started GET "/orders/1" for 127.0.0.1 at 2026-06-12 10:00:00
Processing by OrdersController#show as HTML
  Parameters: {"id" => "1"}
  User Load (0.5ms)  SELECT "users".* FROM "users" WHERE ...
  Order Load (0.3ms)  SELECT "orders".* FROM "orders" WHERE ...
  Rendering Views::Orders::Show in 15ms
  Rendered in 25ms
Completed 200 OK in 30ms (Views: 15ms | ActiveRecord: 5ms)
```

### Key patterns to watch
- **Slow queries** — `AR: 500ms` out of `600ms total` → database bottleneck
- **N+1** — same query repeated with different IDs (e.g., `Word Load` x50)
- **Rendering spikes** — `Views: 400ms` → partial/view complexity
- **Completed 500** — unhandled exception, check `backtrace`
- **Completed 302** — unexpected redirect, check `before_action` chain

## Common error patterns

### `ActiveRecord::RecordNotFound`
- Check if record exists before `find`/`find_by!`
- Use `find_by` (returns nil) instead of `find_by!` (raises) if not found is valid
- Scope finds through the owning association to enforce access (e.g. `user.orders.find(params[:id])`), not a bare `Order.find`

### `NoMethodError: undefined method 'x' for nil`
- A dependent association returned nil
- Use `&.` safe navigation: `user&.profile&.display_name`
- Eager load or check presence before calling methods
- For collections, ensure `.includes` was called

### `ActionView::MissingTemplate`
- Check controller action name matches view file name
- Phlex views are classes, not template files — verify class name matches convention
- Controller must `render Views::Xxx::Yyy.new(...)`
- Check `app/views/` directory structure mirrors controller namespace

### `ActiveRecord::StatementInvalid` (PostgreSQL) / `PG::Error`
- Constraint violation → check FK / null / check constraints vs model validations
- `PG::UndefinedColumn` → migration not run: `bin/rails db:migrate:status`
- Pool exhaustion (`could not obtain a connection`) → check `pool` in `config/database.yml` vs Puma/Solid Queue concurrency
- Deadlock / lock timeout → review long transactions and ordering of writes

### `Faraday::ConnectionFailed` / `Net::ReadTimeout`
- External API (OpenPix/Woovi, Stripe, OpenAI) is unreachable
- Check network connectivity and the relevant credential/env var
- Jobs should have retry logic: `retry_on Net::ReadTimeout, wait: :exponentially_longer`
- Use VCR cassettes / WebMock stubs in tests

### External payment/AI service failures
- OpenPix/Stripe → inspect the service object under `app/services/openpix/` (and Stripe controllers); confirm the API credential is set
- Webhooks → check `webhooks_controller` / `stripe/webhooks_controller`; CSRF is skipped on `:create`, so the handler must validate the payload itself
- OpenAI (`app/services/openai/`) → verify the API key and that the response shape matches what the service parses

## Query debugging

```ruby
# Enable query logging
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Track queries in a block
queries = []
ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  queries << args.last[:sql]
end

# Use Bullet in development/test
Bullet.enable = true
Bullet.alert = true
```

## Cache debugging

```ruby
# Enable cache logging
ActiveSupport::Cache::Store.logger = Logger.new(STDOUT)

# Check cache hit/miss in Rails console
Rails.cache.read("views/orders/index")
Rails.cache.fetch("expensive_query") { Order.all.to_a }

# Inspect Solid Queue jobs (background processing)
ActiveRecord::Base.connection.execute("SELECT count(*) FROM solid_queue_jobs")
```

## Background job debugging (Solid Queue)

```bash
# Check failed jobs
bin/rails runner "SolidQueue::FailedExecution.all.each { |e| puts e.error.message }"

# Retry all failed jobs
bin/rails runner "SolidQueue::FailedExecution.all.each(&:retry)"

# Clear failed jobs
bin/rails runner "SolidQueue::FailedExecution.delete_all"

# Check job queue depth
bin/rails runner "puts SolidQueue::ReadyExecution.count"
```

## Configuration debugging

```bash
# Check Rails version
bin/rails about

# Check gem versions
bundle list | grep <gem-name>

# Check routes
bin/rails routes

# Check schema
bin/rails db:migrate:status

# Check environment
bin/rails runner "puts Rails.env; puts Rails.application.config.active_job.queue_adapter"
```
