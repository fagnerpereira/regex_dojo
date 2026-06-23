# `bundle gem` — complete options (from bundler.io/man/bundle-gem.1.html)

Generates `GEM_NAME/` with Rakefile, gemspec, lib skeleton, and supporting files.
Run `rake -T` in the result for test/build/release tasks.

## Test framework
| Flag | Effect |
|---|---|
| `--test=rspec` | spec/ skeleton, rspec in Gemfile, rake task |
| `--test=minitest` | test/ skeleton (37signals style) |
| `--test=test-unit` | test/ skeleton with test-unit |
| `--no-test` | no test framework |

Unspecified → uses global config `gem.test`, else interactive prompt (answer saved globally).

## Linter
| Flag | Effect |
|---|---|
| `--linter=rubocop` | adds rubocop + `.rubocop.yml` |
| `--linter=standard` | adds standard + `.standard.yml` |
| `--no-linter` | none |

Unspecified → global config `gem.linter`, else prompt.
(Legacy `--rubocop` flag still exists; prefer `--linter`.)

## CI
| Flag | Effect |
|---|---|
| `--ci=github` | `.github/workflows/main.yml` |
| `--ci=gitlab` | `.gitlab-ci.yml` |
| `--ci=circle` | `.circleci/config.yml` |
| `--no-ci` | none |

## Files & extras
| Flag | Effect |
|---|---|
| `--exe` / `-b` | creates `exe/GEM_NAME` binary, added to gemspec |
| `--ext=c` | C extension boilerplate |
| `--ext=rust` | Rust extension boilerplate (magnus-based) |
| `--mit` | LICENSE.txt with MIT (name from git config) |
| `--coc` | CODE_OF_CONDUCT.md |
| `--changelog` | CHANGELOG.md |
| `--git` | init a git repo |
| `--github-username=X` | fills README links |
| `--bundle` / `--no-bundle` | run `bundle install` after (or not) |
| `--edit[=EDITOR]` | open gemspec in editor |

## Global config keys (set once, skip all prompts forever)
```bash
bundle config set --global gem.test rspec
bundle config set --global gem.linter standard
bundle config set --global gem.ci github
bundle config set --global gem.mit true
bundle config set --global gem.coc true
bundle config set --global gem.changelog true
bundle config set --global gem.github_username YOUR_USERNAME
```

## Generated structure (with --test=rspec --linter=standard --ci=github --exe)
```
my_tool/
├── .github/workflows/main.yml
├── .standard.yml
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── Gemfile                  # dev deps here (rake, rspec, standard)
├── LICENSE.txt
├── README.md
├── Rakefile                 # default task: spec + standard
├── bin/console              # irb with gem loaded
├── bin/setup
├── exe/my_tool              # the CLI binary
├── lib/my_tool.rb           # entry point, requires version + files
├── lib/my_tool/version.rb   # VERSION constant — single source of truth
├── my_tool.gemspec
├── sig/my_tool.rbs          # RBS type signatures
└── spec/
    ├── my_tool_spec.rb
    └── spec_helper.rb
```

## Naming rules (rubygems convention)
- Underscore for multi-word standalone gems: `my_tool` → `require "my_tool"` → `MyTool`
- Dash ONLY when extending another gem: `rspec-retry` → `require "rspec/retry"` → `RSpec::Retry`
- Check name availability: `gem search ^NAME$ -r` or visit rubygems.org/gems/NAME
