# RegexDojo — Improvement Log

Every change made in the repair-and-improvement pass, with rationale and trade-offs.
Ordered by phase. Each entry: **What changed / Why / Pros / Cons**.

## P0 — Make it work

### 0.1 Ruby version pin (`.ruby-version`)

- **What**: Added `.ruby-version` with `4.0.5`.
- **Why**: The repo pinned no Ruby version anywhere (no `.ruby-version`, no Gemfile
  directive). mise resolved a default Ruby (4.0.6) whose gem set does not contain the
  bundle, so the documented `bundle exec rspec` and `bin/setup` failed out of the box.
  The bundle is installed under 4.0.5.
- **Pros**: `bundle exec rspec` works with no PATH gymnastics; every tool (mise, rbenv,
  chruby) and CI reads this file; reproducible onboarding.
- **Cons**: One more file to bump on Ruby upgrades (a feature, really — upgrades become
  explicit).

### 0.2 Database cleaning covers all DB-touching specs (`spec/support/db.rb`)

- **What**: The `:db` tag (which wraps examples in a rollback transaction) was derived
  only for `type: :feature` specs — and the suite has none. Now it is also derived from
  file path for `spec/requests/`, `spec/actions/`, `spec/repos/` and `spec/features/`.
- **Why**: `Home::Index` creates a guest user on every call. The request and action specs
  exercising it ran with **no transaction and no cleanup** — verified: 2 orphan user rows
  left in the test DB after a run. Under RSpec's random ordering that is a latent
  order-dependency bomb.
- **Pros**: Test isolation restored; new specs get cleaning for free by living in the
  right directory; one-line-per-glob change.
- **Cons**: Specs that genuinely don't touch the DB pay a (tiny, SQLite) transaction
  begin/rollback cost.

### 0.3 Stray double assignment in validator spec

- **What**: `result = described_index = described_class.validate(...)` →
  `result = described_class.validate(...)` in `spec/lib/regex_dojo/validator_spec.rb`.
- **Why**: `described_index` was a dead leftover (likely an autocomplete accident); it
  shadowed nothing but confused readers and linters.
- **Pros**: Clean. **Cons**: None.

### 1. Phlex 2 entry point: `template` → `view_template`

- **What**: Renamed `def template` to `def view_template` in `app/views/layout.rb` and
  `app/views/components/hud.rb`. New specs: `spec/views/layout_spec.rb`,
  `spec/views/components/hud_spec.rb`.
- **Why**: Phlex 2.x renders through `view_template`; `template` is a Phlex 1 name that
  Phlex 2 silently ignores. Result before the fix: the layout emitted **nothing** of its
  own (no doctype, no `<head>`, no CSS/JS links) and the HUD rendered a literal
  "Phlex Warning: … doesn't define a `view_template` method" string.
- **Pros**: The page actually gets its stylesheet, JS bundle and HUD; specs now lock the
  contract so a future Phlex upgrade can't silently regress it.
- **Cons**: None — pure bug fix.

### 2. Layout composition: nested `.call` → `render`

- **What**: In `app/actions/home/index.rb`, `layout.call { dashboard.call }` became
  `layout.call { |l| l.render(dashboard) }`. Guarded by `spec/requests/root_spec.rb`,
  which now asserts real markup and rejects `&lt;div` (the escaped-HTML symptom).
- **Why**: In Phlex 2, `component.call` renders into a **fresh buffer and returns a
  String**. Returning that string from another component's block makes Phlex treat it as
  plain text and HTML-escape it — the entire dashboard was served as literal
  `&lt;div&gt;…` source code. `render` writes into the shared output buffer instead.
- **Pros**: The app is visible again; this is the idiomatic Phlex 2 composition pattern.
- **Cons**: None — pure bug fix.

### 3. CSRF token meta tag

