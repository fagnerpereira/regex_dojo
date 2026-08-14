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

## Answer persistence

### 17. Your latest answer is restored per kata (and every attempt is recorded)

- **What**: The pattern box now pre-fills with your most recent answer for that kata —
  right or wrong — across navigation, reload, and browsers. Two layers:
  - **Browser**: every keystroke saves a per-kata draft under
    `regex_dojo_draft_pattern:<kataId>`. A new `patternChanged()` action wraps
    `evaluatePattern()` and writes *before* any early return, so deliberately clearing
    the box persists an empty draft instead of being ignored.
  - **Server**: a migration adds nullable `submissions.user_id` (plus a
    `(user_id, challenge_id, id)` index); `DojoRepo#latest_patterns_for_user` returns the
    newest attempt per kata in **one** query; it reaches the browser as
    `data-kata-last-pattern` on each sidebar button, following the existing
    `data-kata-solved` precedent.
  - On load, an unsent local draft wins over the server value (`!== null`, not
    truthiness, so a cleared `""` beats a stale server answer); otherwise the server
    value fills in. `evaluatePattern()` then re-runs so highlights and ⬜/✅ icons match
    the restored pattern rather than showing neutral state.
- **Why**: `dojo_controller.js` hard-cleared the input on *every* kata load, so solving a
  kata and auto-advancing lost your answer permanently — the single most annoying thing
  about using the app to actually learn. Ordering by `id` rather than `submitted_at`
  matters: the timestamp has second granularity, so same-second attempts tie, while the
  autoincrement id is a true total order.
- **Pros**: Nothing you type is ever lost; a solved kata shows the pattern that won;
  attempt history is now real data (`user_id` + index) ready for a history UI; storage
  access is wrapped in try/catch, so private browsing no longer throws inside `connect()`
  and kills kata loading — a pre-existing latent crash.
- **Cons**: `submissions` grows unbounded with no retention policy; the expected answers
  were already client-visible, and now your own past answers are too (fine for a personal
  learning tool); the whole Stimulus half is manually verified because this repo has no
  JS test runner.

### 18. Every submit is recorded, not just winning ones

- **What**: `submit()` no longer short-circuits wrong answers client-side — it POSTs every
  attempt and lets the server decide. `current_user` is resolved *before* the submission
  is logged so each attempt is attributed. Since a wrong-but-valid pattern returns **HTTP
  200 with `passing: false`**, the success path is now gated on `data.passing`; a new
  `_onFailure()` carries the shake + "keep tweaking" message. The now-unused
  `_allTestCasesPass` helper was deleted.
- **Why**: The client only ever POSTed patterns that already passed locally, so failing
  attempts never reached the database — despite the comment in `check.rb` claiming every
  attempt was logged for history. Without this, a "history of everything I tried" would
  only ever contain correct answers.
- **Pros**: The history is honest; the server is the single grading authority, removing
  any chance of client/server divergence deciding whether you get XP.
- **Cons**: One network round-trip per submit where wrong answers used to be free —
  negligible for a local single-user app, and it buys correct data. Without the
  `data.passing` gate this change would have fired the success banner and auto-advance on
  every wrong answer; that gate is load-bearing.

## Ruby track feedback

### 19. Output-equivalent answers pass, and every answer teaches the idiomatic forms

- **What**: The Ruby grader now judges in two rounds. Round 1 is the existing
  parse-only structural match against the accepted forms — the idiomatic pass. When
  that misses, round 2 **runs the answer in a throwaway subprocess**
  (`Graders::RubyExecutor`: separate OS process, `--disable-gems`, 2 s SIGKILL
  timeout, hard-disabled in production) and passes it if the returned value equals
  the expected output — flagged `idiomatic: false`. Failures now say *what your code
  actually returned* ("Your code ran and returned [1, 3, 5] — expected [2, 4, 6]")
  instead of the misleading "compare your result" line, and runtime errors surface
  readably. Every graded answer — pass or fail — now carries `suggestions`: each
  kata's authored `approaches` (code + why), rendered under the form. Accepted lists
  were broadened too (`x % 2 == 0` and friends are legitimate general solutions).
