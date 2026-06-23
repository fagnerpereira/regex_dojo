---
name: coding-principles
description: >
  Load the Anonymous Pix development principles relevant to the current task
  BEFORE planning or implementing. A router: evaluate every group below and read
  the rule/skill files that apply. Most tasks span several groups (a model change
  often needs Backend + Database + Testing). Use at the start of any non-trivial
  change, refactor, or review. Triggers: "follow our conventions", "load the
  principles", or proactively before editing app code.
---

# Load Anonymous Pix principles (router)

The always-loaded contract (`CLAUDE.md` / `AGENTS.md`) stays lean on purpose.
Depth lives in the per-domain files below — load ONLY the ones your task
touches, so context stays small. Evaluate ALL groups; do not stop at the first.
When your task involves database queries, scopes, or data access, ALWAYS load
the Database rules regardless of which files you edit.

## Backend (Ruby / Rails)
- Architecture, SOLID, fat-model/skinny-controller, no global state → Read `.agents/rules/architecture.md`
- Rails commands, linting (standardrb), env workflows → Read `.agents/rules/rails-conventions.md`
- Memory / GC discipline (in-place mutation, batching, streaming reads) → Read `.agents/rules/memory-gc.md`
- Solid Queue (background jobs) usage → Read `.agents/rules/solid-framework.md`

## Database
- ActiveRecord efficiency, batching, aggregations, **callback discipline**, scopes/indexes → Read `.agents/rules/active-record.md`
- Schema design, column types, indexing, EXPLAIN (PostgreSQL) → Skill `database`
- Schema CHANGES (any migration) → Skill `migration`
- Query / N+1 / allocation audit → Skill `n-plus-one-audit`

## Frontend
- Phlex views, Stimulus, Turbo/Hotwire, Tailwind 3 → Skill `frontend`

## Testing
- RSpec patterns, factories, branch/edge coverage, spec hygiene → Read `.agents/rules/testing-guidelines.md` (and `.agents/rules/rspec-testing.md`)

## API
- JSON API design, versioning, serialization, error envelopes → Skill `api`

## Quality & process
- Reviewing a diff/PR (layers, verdict, verify-before-flagging) → Read `.agents/rules/code-review.md`
- Replying to PR review comments (never resolve threads) → Skill `pr-review-reply`
- Refactoring by code smell → Skill `refactor`
- GoF patterns / when to AVOID them → Skill `design-pattern`
- Security review (Brakeman, injection, mass-assignment) → Skill `security`
- Verifying an API/method signature against version-matched docs → Skill `docs`
- Building/running the Docker image, dev process model, env/secrets (no Kamal) → Skill `deployment`
- Debugging a Rails error / failing test → Skill `debug-rails`
- Upgrading Rails or a major gem → Skill `rails-upgrade`
- Scaffolding a new gem → Skill `new-gem`

## How these files are written (and how to add to them)
Keep every rule a directive, not a description: start with `DO NOT <verb>`,
or an imperative (`Use`, `Prefer`, `Ensure`, `Freeze`...). Omit best practices
any competent Rails dev already knows — keep only Anonymous Pix-specific conventions,
gotchas, and tooling. One line per rule. Put an exception inline on the same
bullet (`… Exception: …`), never as a contradicting adjacent bullet.
