# ROM Relations & Query Safety Rules

- Keep relations thin and declarative, utilizing schema inference: `schema(..., infer: true)`.
- Encapsulate queries inside Repository classes (e.g. `DojoRepo`) and avoid querying relations directly in controllers.
- Use `.combine` to preload associated tables and prevent N+1 queries. E.g. `challenges.combine(:test_cases)`.
- Use `.exist?` for existence checks instead of ActiveRecord-style `.any?` or `.exists?` on ROM relations.
- Keep commands idempotent.
- SQLite is the storage engine; define cascaded deletes and foreign keys at the schema/migration layer.
