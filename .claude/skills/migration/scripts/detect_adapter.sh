#!/usr/bin/env bash
# scripts/detect_adapter.sh — which database is this project using?
# Output: adapter name + version + which reference file to load

set -euo pipefail

ADAPTER=""

# 1. config/database.yml (authoritative)
if [ -f config/database.yml ]; then
  ADAPTER=$(grep -E "^\s+adapter:" config/database.yml | head -1 | awk '{print $2}' | tr -d '"' || echo "")
fi

# 2. Fallback: Gemfile.lock driver gems
if [ -z "$ADAPTER" ] && [ -f Gemfile.lock ]; then
  grep -qE "^\s+pg \(" Gemfile.lock        && ADAPTER="postgresql"
  grep -qE "^\s+mysql2 \(" Gemfile.lock    && ADAPTER="mysql2"
  grep -qE "^\s+trilogy \(" Gemfile.lock   && ADAPTER="trilogy"
  grep -qE "^\s+sqlite3 \(" Gemfile.lock   && ADAPTER="${ADAPTER:-sqlite3}"
fi

case "$ADAPTER" in
  postgresql|postgis)
    echo "ADAPTER: PostgreSQL"
    command -v psql >/dev/null && psql --version 2>/dev/null | head -1
    # Server version matters for safety rules (PG11+ instant defaults, PG12+ NOT NULL via constraint)
    bin/rails runner 'puts "Server: #{ActiveRecord::Base.connection.select_value(%q(SHOW server_version))}"' 2>/dev/null || true
    echo "LOAD: references/postgresql.md"
    ;;
  mysql2|trilogy)
    echo "ADAPTER: MySQL/MariaDB (driver: $ADAPTER)"
    bin/rails runner 'puts "Server: #{ActiveRecord::Base.connection.select_value(%q(SELECT VERSION()))}"' 2>/dev/null || true
    # 8.0.12+ = INSTANT add_column; 8.0.29+ = INSTANT any position; 8.0.16+ = CHECK constraints
    echo "LOAD: references/mysql.md"
    ;;
  sqlite3)
    echo "ADAPTER: SQLite"
    sqlite3 --version 2>/dev/null | awk '{print "Server: " $1}' || true
    # 3.25+ = RENAME COLUMN; 3.35+ = DROP COLUMN
    echo "LOAD: references/sqlite.md"
    ;;
  "")
    echo "ADAPTER: not detected — check config/database.yml manually" >&2
    exit 1
    ;;
  *)
    echo "ADAPTER: $ADAPTER (no specific reference; apply universal rules + verify locking behavior in adapter docs)"
    ;;
esac

# Multi-database setups (Rails 6+): list all configured
if [ -f config/database.yml ] && grep -qE "^\s+(primary|queue|cache|cable):" config/database.yml; then
  echo ""
  echo "MULTI-DB detected — adapters per role:"
  grep -E "^\s+(primary|queue|cache|cable|replica.*):|^\s+adapter:" config/database.yml | head -20
fi