- **Why**: A learner whose answer produced the exact expected output was told they
  were wrong with a message implying the *output* mismatched — the worst possible
  feedback in a learning tool. Structure-only grading cannot enumerate every correct
  answer; execution can confirm any of them, while the idiomatic flag preserves the
  teaching pressure toward better forms.
- **Pros**: Correct answers are never called wrong; wrong answers get told exactly
  what they produced; every submission ends in a mini-lesson; hardcoded-answer
  "cheats" (e.g. `[2,4,6].include?(n)`) now pass honestly but are immediately shown
  the general forms — which teaches more than rejecting them did.
- **Cons**: This **is** arbitrary code execution, deliberately: acceptable for a
  personal localhost learning tool, mitigated by process isolation + timeout, and
  disabled in the production env where the structural verdict stands alone. If the
  app is ever deployed publicly, revisit before enabling. One subprocess per
  non-structural submit (~50 ms) is the price of honest grading.

### 20. Answering no longer throws you back to the regex tab

- **What**: `ruby_dojo_controller` no longer calls `window.location.reload()` after a
  correct answer — you stay on the same challenge, with the banner, suggestions, a
  live-updated "N/5 solved" counter and HUD XP bar. Separately, `tabs_controller` now
  remembers the active tab in localStorage (try/catch-wrapped) and restores it on
  connect, so even a manual reload lands back on the Ruby tab.
- **Why**: The reload existed to advance to the next server-picked challenge, but its
  real effect was `tabs_controller.connect()` re-activating the *first* tab — the
  regex dojo — mid-Ruby-practice. The user explicitly wants to stay on the answered
  challenge and move on themselves.
- **Pros**: No lost context; the reviewed answer and its suggestions stay on screen.
- **Cons**: The next challenge no longer auto-loads — moving on currently means
  reloading the page (now safely returning to the Ruby tab). A "Next kata" button
  that swaps the challenge in place is the natural follow-up.

### 21. Content-Security-Policy allows the Google Fonts files

- **What**: `config.actions.content_security_policy[:font_src] += " https://fonts.gstatic.com"`
  in `config/app.rb`, with a request spec pinning the header.
- **Why**: Hanami's default CSP sets `font-src 'self'`; the layout loads Inter and
  JetBrains Mono from Google Fonts, whose stylesheet passed (`style-src` allows
  `https:`) but whose font files from fonts.gstatic.com were blocked — the console
  CSP violations, and silently fallback fonts.
- **Pros**: Clean console; the intended typography actually renders.
- **Cons**: Third-party font dependency remains — self-hosting the two families
  would be more offline-friendly and CSP-strict (future work).

## Sandbox & navigation polish

### 22. The pattern box reads as a real regex literal, and the slash overlap is fixed

- **What**: (a) The Sandbox's trailing `/` is now a live flags display — toggling
  g/i/m/s updates it to `/g`, `/gi`, … `/gims`, exactly like writing a real regex
  literal; the `s` button finally lights up (it was missing from the controller's
  targets, so it silently affected matching with no visual state). (b) The
  decorative leading `/` no longer overlaps the typed text — in all three panels
  (sandbox, dojo, blitz).
- **Why**: The overlap was a Tailwind v4 cascade bug, not a padding typo:
  `.regex-input` was **unlayered** CSS whose `padding` shorthand outranked the
  `pl-8`/`pr-12` utilities (unlayered rules beat every `@layer`). Wrapping it in
  `@layer components` restores utility priority everywhere the class is used.
- **Pros**: The UI teaches literal syntax passively; one root-cause CSS fix heals
  three panels; flags state is finally honest.
- **Cons**: Other component classes (`.kata-card`, `.flag-toggle`, …) remain
  unlayered by choice — layering them all at once risked collateral cascade
  shifts; migrate them opportunistically.

### 23. Next-kata flow hardened (from the adversarial review)

