#!/usr/bin/env bash
# .claude/skills/docs/scripts/gem_version.sh
# Usage: ./gem_version.sh rails
# Returns: 7.1.6 (exact RESOLVED version from Gemfile.lock)
# Falls back to: bundle info output
#
# Portable: uses awk/sed only (POSIX). Avoids `grep -P`/`\K`, which are
# GNU/PCRE-only and fail on stock macOS BSD grep.

GEM="${1:?Usage: gem_version.sh <gem_name>}"
LOCKFILE="${2:-Gemfile.lock}"

# Extract the resolved version for gem $1 from a Gemfile.lock-style file.
# Matches "    <gem> (<version>)" where the version starts with a digit (so
# dependency constraints like "(>= 7.0.0)" are skipped), then strips any
# platform suffix ("1.19.3-x86_64-linux-gnu" -> "1.19.3").
lock_version() {
  awk -v g="$1" '$1==g && $2 ~ /^\([0-9]/ { v=$2; gsub(/[()]/,"",v); split(v,a,"-"); print a[1]; exit }' "$LOCKFILE"
}

if [ ! -f "$LOCKFILE" ]; then
  echo "No Gemfile.lock found — trying bundle info..." >&2
  # Pull the first "(<version>)" token from bundle info, strip platform suffix.
  bundle info "$GEM" 2>/dev/null | sed -n 's/.*(\([0-9][^)]*\)).*/\1/p' | head -1 | cut -d- -f1
  exit 0
fi

# Try exact match first, then the hyphen ↔ underscore alternate form.
VERSION=$(lock_version "$GEM")

if [ -z "$VERSION" ]; then
  ALT="${GEM//_/-}"
  [ "$ALT" = "$GEM" ] && ALT="${GEM//-/_}"
  VERSION=$(lock_version "$ALT")
fi

if [ -z "$VERSION" ]; then
  echo "Gem '$GEM' not found in $LOCKFILE — check spelling or run: bundle info $GEM" >&2
  exit 1
fi

echo "$VERSION"
