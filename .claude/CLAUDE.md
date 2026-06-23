# CLAUDE.md — RegexDojo

Project-specific guidance for this Hanami 3.0 learning app. See `~/.claude/CLAUDE.md` for global Ruby/Rails/Hanami principles.

## What This Project Is

**RegexDojo**: Interactive web app where users solve regex puzzles (katas) to learn regular expressions. Guest-based, progress-tracked, difficulty-tiered.

Built with **Hanami 3.0**, **Phlex** (component views), **SQLite**, and **RSpec**.

## Architecture at a Glance

- **Actions** (in `app/actions/`): HTTP handlers inheriting `RegexDojo::Action`; use Hanami DI to access `dojo_repo`
- **Views** (in `app/views/`): Phlex components; rendered as `Layout.call { |l| Component.call }`
- **Repo** (in `app/repos/dojo_repo.rb`): Data layer; queries via Hanami ROM/Sequel relations
- **Relations** (in `app/relations/`): Database schema definitions (users, progress, challenges, submissions, blitz_scores, test_cases)
- **Lib** (in `lib/regex_dojo/`): Business logic (kata validation, scoring, pool management)

**Key Pattern**: Action → loads data via dojo_repo → renders Phlex → sends HTML

## Core Files & Their Roles

| File | Purpose |
|------|---------|
| `config/routes.rb` | Routes: `GET /` (home), `POST /kata/:id/check` (validate regex) |
| `config/challenges.json` | Kata definitions (id, difficulty, title, description, hint, test_cases) |
| `config/app.rb` | App config (sessions, cookies, middleware) |
| `app/action.rb` | Base action with `Dry::Monads[:result]` included |
| `lib/regex_dojo/kata_pool.rb` | Loads and manages challenges in memory |

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

- **Spec layout**: `spec/actions/`, `spec/lib/`, `spec/support/`
- **spec/spec_helper.rb**: Sets `HANAMI_ENV=test`, loads app, auto-loads `spec/support/**/*.rb`
- **Capybara integration**: Available for request specs; actions can be tested as HTTP handlers
- **Test data**: Fixtures in `spec/support/` (helpers, factories if added later)

## Sessions & Guest Users

- Guest users created on first visit: `session[:session_id] = SecureRandom.uuid`
- User record created in `users` relation via `dojo_repo.create_user`
- Progress tracked per user in `progress` relation (`kata_id`, `solved`, `attempts`)

## Challenges & Katas

- Loaded from `config/challenges.json` → cached in `KataPool` (in-memory)
- Each challenge: id, difficulty, title, description, hint, test_cases
- Test cases: `{ input: "...", expected_match: "..." }` (single match or null)
- Stored in DB via `challenges` relation; linked to test_cases

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
- **Sessions**: Hanami Action provides `request.session` (cookie-based, expires after 30 days by config)
- **No migrations**: Schema driven by relations; use `hanami db prepare` or `hanami db reset`
- **Routes**: Simple DSL in `config/routes.rb`; supports `get`, `post`, `put`, `delete`, `:id` params, etc.

---

**Reference**: [Hanami Guides](https://hanamai.org/learn#hanami) • [Phlex Docs](https://www.phlex.fun/) • [Dry Gems](https://dry-rb.org/)
