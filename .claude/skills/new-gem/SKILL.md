---
name: new-gem
description: >
  Scaffold a new Ruby gem with `bundle gem` following Bundler's official
  conventions — interactive choices for test framework (RSpec/Minitest),
  linter (RuboCop or Standard), CI (GitHub/GitLab/Circle), license, and
  optional C/Rust extension. Use when the user wants to create, start, or
  scaffold a gem, library, or extract code into a gem.
---

# Create a new Ruby gem (generators-first, vendored conventions)

Bundler's `bundle gem` IS the generator. Never hand-create gem structure.

## Step 0 — Gather decisions (ask only what's not stated)

1. **Gem name** — lowercase, underscores for spaces, dashes ONLY for extensions
   of other gems (`rspec-retry` extends rspec; `my_tool` is standalone).
   Check availability: `gem search ^NAME$ -r` (must return nothing).
2. **Test framework** — `rspec` (Fagner's default), `minitest` (37signals style), `test-unit`
3. **Linter** — `rubocop` (configurable, extensions ecosystem) or `standard`
   (zero-config, no bikeshedding). See `references/linter-choice.md` for trade-offs.
4. **CI** — `github` (default), `gitlab`, `circle`, or none
5. **Extras** — executable (`--exe`)? C/Rust extension (`--ext=rust`)? MIT license? CoC? Changelog?

## Step 1 — Generate

```bash
bundle gem GEM_NAME \
  --test=rspec \
  --linter=standard \
  --ci=github \
  --mit --coc --changelog \
  --git
# add --exe for a CLI tool; --ext=rust or --ext=c for native extensions
```

Persist preferences globally so future runs don't prompt:
```bash
bundle config set --global gem.test rspec
bundle config set --global gem.linter standard
bundle config set --global gem.ci github
bundle config set --global gem.mit true
bundle config set --global gem.coc true
bundle config set --global gem.changelog true
```

## Step 2 — Complete the gemspec (generation leaves TODOs)

Open `GEM_NAME.gemspec` and fix every `TODO`:
- `summary` (one line), `description` (longer), `homepage`, `metadata["source_code_uri"]`,
  `metadata["changelog_uri"]`, `metadata["rubygems_mfa_required"] = "true"`
- `required_ruby_version` — set to oldest version you'll support (`>= 3.1.0`)
- Runtime deps via `spec.add_dependency`; dev deps go in Gemfile, NOT gemspec
- See `references/gemspec-checklist.md` for the full checklist.

## Step 3 — Verify the skeleton works

```bash
cd GEM_NAME
bin/setup                 # installs deps
bundle exec rake          # runs tests + linter (default task)
rake -T                   # see all tasks (build, install, release)
```

## Step 4 — TDD the first feature

Write the failing spec first (`spec/GEM_NAME_spec.rb`), then implement in
`lib/GEM_NAME.rb`. Keep `lib/GEM_NAME/version.rb` as the single version source.

## Conventions (enforce these)

- One class/module per file mirroring the path: `lib/my_tool/parser.rb` → `MyTool::Parser`
- Everything namespaced under the gem's root module — never pollute global namespace
- `require_relative` inside lib/; plain `require "my_tool"` for consumers
- Semantic versioning; CHANGELOG entry per release
- Release flow: bump version.rb → update CHANGELOG → `bundle exec rake release`
  (tags git, pushes, publishes to rubygems.org)

## Detailed references (read only when needed)

- `references/bundle-gem-options.md` — every flag from the official man page
- `references/gemspec-checklist.md` — production-ready gemspec checklist
- `references/linter-choice.md` — RuboCop vs Standard decision guide