- **What**: `Views::Layout` accepts a `csrf_token:` kwarg and emits
  `<meta name="csrf-token">`; `Home::Index` passes `request.session[:_csrf_token]`
  (`||=` a fresh `SecureRandom.hex(32)`, matching hanami-action's own generator).
- **Why**: Hanami auto-enables CSRF protection when sessions are on, and
  `@rails/request.js` sends the `X-CSRF-Token` header **only if this meta tag exists**.
  Without it, every real `POST /kata/:id/check` raised `InvalidCSRFTokenError` — the app's
  core interaction was broken outside the test env (hanami-action skips CSRF checks in
  test, which is why the suite never caught it).
- **Pros**: Submissions work in dev/prod; no JS changes needed; specs assert the tag.
- **Cons**: Specs can only assert tag *presence*, not enforcement (test env limitation) —
  noted in the spec itself.

### 4. Grading routed through `RegexDojo::Validator` + capture-group rule

- **What**: `Kata::Check` no longer open-codes regex evaluation; it delegates to
  `Validator.validate` — previously used only by a rake task despite being the only
  well-tested code in the repo. New rule: **if the pattern has a capture group
  (numbered or named), the graded value is what the group captured; otherwise the full
  match**. Mirrored in `dojo_controller.js` and `blitz_controller.js`.
- **Why**: Two katas ("extract 555 from (555)-0199", "extract the protocol") were
  mathematically unsolvable with full-match-only grading while their hints told you to
  use the patterns that failed. Capture-group semantics are the standard meaning of
  "extraction" and teach groups properly. Duplication meant the action and the tested
  Validator could silently diverge.
- **Pros**: One source of truth; extraction katas teach what they claim; groups become a
  learnable concept.
- **Cons**: A learner could "cheat" a full-match kata by wrapping an over-narrow group —
  acceptable in a solo learning tool; the rule is documented in code.

### 5. Truthful XP/belt + consistent guest creation in `Kata::Check`

- **What**: The find-or-create guest logic moved into `Action#current_user` (base
  class), used by both actions and hoisted **before** grading; the response now always
  carries the user's real `total_xp`/`belt`. Client reads `xp_awarded` (the real key)
  instead of the nonexistent `data.xp`, and updates the HUD from the server's
  authoritative `total_xp`. Statuses: 404 unknown kata, 422 empty/invalid pattern
  (was HTTP 200 for invalid regex).
- **Why**: `user` was only assigned inside `if all_passing`, so every failing submission
  reported `total_xp: 0, belt: "white"` regardless of reality. `GET /` created guest
  users but the POST endpoint didn't, silently discarding XP for fresh sessions.
  `data.xp` was always `undefined`, so re-solves showed full XP that was never granted.
- **Pros**: The HUD never lies; a first-time visitor can solve a kata immediately; error
  responses are machine-distinguishable by status code.
- **Cons**: `current_user` assumes the including action injects `dojo_repo` — a soft
  contract documented in the method comment.

### 6. Client and server agree on what "passing" means

- **What**: `DojoRepo#get_challenges_for_view` now ships `expected_match` with each test
  case; both Stimulus controllers grade with the exact server rule instead of a boolean
  `re.test()`. Test-case cards now show *what* should be extracted
  (`→ should extract "555"`).
- **Why**: The client only knew `should_match: true/false`, so an over-broad pattern
  (`.` matches everything) passed the client's pre-check and then failed server-side —
  a confusing contradiction for a learning tool.
- **Pros**: What you see while typing is exactly what the server will grade; showing the
  expected extraction teaches precision.
- **Cons**: The expected answers are visible in the page source/devtools. For a personal
  learning app this is fine (you'd only cheat yourself); a competitive app would need
  server-side-only grading.

## P1 — Correctness + security

### 7. ReDoS safety rails in `Validator`

- **What**: Patterns compile with `Regexp.new(pattern, timeout: 0.2)`; patterns over 200
  chars are rejected; `Regexp::TimeoutError` returns a friendly "took too long" error.
  The spec uses `^(a|aa)+\1$`, empirically verified to be exponential on this Ruby
  (backreferences bypass Ruby 3.2+'s regex memoization).
- **Why**: User-supplied regexes run on an unauthenticated POST. One hostile pattern
  could pin a Puma thread indefinitely (no `Regexp.timeout` existed anywhere).
- **Pros**: A DoS vector closed with two constants; learners get a helpful message
  instead of a hung request.
- **Cons**: An extremely convoluted-but-legitimate pattern could hit the 0.2 s ceiling on
  slow hardware; the limit is a named constant (`MATCH_TIMEOUT`) and easy to tune.

### 8. XSS hardening of the blitz JSON island

- **What**: `BlitzPanel` escapes `<` as `<` in the JSON it embeds inside
  `<script type="application/json">`. Spec proves `</script><script>alert(1)</script>`
  in a challenge title cannot break out.
- **Why**: `to_json` does not escape `</script>`, so hostile challenge data could close
  the script tag early and execute. Data is currently repo-seeded (low risk), but any
  future admin/import feature would have turned this into stored XSS.
- **Pros**: Standard, zero-cost JSON-in-HTML escaping; `JSON.parse` reads `<` back
  as `<` transparently.
- **Cons**: None.

### 9. Session secret guard + progress unique index (+ reconstructed migration)

- **What**: (a) `SESSION_SECRET` must be set in production — boot fails loudly instead
  of silently signing sessions with `"aaa…"`; dev/test keep a deterministic fallback.
  (b) New migration adds a **unique index on `progress(user_id, kata_id)`**, and
  `record_solved_kata` now runs in a transaction, rescuing the constraint violation.
  (c) The phantom migration `20260623090000_add_details_to_challenges` (recorded in
  `schema_migrations` but missing from the repo) was reconstructed from the live schema
  with its original timestamp — it was blocking **all** `hanami db migrate` runs.
- **Why**: A guessable session secret lets anyone forge sessions. Without the index, two
  concurrent solves both passed the `exist?` check and double-awarded XP; the XP
  read-modify-write could also be torn by a crash mid-way.
- **Pros**: Race-proof XP at the DB level (the only level that can actually guarantee
  it); schema is reproducible from a clean checkout; migrations unblocked.
- **Cons**: The reconstructed migration is a best-effort mirror of the live schema —
  correct for these three nullable columns, verified against `.schema challenges`.

### 10. Single XP table

- **What**: `DojoRepo::XP_BY_DIFFICULTY` + `#xp_for(difficulty)`; both the action and
  the view mapper use it (previously two byte-identical `case` expressions).
- **Pros**: Changing XP values is now a one-line edit. **Cons**: None.

## P2 — Test coverage

### 11–13. Repo suite, component smoke specs, end-to-end request spec

- **What**: `spec/repos/dojo_repo_spec.rb` (user lifecycle, XP idempotency, belt
  promotion, unique-index enforcement, view-hash shapes), `spec/views/**` smoke specs
  (every panel renders and mounts its Stimulus controller), and
  `spec/requests/kata_check_spec.rb` (real POST through the router with a session
  cookie). Also removed a hidden 2× query: `Home::Index` derived the blitz list from
  the already-loaded challenges instead of re-running the full query.
- **Why**: The suite grew 7 → 50 examples. The request spec alone would have caught the
  rendering, grading, and XP bugs — it exercises the same path the browser uses.
- **Pros**: Refactors are now safe; every bug fixed in P0/P1 has a guard.
- **Cons**: Smoke specs assert structure, not pixels — visual regressions still need a
  human (or future system specs).

## P3 — Data, cleanup, DX

### 14. Challenge data: one source of truth (user decision: adopt the 15 rich katas)

- **What**: Exported the 15 curriculum challenges (with `concept`/`lesson`/`task`
  teaching content) from the dev DB into `config/challenges.json` — **preserving ids
  31–45**. `seeds.rb` now inserts explicit ids and all columns, and raises instead of
  swallowing every exception. `DojoRepo` uses the authored teaching content (falls back
  to derived text only when a column is nil, instead of always overwriting it with
  junk like "Easy Challenge").
- **Why**: Three unsynchronized sources existed (6-kata JSON, 15-kata DB, 10-kata dead
  `KataPool`); the JSON contained the two unsolvable katas; the repo mapper was
  discarding the authored lessons the DB already had.
- **Pros**: Clean checkout reproduces the full curriculum; **no destructive reseed was
  needed** — because ids are preserved, existing `progress` rows stay valid and future
  reseeds are id-stable too; lessons finally display their real teaching text.
- **Cons**: `challenges.json` is now generated-from-DB content — future kata authoring
  should edit the JSON and reseed, treating the JSON as the master copy.

### 15. Dead code removal

- **What**: Deleted `lib/regex_dojo/kata_pool.rb` (229 LOC, zero call sites) and its
  three leftover `require_relative`s; the empty `Hanami::View` stubs
  (`app/views/home/index.rb`, `app/views/kata/check.rb`); the entire unused
  `app/templates/` ERB tree (including the misleading `app.html.erb` layout that
  contradicted the real Phlex layout); the stray empty `public/assets.json`; and stale
  fingerprinted build artifacts.
- **Why**: Every one of these was verified unreferenced. The ERB layout in particular
  had already caused a real diagnosis error (it looked like the app's layout but never
  rendered).
- **Pros**: ~600 fewer lines to mislead future readers (and AI agents).
- **Cons**: If a KataPool-style in-memory pool is ever wanted again, it's in git
  history — but the DB + JSON pipeline supersedes it.

### 16. Linting: standard

- **What**: Added the `standard` gem (development/test group); `standardrb --fix`
  resolved ~220 offenses (almost all hash-literal spacing); the codebase is now
  standardrb-clean and the quality gate is `bundle exec standardrb && bundle exec rspec`.
- **Pros**: Style debates end; agents and humans share one authority.
- **Cons**: The mechanical reformat adds diff noise to this branch (one-time cost).

## Deferred (future work)

- **i18n**: all user-facing text in Phlex components and JS is hardcoded English.
  Per the project owner's preference, new/changed copy should move to an i18n layer
  (the `i18n` gem is already in the Gemfile, unused). Retrofit deferred as its own pass.
- **Blitz score persistence**: `DojoRepo#save_blitz_score` and the `blitz_scores` table
  exist, but no route accepts a score — blitz results vanish on reload.
- **Belt ladder**: only white → yellow at 200 XP exists; yellow is terminal.
- **Streak logic**: `users.streak` is set to 1 at creation and never updated;
  `users.last_active_at` is never touched.
- **Asset fingerprinting**: the layout hardcodes `/assets/app.css`/`app.js`, bypassing
  the hanami-assets manifest (works because Tailwind CLI writes those paths directly).
- **JS test harness**: the four Stimulus controllers have no automated tests; the
  grading logic in JS is verified manually against the server rule.
- **Params schemas**: actions parse params/JSON manually; Hanami's `params do` contract
  blocks would give typed validation.
- **CI**: no `.github/workflows` — the quality gate runs only locally.
- **Hanami 3.0 stable**: everything is pinned to `3.0.0.rc1`; bump when stable lands.
