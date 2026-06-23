---
name: docs
description: >
  Look up documentation for any Ruby gem or Rails feature using LOCAL sources
  (bundle show) before any network fetch. Use when you need to verify an API,
  method signature, configuration option, or gem-specific behavior — instead of
  answering from training data. Triggers: "how does X work", "what's the API for",
  "check the docs", "which version", or before writing any gem-specific code.
---

# Local-first docs lookup

NEVER answer gem-API questions from training data. Detect → locate → read.

## The hierarchy

```
1. bundle show <gem>   → installed gem (README, CHANGELOG, lib/, spec/)  — no network
2. web fallback        → only when the gem is NOT installed, or for Rails guides
```

## Step 1 — Detect version (always first)

```bash
scripts/gem_version.sh <gem>          # exact version from Gemfile.lock
```

## Step 2 — Fetch docs

```bash
scripts/fetch_gem_docs.sh <gem> "<keyword>"
```

The script handles all tiers automatically. Examples:

```bash
scripts/fetch_gem_docs.sh phlex-rails "view_template"  # → bundle show + v1/v2 warning
scripts/fetch_gem_docs.sh rspec-rails "request"        # → bundle show README
scripts/fetch_gem_docs.sh money-rails "monetize"       # → bundle show README section
```

## Manual lookups (when the script isn't enough)

```bash
# Read installed gem files directly
cat $(bundle show phlex-rails)/README.md | grep -A 30 "view_template"
grep -rn "def monetize" $(bundle show money-rails)/lib/
cat $(bundle show turbo-rails)/CHANGELOG.md | head -60
grep -rn "turbo_stream" $(bundle show turbo-rails)/test/ | head -20   # tests = usage docs
```

## Version-sensitive APIs — check before writing code

- **Phlex:** major ≥ 2 → `def view_template`; major 1 → `def template` (this app pins `phlex-rails ~> 1.2`)
- **Rails:** this app is **7.1** — `params.expect` is 8.0+ (use `params.require(...).permit(...)`); Solid Cache/Cable defaults are 8.0 (only `solid_queue` is present here)
- When unsure, read the installed source: `grep -r "def <method>" $(bundle show <gem>)/lib/`

## Detailed mappings (read only when needed)

- `references/rails-guides-map.md` — topic → Rails guide
- `references/url-map.md` — web fallback URLs per gem

## Rails guides

There is no local Rails guides clone in this repo — for Rails guide content,
use `bundle show rails`-installed framework source for behavior, and fall back to
guides.rubyonrails.org / api.rubyonrails.org (pin to the 7.1 version) for prose.
