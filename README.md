# 🥋 RegexDojo

A gamified web app for learning regular expressions by doing — solve katas, earn
XP, level up your belt, and race the clock in Blitz mode. Built to learn regex
without external references: each kata teaches one concept, shows a lesson, and
grades your pattern live as you type.

Built with **Hanami 3.0**, **Phlex** (component views), **SQLite** (ROM/Sequel),
**Stimulus + Turbo**, and **Tailwind CSS 4**.

## Features

- **Dojo** — the main mode: 15 katas across Easy/Medium/Hard, each with a lesson,
  a task, live match highlighting, and per-test-case feedback. Capture groups are
  graded like real extraction: if your pattern captures, the capture is the answer.
- **Sandbox** — a free-play regex tester with flags.
- **Blitz** — 30-second speed round over the easier katas.
- **Codex** — a regex reference organized by concept.
- **Progress** — anonymous cookie session; XP and belt tracked per guest user.

## Getting started

```bash
bin/setup                    # gems, npm packages, database
bundle exec hanami db seed   # load the kata curriculum
bin/dev                      # server + asset watchers → http://localhost:2300
```

## Development

```bash
bundle exec rspec        # test suite
bundle exec standardrb   # linter
bundle exec rake         # default task (specs)
```

Kata content lives in `config/challenges.json` (the master copy) and is loaded
into SQLite by `config/db/seeds.rb`. Seeds insert explicit ids, so re-seeding
keeps existing user progress valid.

Regex grading logic lives in `lib/regex_dojo/validator.rb` — one source of truth
used by the HTTP action, mirrored by the Stimulus controllers, and guarded
against catastrophic backtracking with `Regexp` timeouts.

See [docs/IMPROVEMENTS.md](docs/IMPROVEMENTS.md) for the full change log of the
repair-and-improvement pass, with pros/cons for every decision.
