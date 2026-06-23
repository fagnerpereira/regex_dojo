# AGENTS.md — Regex Dojo AI Agent Contract

Behavioral contract for AI agents working on Regex Dojo.

## Work Style
- You are the Navigator; the developer is the Driver.
- TDD always: red → green → refactor. Do not write production logic before a failing test unless the developer explicitly says `WRITE THE PRODUCTION CODE`.
- Make the smallest useful diff. Plan briefly, change one thing, verify once, then stop.
- NO GIT OPERATIONS: the human stages, commits, and pushes. Do not run `git add|commit|push|fetch|merge`.

## Verified Stack
- **Backend**: Hanami 3.0 (with Dry-System dependency injection via `Deps` mixin).
- **Database**: SQLite (using ROM - Ruby Object Mapper). Keep relations thin, queries inside repositories, and commands idempotent.
- **Views**: Phlex (Ruby classes implementing `view_template`) for layout and components. Pages render Phlex templates. Reusable components live under `app/views/components/`.
- **Frontend**: Tailwind CSS 3.
- **Testing**: RSpec, FactoryBot.
- **Linting**: StandardRB (`bundle exec standardrb --fix`).

## Conventions

### Actions (Controllers)
- Inherit from `App::Action` (or slice-specific action classes).
- Use Dry-System for dependency injection using `Deps` mixin (e.g. `include Deps["repos.dojo_repo"]`).
- Keep actions thin; coordinate fetching/mapping of parameters and invoking repositories or business logic operations.

### ROM Relations & Repositories
- Keep relations thin and declarative, utilizing schema inference: `schema(:dojos, infer: true)`.
- Query database logic should remain encapsulated within repository classes. Repos return clean ROM structs.
- Use `.combine` to preload associated tables and prevent N+1 queries. E.g. `challenges.combine(:test_cases)`.

### Phlex Views & Components
- Define components in `app/views/components/` inheriting from `Phlex::HTML` (e.g. `Views::Components::Card`).
- Define `view_template` for HTML DSL. Use Tailwind utility classes for flexbox/grid layout and styling.
- Controllers/Views pass data to components through constructors. Avoid global state.

## Useful Commands
- `mise exec -- bundle exec rspec` — Run the test suite.
- `bundle exec standardrb --fix` — Lint and auto-correct Ruby code.
- `bundle exec hanami db migrate` — Run database migrations.
- `bundle exec hanami db prepare` — Prepare test/development database.
- `bin/dev` or `bundle exec hanami server` — Start development server.
