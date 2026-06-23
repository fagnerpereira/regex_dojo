# Rails guides — topic → file map (guides.rubyonrails.org, pin to 7.1)

| Topic / keywords | Guide file |
|---|---|
| Queries, where, includes, preload, eager_load, scopes, strict_loading, N+1, pluck, find_each | `active_record_querying.md` |
| Migrations, schema, add_column, create_table, indexes | `active_record_migrations.md` |
| Validations, validates, errors | `active_record_validations.md` |
| Callbacks, before_save, after_commit | `active_record_callbacks.md` |
| Associations, belongs_to, has_many, polymorphic, delegated_type | `association_basics.md` |
| Routing, resources, namespace, constraints, concerns | `routing.md` |
| Controllers, strong params, params.expect, before_action, rescue_from | `action_controller_overview.md` |
| Caching, fragment, russian doll, Solid Cache, low-level cache | `caching_with_rails.md` |
| Background jobs, Active Job, Solid Queue, retries, queues | `active_job_basics.md` |
| Mailers, deliver_later, previews | `action_mailer_basics.md` |
| Testing, fixtures, system tests, parallel testing | `testing.md` |
| Action Cable, channels, broadcasting, Solid Cable | `action_cable_overview.md` |
| Active Storage, attachments, variants, direct upload | `active_storage_overview.md` |
| Security, CSRF, XSS, SQL injection, CSP | `security.md` |
| Engines, mountable, isolate_namespace | `engines.md` |
| Generators, templates, custom generators | `generators.md` |
| Hotwire, Turbo, importmap, JS | `working_with_javascript_in_rails.md` |
| Internationalization, locales | `i18n.md` |
| Action Text, rich text, Trix | `action_text_overview.md` |
| Multiple databases, sharding, replicas | `active_record_multiple_databases.md` |
| Encryption, encrypts | `active_record_encryption.md` |
| Configuration, config.x, initializers | `configuring.md` |
| Upgrading between versions | `upgrading_ruby_on_rails.md` |
| Error reporting, Rails.error | `error_reporting.md` |

## Source lookup (method signatures)

| Component | Path in tmp/rails_docs |
|---|---|
| Active Record | `activerecord/lib/` + `activerecord/CHANGELOG.md` |
| Action Pack (controllers/routing) | `actionpack/lib/` + `actionpack/CHANGELOG.md` |
| Active Support | `activesupport/lib/` + `activesupport/CHANGELOG.md` |
| Railties (generators, CLI) | `railties/lib/` + `railties/CHANGELOG.md` |
| Action View (helpers, rendering) | `actionview/lib/` |
| Active Job | `activejob/lib/` |
| Action Mailer | `actionmailer/lib/` |
