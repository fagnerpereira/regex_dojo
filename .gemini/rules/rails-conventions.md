# Rails Conventions for Kanjika

## Stack
- Rails 8.x, Ruby 3.4.2, SQLite3 (multi-database: primary, queue, cache, cable)
- Phlex views (no new ERB or Slim), Stimulus + Turbo, Tailwind 4, Bun, Propshaft
- Solid Cache, Solid Queue, Solid Cable (all SQLite-backed)
- Auth: bcrypt + session-based (SessionsController, Current model via CurrentAttributes)
- AI/LLM: RubyLLM gem with Gemini for sentence analysis and conjugations
- Japanese NLP: JapaneseProcessor, JpConjugator, SentenceWordProcessor, KanjiApi, Forvo
- Testing: RSpec, FactoryBot, VCR, WebMock, Shoulda-Matchers
- Linting: StandardRB, Prettier, Herb formatter

## Development Commands
- `bin/dev` — start dev server
- `bundle exec rspec` — run tests
- `bundle exec standardrb --fix` — lint+fix Ruby
- `bundle exec brakeman` — security audit
- `bun run format` — format all

## Conventions
- TDD always. Write failing test first, then production code.
- Controllers: thin actions, `params.expect(...)`, scope through `Current.user`.
- Views: Phlex `Views::*` pages, `Components::*` UI components.
- Models: POROs for flows, JSON column defaults.
- Stimulus: one controller per file, kebab-case, static targets/values.
- Tailwind 4 only. No DaisyUI, no inline CSS, no config.js.
- Ruby: `frozen_string_literal: true`, double quotes, StandardRB compliance.
- Prefer request specs and system specs over controller specs.

## Key Domain Models
- Sentence — primary learning unit, analyzed into Words
- Word — vocabulary with readings, meanings, JLPT levels
- Kanji — character details
- Deck — collections for focused study
- FlashCard — SRS progress tracking
