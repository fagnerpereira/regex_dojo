---
name: rom
description: ROM (Ruby Object Mapper) conventions, schema definitions, query encapsulation in Repositories, eager loading, SQLite optimizations, and command actions. Use when editing or creating database relations, schemas, migrations, or repositories.
---

# ROM (Ruby Object Mapper) Persistence Skill

This skill defines rules and conventions for working with ROM and SQLite database layers inside this project.

## 1. Decoupled Persistence Architecture
ROM splits database mapping into distinct layers:
- **Relations**: Define the low-level database schemas and associations. Keep relations thin and declarative.
  ```ruby
  # app/relations/users.rb
  class Users < ROM::Relation[:sql]
    schema(:users, infer: true) do
      associations do
        has_many :submissions
      end
    end
  end
  ```
- **Repositories**: Encapsulate high-level application queries and mutations. Controllers and operations MUST talk to repositories and never call relations directly.
  ```ruby
  # app/repos/user_repo.rb
  module Repos
    class UserRepo < ROM::Repository[:users]
      commands :create, update: :by_pk, delete: :by_pk

      def find_by_id(id)
        users.by_pk(id).one
      end

      def find_with_submissions(id)
        users.combine(:submissions).by_pk(id).one
      end
    end
  end
  ```
- **Idempotent Commands**: Create/update/delete records using repository commands or custom command classes.

## 2. Query Safety & Performance

### Avoid N+1 Queries
- Eager-load associations with `.combine` inside repositories:
  ```ruby
  challenges.combine(:test_cases)
  ```
- Avoid calling association methods inside iterations if they perform lazy-loaded database queries.

### Columns and Projections
- Project column lists by using `.select` or pluck operations to load only what is needed:
  ```ruby
  users.select(:id, :name).to_a
  ```

### SQLite Specific Rules
- SQLite is the storage engine for this project.
- Always implement cascading deletes or foreign key constraints at the SQLite layer in migrations rather than in memory.
- Avoid large open transactions.
- Use `.exist?` for existence checks rather than ActiveRecord-style `.any?` or `.exists?` on ROM relations.