- **What**: An adversarial 3-lens review workflow confirmed 5 real issues in the
  Next-kata diff before it shipped; all fixed: the server now pins the landing
  tab (`data-tabs-server-tab="ruby"` when `ruby_after` is present, honored by
  `tabs_controller` ahead of localStorage) so the link works in storage-blocked
  private browsing; the link uses `data-turbo-action="replace"` so walking the
  track doesn't stack history entries; `ruby_dojo_controller` scrubs the
  one-shot `ruby_after` param via `history.replaceState`, so reloads/bookmarks
  return to first-unsolved instead of a pinned stale cursor; an already-solved
  kata shows a `✓ solved` badge and a completed track announces
  "cycling for review" instead of masquerading as fresh material.
- **Why**: The original link relied entirely on localStorage restore — exactly
  the regex-tab bounce this branch fixed, resurrected in any storage-blocked
  browser; and the durable query param made a one-click intent permanent.
- **Pros**: The flow is correct without storage; Back stays one step away;
  wrapping is honest.
- **Cons**: Three cooperating mechanisms (server pin → storage → first tab) is
  more moving parts than one; the priority order is documented in
  `tabs_controller.connect()`.

## Plain language

### 24. "Kata" is gone from the UI; the Ruby track can also step backwards

- **What**: Every learner-visible "kata" became "challenge" ("White Belt
  Challenges", "Challenge Solved!", "Select a challenge to begin", "Challenges
  Solved", "Next →"). A "← Previous" button joins "Next →" on the Ruby track,
  via the same server-side stepping (`ruby_before` mirrors `ruby_after`,
  wrapping, tab-pinned, history-replaced, one-shot). A spec asserts the ruby
  panel's *visible text* contains no "kata"; a whole-dashboard sweep with real
  seeded data confirmed the same across every panel.
- **Why**: Project owner's call — themed jargon makes learners stop to decode a
  word instead of the concept. The UI should spend attention on regex and Ruby,
  not vocabulary.
- **Pros**: Zero-friction copy; back-navigation makes review natural.
- **Cons**: Internal identifiers (`kata_id` column, `data-kata-*` attributes,
  `.kata-card` CSS, storage keys) deliberately keep their names — renaming them
  is churn with migration risk and no learner value. The seam between visible
  copy and internals is now pinned by the spec.

### 25. Assets force revalidation — the era of "hard refresh to see changes" ends

- **What**: Hanami's implicit assets middleware (mounted ahead of all user
  middleware when `assets.serve` is true) served `/assets` with **no
  cache-control header**, so browsers heuristically cached the unfingerprinted
  `app.css`/`app.js` — which is why every fix in this project "didn't work"
  until a hard refresh, including this round's flags display and slash-overlap
  fixes that were verifiably live on the server. Disabled `config.assets.serve`
  and made the app's own `Rack::Static` (previously dead weight behind Hanami's)
  the single asset server, with `header_rules` forcing `cache-control: no-cache`
  (revalidate → 304 when unchanged). Pinned by a request spec.
- **Why**: Root cause over ritual: telling the user "hard refresh" after every
  change was treating the symptom.
- **Pros**: Plain reload always shows current assets; 304s keep it cheap.
- **Cons**: No immutable caching — the real long-term fix is fingerprinted
  assets via the hanami-assets manifest (already in Deferred).

### 26. Sandbox pattern grows instead of hiding long patterns

- **What**: The sandbox pattern field is now a one-row textarea that auto-grows
  with content (`_autosizePattern` on connect/input/clear); the `/` and flags
  decorations pin to the first and last line so a wrapped pattern still reads
  as a literal.
- **Why**: A long pattern (or pasted text) scrolled invisibly off a single-line
  input — you couldn't see what you were editing.
- **Pros**: The whole pattern is always visible; no horizontal scrolling.
- **Cons**: Enter inserts a newline (a literal newline in the pattern) rather
  than being swallowed — acceptable in a free-play sandbox; the dojo and blitz
  inputs stay single-line since Enter submits there.

### 27. The "Organic" redesign — one route per screen, Portuguese, calm

