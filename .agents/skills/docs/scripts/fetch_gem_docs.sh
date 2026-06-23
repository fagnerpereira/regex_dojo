#!/usr/bin/env bash
# .claude/scripts/fetch_gem_docs.sh
#
# Local-first documentation fetcher — Context7 replacement.
#
# Priority:
#   1. LOCAL GEM SOURCE  via `bundle show <gem>`  (installed gems — no network)
#   2. LOCAL RAILS CLONE via tmp/rails_docs/       (only if you maintain one — none in this repo)
#   3. WEB FETCH         curl the canonical URL    (fallback when local unavailable)
#
# Usage:
#   .claude/scripts/fetch_gem_docs.sh <gem> [keyword_or_topic]
#
# Examples:
#   .claude/scripts/fetch_gem_docs.sh rails "strict_loading"
#   .claude/scripts/fetch_gem_docs.sh money-rails "monetize"
#   .claude/scripts/fetch_gem_docs.sh turbo-rails "streams"
#   .claude/scripts/fetch_gem_docs.sh phlex-rails "view_template"
#   .claude/scripts/fetch_gem_docs.sh rspec-rails "request spec"

set -euo pipefail

GEM="${1:?Usage: fetch_gem_docs.sh <gem> [keyword]}"
KEYWORD="${2:-}"
RAILS_DOCS="tmp/rails_docs"
LOCKFILE="Gemfile.lock"

# ─── helpers ─────────────────────────────────────────────────────────────────
strip_html()  { sed 's/<[^>]*>//g' | tr -s ' \n'; }
narrow()      { [ -n "$KEYWORD" ] && grep -A 50 -i "$KEYWORD" | head -60 || head -80; }
md_section()  { [ -n "$KEYWORD" ] && awk -v pat="^[#]+.*$(echo "$KEYWORD" | tr '[:upper:]' '[:lower:]')" 'tolower($0) ~ pat, /^#+ /' | head -80 || head -80; }
info()        { echo "[$1] $2" >&2; }

gem_path() {
  # Returns the local install path for a gem, or empty string if not found
  bundle show "$1" 2>/dev/null || echo ""
}

version_from_lock() {
  local g="${1//-/_}"  # normalize hyphens
  local v
  v=$(grep -P "^    ${1} \\(\\d" "$LOCKFILE" 2>/dev/null | head -n1 | sed -E 's/.* \(([^)]+)\).*/\1/')
  [ -z "$v" ] && \
  v=$(grep -P "^    ${g} \\(\\d" "$LOCKFILE" 2>/dev/null | head -n1 | sed -E 's/.* \(([^)]+)\).*/\1/')
  echo "$v"
}

# ─── detect version ───────────────────────────────────────────────────────────
VERSION=$(version_from_lock "$GEM")
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)

echo "=== ${GEM} ${VERSION:-?} ==="
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
#  RAILS — special case: use local clone (guides as Markdown) when available
# ═══════════════════════════════════════════════════════════════════════════════
handle_rails() {
  local topic="${KEYWORD:-}"

  # ── Tier 1: local clone (best — Markdown, greppable, no network) ───────────
  if [ -d "$RAILS_DOCS/guides/source" ]; then
    info "SOURCE" "Local clone: $RAILS_DOCS/guides/source"

    # Map common keywords to the right guide file
    declare -A GUIDE_MAP=(
      ["query|where|includes|preload|eager|scope|find|pluck|strict_loading|n+1|n\+1"]="active_record_querying.md"
      ["migration|schema|add_column|create_table|index"]="active_record_migrations.md"
      ["validation|validates|valid?"]="active_record_validations.md"
      ["callback|before_|after_|around_"]="active_record_callbacks.md"
      ["association|belongs_to|has_many|has_one|polymorphic|delegated_type"]="association_basics.md"
      ["routing|route|resources|namespace|concern"]="routing.md"
      ["controller|strong_param|before_action|rescue_from"]="action_controller_overview.md"
      ["cache|caching|fragment|russian|solid_cache"]="caching_with_rails.md"
      ["background|job|queue|solid_queue|perform"]="active_job_basics.md"
      ["mailer|mail|deliver"]="action_mailer_basics.md"
      ["turbo|hotwire|frame|stream"]="working_with_javascript_in_rails.md"
      ["test|rspec|minitest|system|request|capybara"]="testing.md"
      ["storage|attachment|blob|activestorage"]="active_storage_overview.md"
      ["websocket|cable|channel|action_cable"]="action_cable_overview.md"
      ["security|csrf|xss|sql.injection"]="security.md"
      ["engine|mountable|plugin"]="engines.md"
      ["generator|scaffold|template"]="generators.md"
      ["current|current_attributes"]="active_support_instrumentation.md"
    )

    local matched_guide=""
    for pattern in "${!GUIDE_MAP[@]}"; do
      if echo "$topic" | grep -qiE "$pattern"; then
        matched_guide="${GUIDE_MAP[$pattern]}"
        break
      fi
    done

    if [ -n "$matched_guide" ] && [ -f "$RAILS_DOCS/guides/source/$matched_guide" ]; then
      info "GUIDE" "$matched_guide"
      cat "$RAILS_DOCS/guides/source/$matched_guide" | md_section
      return
    fi

    # No exact guide match — grep across all guides
    if [ -n "$topic" ]; then
      info "GREP" "Searching all guides for: $topic"
      grep -r -l -i "$topic" "$RAILS_DOCS/guides/source/" 2>/dev/null | head -5 | while read -r f; do
        echo ""
        echo "─── $(basename $f) ───"
        grep -A 15 -i "$topic" "$f" | head -40
      done
      return
    fi

    # No keyword — list available guides
    echo "Available guides (pass a keyword to search):"
    ls "$RAILS_DOCS/guides/source/"*.md | xargs -n1 basename | sed 's/.md$//'
    return
  fi

  # ── Tier 2: installed gem source (lib/ is there, but no guides) ──────────
  local rp
  rp=$(gem_path "railties")
  if [ -n "$rp" ]; then
    info "SOURCE" "Installed railties: $rp"
    echo "[NOTE] No local Rails guides clone in this repo."
    echo "       Falling back to installed source + web guides (pin to 7.1)."
    echo ""
  fi

  # ── Tier 3: web (fallback) ─────────────────────────────────────────────────
  local guide_name
  guide_name=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
  local url="https://guides.rubyonrails.org/${guide_name}.html"
  info "WEB" "$url"
  curl -fsL --max-time 10 "$url" 2>/dev/null | strip_html | narrow || \
    curl -fsL --max-time 10 "https://guides.rubyonrails.org/" 2>/dev/null | \
      strip_html | grep -i "$topic" | head -20
}

