---
description: Rules for ROM (Ruby Object Mapper) optimization and database efficiency
globs: app/relations/**/*.rb, db/migrate/*.rb, app/repos/**/*.rb
---

# ROM Relations & Query Safety Rules

ROM (Ruby Object Mapper) decouples application data mappings from the database schema. In this project, SQLite is used as the storage engine.

## 1. Decoupled Architecture

- **Relations**: Define the schemas and database associations. Keep them thin and declarative (e.g. `schema(:users, infer: true)`).
- **Repositories**: Encapsulate queries and return clean ROM structs. Keep queries inside repository classes (e.g., `DojoRepo`) and avoid querying relations directly in controllers.
- **Idempotent Commands**: Create and update records via ROM commands (e.g., `relation.command(:create).call(...)`).

## 2. Query Safety & Performance

- **Eager Loading**: Use `.combine` to preload associated tables and prevent N+1 queries. E.g. `challenges.combine(:test_cases)`.
- **Projection**: Only load required columns for simple checks by using `.select` or pluck operations.
- **SQLite Optimization**: Avoid heavy transactions when not needed. Ensure foreign keys and cascaded deletes are defined at the schema/migration layer.
- **No ActiveRecord Methods**: Avoid using ActiveRecord helpers. For existence checks, use `.exist?` instead of `.any?` or `.exists?` on ROM relations.