- **What**: Full UI migration to the Organic design from
  `design_handoff_organic_ui/` (cream/sand + terracotta/sage, Caprasimo/
  Figtree/IBM Plex Mono, blob radii, dark mode via a server-read `theme`
  cookie stamping `html[data-dark]`). The 5-tab dashboard became a
  conventional multi-page app: `GET /` (Início hub), `/desafios/:id` (one
  challenge per page, clickable progress dots), `/sandbox` (`?pattern=`
  prefill is the Codex handoff), `/blitz` (record now in `blitz_scores` via
  `POST /blitz/score`), `/codex`, `/ruby/:id` (wrapping prev/next links).
  Turbo Drive smooths navigation; both tracks submit through one real form
  flow (`Actions::Challenges::Check` → PRG 303 + flash), so XP, banners and
  dots re-render server-side and no client code patches the header. Stimulus
  keeps only in-page interactivity: live grading (mirroring the server's
  capture-group rule via `js/lib/grading.js`), the shared pattern field with
  syntax-highlight overlay, the PT tokenizer chips, the Blitz game loop.
  All copy is Portuguese through the native Hanami i18n provider
  (`config/i18n/pt.yml` + `en.yml` kept in key parity by a spec); challenge
  content translated in `challenges.json`/`ruby_challenges.json` with ids,
  difficulties, test cases and grader fields byte-identical; hints ship as
  3 layers (conceito → esqueleto → resposta) JSON-encoded in the existing
  hint column. Belt labels became learner-facing levels (Novato →
  Especialista), same thresholds; the header derives the level from XP, so
  stale stored belt strings can't leak. Lessons render their inline markup
  server-side (fixing the old literal-`<code>` bug).
- **Why**: The prototype was hash-routed; the project owner chose real
  routes + Hotwire instead — less JavaScript state, native history,
  shareable URLs, and server-rendered truth (the fragile "parse `N/M XP`
  out of the DOM" contracts died with it).
- **Pros**: ~3.5k lines of tabbed-dashboard code deleted; every screen has
  request-spec coverage against a real route; state lives in the database
  (blitz record, last attempt restore via `latest_patterns_for_user`).
- **Cons**: Enviar is gated client-side on all tests passing, so failing
  patterns reach `submissions` only via Enter (which always submits — a
  deliberate trade to keep attempt history). Grader error strings are still
  English (backend-owned). No JS test harness yet for the shared libs.

## Deferred (future work)

- **Locale switcher**: pt/en locale files ship in key parity and the header
  carries a static "PT ▾" chip; wiring the switcher (cookie + per-request
  locale) and translating challenge content/`js/lib/tokenizer.js` labels to
  EN is its own pass.
- **Streak logic**: `users.streak` is set to 1 at creation and never updated;
  `users.last_active_at` is never touched. The design calls for a streak
  with 1 weekly protection ("streak com perdão").
- **Grader error copy**: `Graders::Regex`/`Ruby` error/feedback strings are
  English and surface in the error flash.
- **Asset fingerprinting**: the layout hardcodes `/assets/app.css`/`app.js`,
  bypassing the hanami-assets manifest (works because Tailwind CLI writes
  those paths directly).
- **JS test harness**: the Stimulus controllers and `js/lib/` modules have no
  automated tests; grading parity is verified by request specs plus manual checks.
- **Params schemas**: actions parse params/JSON manually; Hanami's `params do`
  contract blocks would give typed validation.
- **Attempt-history UI**: submissions are captured per user, but nothing
  renders a per-challenge attempt timeline yet.
- **Submissions retention**: the table grows without bound; no pruning or archival.
- **Self-host the web fonts**: removes the last third-party origin from the CSP and
  makes the app fully offline.
- **CI**: no `.github/workflows` — the quality gate runs only locally.
- **Hanami 3.0 stable**: everything is pinned to `3.0.0.rc1`; bump when stable lands.
- **Dead view stubs**: `app/view.rb`, `app/views/context.rb` and
  `app/views/helpers.rb` are hanami-view scaffolding nothing uses (the app
  renders Phlex); removable once confirmed against a stable Hanami.
