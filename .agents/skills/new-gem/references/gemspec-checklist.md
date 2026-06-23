# Gemspec checklist — production-ready before first release

`bundle gem` leaves TODOs that BLOCK `gem build`. Fix all of these:

## Required (build fails without them)
```ruby
spec.summary     = "One-line description (shows in gem list)"
spec.description = "Longer paragraph (shows on rubygems.org)"
spec.homepage    = "https://github.com/USER/GEM_NAME"
```

## Metadata (strongly recommended)
```ruby
spec.metadata["homepage_uri"]    = spec.homepage
spec.metadata["source_code_uri"] = "https://github.com/USER/GEM_NAME"
spec.metadata["changelog_uri"]   = "https://github.com/USER/GEM_NAME/blob/main/CHANGELOG.md"
spec.metadata["rubygems_mfa_required"] = "true"   # require MFA to push — do this
# Remove the allowed_push_host TODO line (it's for private gem servers)
```

## Ruby version
```ruby
spec.required_ruby_version = ">= 3.1.0"   # oldest you'll actually support/test
```

## Dependencies — the golden rule
```ruby
# RUNTIME deps → gemspec (what consumers need)
spec.add_dependency "zeitwerk", "~> 2.6"

# DEVELOPMENT deps → Gemfile, NOT gemspec (modern bundle gem convention)
# Gemfile already has: rake, rspec/minitest, standard/rubocop
```
Version constraints on runtime deps: pessimistic (`~> 2.6`) — never unbounded,
never exact-pinned (`= 2.6.1` causes resolution hell for consumers).

## Files — what gets packaged
The generated gemspec uses git to list files. Verify nothing secret/dev-only ships:
```bash
gem build GEM_NAME.gemspec
gem contents --all GEM_NAME-0.1.0.gem 2>/dev/null || tar -tzf GEM_NAME-0.1.0.gem
```
Exclude spec/, test/, .github/ via the gemspec's `reject` block (default does this).

## Release flow
```bash
# 1. bump lib/GEM_NAME/version.rb
# 2. update CHANGELOG.md (Keep a Changelog format)
# 3. commit
bundle exec rake release   # builds, tags vX.Y.Z, pushes tag, pushes to rubygems.org
```

## Semantic versioning
- PATCH (0.1.1): bugfix, no API change
- MINOR (0.2.0): new features, backwards-compatible
- MAJOR (1.0.0): breaking changes — document migration in CHANGELOG
- Stay 0.x until the public API is stable; 1.0.0 is a stability promise
