# Hanami Conventions for Regex Dojo

## Stack
- Hanami 3.0.0.rc1, Ruby 3.4.x, SQLite3
- Phlex views (no ERB or Slim)
- dry-system for dependency injection via the `Deps` mixin
- ROM (Ruby Object Mapper) for database relations and repositories
- Testing: RSpec, FactoryBot, VCR, WebMock
- Linting: StandardRB (`bundle exec standardrb --fix`)

## Development Commands
- `bin/dev` or `bundle exec hanami server` — start dev server
- `mise exec -- bundle exec rspec` — run tests
- `bundle exec standardrb --fix` — lint+fix Ruby
- `bundle exec hanami db migrate` — run migrations
- `bundle exec hanami db prepare` — prepare db

## Conventions
- TDD always. Write failing test first, then production code.
- Actions (Controllers): thin handles, resolve dependencies via `include Deps["repos.dojo_repo"]`.
- Views: Phlex `Views::*` pages, `Views::Components::*` UI components. Pass state in constructors.
- Repositories: Encapsulate database queries and return clean ROM structs.
- ROM Relations: Keep them thin and declarative (`schema(..., infer: true)`).
- Ruby: `frozen_string_literal: true`, double quotes, StandardRB compliance.
