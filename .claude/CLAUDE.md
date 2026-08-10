# CLAUDE.md — RegexDojo

Project-specific guidance for this Hanami 3.0 learning app. See `~/.claude/CLAUDE.md` for global Ruby/Rails/Hanami principles.

## What This Project Is

**RegexDojo**: Interactive web app where users solve regex puzzles (katas) to learn regular expressions. Guest-based, progress-tracked, difficulty-tiered.

Built with **Hanami 3.0**, **Phlex** (component views), **SQLite**, and **RSpec**.

## Architecture at a Glance

- **Actions** (in `app/actions/`): HTTP handlers inheriting `RegexDojo::Action`; use Hanami DI to access `dojo_repo`
- **Views** (in `app/views/`): Phlex 2 components; entry method is `view_template` (never `template`); compose with `layout.call { |l| l.render(component) }` (never nest `.call` — it HTML-escapes)
- **Repo** (in `app/repos/dojo_repo.rb`): Data layer; queries via Hanami ROM/Sequel relations
- **Relations** (in `app/relations/`): `schema(infer: true)` from the SQLite schema (users, progress, challenges, submissions, blitz_scores, test_cases)
- **Lib** (in `lib/regex_dojo/`): `validator.rb` is the single source of truth for regex grading (capture-group rule, ReDoS timeout); the Stimulus controllers mirror its rule

**Key Pattern**: Action → loads data via dojo_repo → renders Phlex → sends HTML

## Core Files & Their Roles

| File | Purpose |
|------|---------|
| `config/routes.rb` | Routes: `GET /` (home), `POST /kata/:id/check` (validate regex) |
| `config/challenges.json` | Kata master data (ids 31–45, difficulty, title, concept/lesson/task, hint, test_cases) |
| `config/db/seeds.rb` | Loads challenges.json into SQLite with explicit ids (id-stable reseeds) |
| `config/app.rb` | App config (sessions, cookies, middleware; CSRF auto-enabled by sessions) |
| `app/action.rb` | Base action; `current_user(request)` find-or-creates the guest user |
| `lib/regex_dojo/validator.rb` | Regex grading: capture-group rule, 200-char cap, 0.2s Regexp timeout |

## Development Workflow

```bash
bin/setup         # Install gems, npm, prep database
bin/dev           # Watch assets + run server (http://localhost:2300)
bundle exec rake  # Run all tests
bundle exec hanami console  # Interactive shell
```

**Key commands**:
```bash
bundle exec rspec spec/actions/home/index_spec.rb                 # Single spec
bundle exec rspec spec/actions/home/index_spec.rb:42 -f d         # Line + docs format
bundle exec hanami routes                                          # List routes
bundle exec hanami db reset                                        # Drop & recreate DB
```

## Testing Approach (Aligns with Global TDD)

- **Spec layout**: `spec/actions/`, `spec/requests/`, `spec/repos/`, `spec/views/`, `spec/lib/`, `spec/db/`
- **spec/spec_helper.rb**: Sets `HANAMI_ENV=test`, loads app, auto-loads `spec/support/**/*.rb`
- **DB cleaning**: specs under `spec/(requests|actions|repos|features)/` get the `:db` tag automatically (transaction rollback per example); tag `:db` manually elsewhere
- **Test data**: seeded from `config/db/seeds.rb` in `before :suite` (challenge ids 31–45); no fixtures/factories
- **Linter**: `bundle exec standardrb` (in the bundle); quality gate is standardrb + rspec

## Sessions & Guest Users

- Guest users created on first visit: `session[:session_id] = SecureRandom.uuid`
- User record created in `users` relation via `dojo_repo.create_user`
- Progress tracked per user in `progress` relation (`kata_id`, `solved`, `attempts`)

## Challenges & Katas

- Master copy: `config/challenges.json` → seeded into SQLite by `config/db/seeds.rb` (explicit ids 31–45); the app reads only the DB
- Each challenge: id, difficulty, title, concept, description, lesson, task, hint, test_cases
- Test cases: `{ input: "...", expected_match: "..." }` — `null` expected_match means "must NOT match"
- Grading: full match, unless the pattern has a capture group — then the first participating capture is graded (see `lib/regex_dojo/validator.rb`)

## Regex Validation

- `kata.check` action receives user's regex + kata_id
- Validates regex against all test cases for that kata
- Returns pass/fail; updates user progress in DB

## What's Already in `~/.claude/CLAUDE.md`

Your global setup covers:
- TDD workflow (red → green → refactor)
- Hanami/Rails patterns & conventions
- Agent routing (test-writer, code-writer, debugger, etc.)
- Dry::Monads, Hanami DI, standard gems

**Don't repeat it here.** This file is for regex_dojo specifics only.

## Next Steps for Development

1. **Feature**: Read `app/actions/home/index.rb` and `app/actions/kata/check.rb` to understand request flow
2. **Testing**: Check `spec/actions/` to see existing specs as templates
3. **DB Schema**: Inspect `app/relations/` files to understand user, progress, challenges structure
4. **Business Logic**: Look in `lib/regex_dojo/` for existing utilities (don't reinvent)
5. **View Components**: Phlex components in `app/views/` — compose via `ComponentName.new(data).call`

## Hanami Specifics Recap

- **DB**: Relations in `app/relations/` define schema; Sequel under the hood; queries lazy & chainable
- **DI**: `include Deps["repos.dojo_repo"]` injects dojo_repo into actions
- **Sessions**: Hanami Action provides `request.session` (cookie-based, expires after 30 days by config); sessions ON means CSRF is enforced on POST — the layout must render the `csrf-token` meta tag (test env skips CSRF checks entirely, so specs can't catch its absence)
- **Migrations**: live in `config/db/migrate/` (ROM::SQL); run `hanami db migrate`; relations infer the schema from the DB
- **Routes**: Simple DSL in `config/routes.rb`; supports `get`, `post`, `put`, `delete`, `:id` params, etc.

---

**Reference**: [Hanami Guides](https://hanamai.org/learn#hanami) • [Phlex Docs](https://www.phlex.fun/) • [Dry Gems](https://dry-rb.org/)
