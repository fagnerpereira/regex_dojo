#!/usr/bin/env bash
# .claude/hooks/validate-commands.sh - Deterministic validation for Claude Code
INPUT=$(cat)
# Parse the command out of the hook JSON with Ruby (jq is not guaranteed on PATH).
COMMAND=$(printf '%s' "$INPUT" | ruby -rjson -e 'print(JSON.parse(STDIN.read).dig("tool_input", "command").to_s)' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Protect against attempts to read sensitive environment details.
# Use word-boundary-aware patterns to avoid false positives on legitimate commands
# like "bundle exec rails environment" or "RAILS_ENV=test".
BLOCKED=false

# Exact command matches (dangerous on their own)
if [[ "$COMMAND" =~ ^(printenv|env)($|[[:space:]]) ]]; then
  BLOCKED=true
fi

# Substring patterns for clearly sensitive content
SENSITIVE_PATTERNS=("cat .env" "cat.env" "aws_key" "secret_key" "API_KEY" "ACCESS_TOKEN")
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    BLOCKED=true
    break
  fi
done

if [ "$BLOCKED" = true ]; then
  echo "BLOCKED: The command contains protected keywords or attempts to read sensitive environment details." >&2
  exit 2
fi

exit 0