# ═══════════════════════════════════════════════════════════════════════════════
#  ALL OTHER GEMS — local install via `bundle show` (no clone needed)
# ═══════════════════════════════════════════════════════════════════════════════
handle_gem() {
  local gem_name="$1"
  local path
  path=$(gem_path "$gem_name")

  if [ -n "$path" ] && [ -d "$path" ]; then
    info "LOCAL" "$path"
    echo ""

    # ── Special: Phlex v1 vs v2 API detection ──────────────────────────────
    if [[ "$gem_name" == phlex* ]]; then
      if [ "$MAJOR" -ge 2 ]; then
        echo "⚠  PHLEX v2: use 'def view_template' (NOT def template)"
      else
        echo "⚠  PHLEX v1: use 'def template' (view_template is v2+)"
      fi
      echo ""
    fi

    # ── 1. README (best narrative docs) ─────────────────────────────────────
    local readme
    readme=$(find "$path" -maxdepth 1 -iname "readme*" | head -1)
    if [ -n "$readme" ]; then
      info "README" "$readme"
      cat "$readme" | md_section
      return
    fi

    # ── 2. CHANGELOG (for version-specific changes) ──────────────────────────
    if echo "$KEYWORD" | grep -qi "change\|upgrade\|deprecat\|break\|new in"; then
      local changelog
      changelog=$(find "$path" -maxdepth 1 -iname "changelog*" | head -1)
      if [ -n "$changelog" ]; then
        info "CHANGELOG" "$changelog"
        cat "$changelog" | head -100
        return
      fi
    fi

    # ── 3. Source grep — best for method signatures ───────────────────────────
    if [ -n "$KEYWORD" ]; then
      info "GREP SOURCE" "$path/lib/"
      grep -r -n "$KEYWORD" "$path/lib/" 2>/dev/null | grep -v "\.rbc" | head -30
      echo ""
      # Also show test examples (tests = best usage docs)
      local test_dir
      test_dir=$(find "$path" -maxdepth 1 -type d -name "test" -o -maxdepth 1 -type d -name "spec" | head -1)
      if [ -n "$test_dir" ]; then
        info "TESTS (usage examples)" "$test_dir"
        grep -r -l -i "$KEYWORD" "$test_dir" 2>/dev/null | head -3 | while read -r f; do
          echo "─── $(basename $f) ───"
          grep -A 8 -i "$KEYWORD" "$f" | head -25
        done
      fi
      return
    fi

    # ── 4. No keyword: show public API (method list) ──────────────────────────
    info "PUBLIC API" "$path/lib/"
    find "$path/lib" -name "*.rb" -maxdepth 3 | while read -r f; do
      grep -E "^\s+def (self\.)?\w+" "$f" | grep -v "private\|protected" | head -20
    done | head -50

  else
    # ── Tier 2: gem not installed — web fallback ──────────────────────────────
    info "WEB" "gem not installed locally, falling back to web"
    web_fallback "$gem_name"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  WEB FALLBACK — only hits network when gem is not installed
# ═══════════════════════════════════════════════════════════════════════════════
web_fallback() {
  local gem_name="$1"
  declare -A WEB_URLS=(
    ["turbo-rails"]="https://turbo.hotwired.dev/handbook/introduction"
    ["stimulus-rails"]="https://stimulus.hotwired.dev/handbook/introduction"
    ["phlex"]="https://raw.githubusercontent.com/phlex-ruby/phlex/v${VERSION}/README.md"
    ["view_component"]="https://viewcomponent.org/guide/getting-started.html"
    ["action_policy"]="https://actionpolicy.evilmartians.io/"
    ["pagy"]="https://ddnexus.github.io/pagy/"
  )

  local url="${WEB_URLS[$gem_name]:-https://rubydoc.info/gems/${gem_name}/${VERSION}}"
  info "WEB" "$url"
  curl -fsL --max-time 10 "$url" 2>/dev/null | strip_html | narrow
}

# ─── dispatch ────────────────────────────────────────────────────────────────
case "$GEM" in
  rails|activerecord|actionpack|actionview|railties|activesupport|activejob|actionmailer)
    handle_rails
    ;;
  *)
    handle_gem "$GEM"
    ;;
esac

echo ""
echo "=== Done: $GEM ${VERSION:-?} ==="
