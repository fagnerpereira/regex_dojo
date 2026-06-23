#!/usr/bin/env bash
# scripts/new_gem.sh — opinionated gem scaffolder wrapper
#
# Usage:
#   scripts/new_gem.sh my_tool                          # rspec + standard + github (defaults)
#   scripts/new_gem.sh my_tool --linter=rubocop         # override linter
#   scripts/new_gem.sh my_tool --exe                    # CLI gem
#   scripts/new_gem.sh my_tool --test=minitest --no-ci  # 37signals style
#
# Checks name availability on rubygems.org first, then runs bundle gem
# with sane defaults, then prints the gemspec TODOs that must be fixed.

set -euo pipefail

NAME="${1:?Usage: new_gem.sh <gem_name> [bundle gem options...]}"
shift || true

# ── validate name ─────────────────────────────────────────────────────────────
if [[ ! "$NAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
  echo "ERROR: gem names should be lowercase letters, digits, _ or -" >&2
  echo "  underscore = standalone gem (my_tool → MyTool)" >&2
  echo "  dash       = extends another gem (rspec-retry → RSpec::Retry)" >&2
  exit 1
fi

# ── check availability on rubygems.org ────────────────────────────────────────
echo "▶ Checking name availability on rubygems.org..."
if gem search "^${NAME}$" -r 2>/dev/null | grep -q "^${NAME} "; then
  echo "⚠  '$NAME' is TAKEN on rubygems.org:" >&2
  gem search "^${NAME}$" -r >&2
  echo "   Pick another name (or this is intentional for a private gem — ctrl-c to abort, enter to continue)" >&2
  read -r
else
  echo "✓ '$NAME' is available"
fi

# ── defaults (overridable by passing flags) ───────────────────────────────────
DEFAULTS=(--test=rspec --linter=standard --ci=github --mit --coc --changelog --git)

# If user passed any --test/--linter/--ci flag, drop the conflicting default
for arg in "$@"; do
  case "$arg" in
    --test=*|--no-test)     DEFAULTS=("${DEFAULTS[@]/--test=rspec}") ;;
    --linter=*|--no-linter) DEFAULTS=("${DEFAULTS[@]/--linter=standard}") ;;
    --ci=*|--no-ci)         DEFAULTS=("${DEFAULTS[@]/--ci=github}") ;;
    --no-mit)               DEFAULTS=("${DEFAULTS[@]/--mit}") ;;
    --no-coc)               DEFAULTS=("${DEFAULTS[@]/--coc}") ;;
    --no-changelog)         DEFAULTS=("${DEFAULTS[@]/--changelog}") ;;
  esac
done

# ── generate ──────────────────────────────────────────────────────────────────
echo "▶ Running: bundle gem $NAME ${DEFAULTS[*]} $*"
# shellcheck disable=SC2086
bundle gem "$NAME" ${DEFAULTS[*]} "$@"

# ── surface the gemspec TODOs ─────────────────────────────────────────────────
echo ""
echo "▶ Gemspec TODOs that MUST be fixed before 'gem build' works:"
grep -n "TODO" "${NAME}/${NAME}.gemspec" || echo "  (none found)"

echo ""
echo "▶ Next steps:"
echo "  1. cd $NAME && fix gemspec TODOs (see .claude/skills/new-gem/references/gemspec-checklist.md)"
echo "  2. bin/setup"
echo "  3. bundle exec rake        # tests + linter must pass on the skeleton"
echo "  4. Write your first failing spec, then implement (TDD)"
