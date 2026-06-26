# Dependency Security PRs (standalone)

Scan for vulnerable dependencies and open one PR per fix — done entirely by Claude using local tools (`bundler-audit`, `npm audit`, `gh`). **No dependency on GitHub's Dependabot service.** It can run alongside GitHub Dependabot; to avoid branch collisions this skill uses its own `deps/` branch namespace.

## Arguments (`$ARGUMENTS`)

- _(none)_ — security vulnerabilities only (Ruby + JS)
- `--all` — all outdated packages, not just vulnerable ones
- `--ruby` — Ruby/Bundler only
- `--js` — JavaScript/npm only

---

## Step 1 — Ensure audit tools are available

**Ruby**: ensure `bundler-audit` is installed, then refresh the advisory DB:

```bash
gem list bundler-audit | grep -q bundler-audit || gem install bundler-audit
bundle-audit update
```

**JS**: `npm audit` is built into npm — no installation needed.

---

## Step 2 — Collect vulnerabilities

### Ruby audit

```bash
bundle-audit check 2>&1
```

For each finding, extract:

- **gem name** (e.g. `nokogiri`)
- **installed version** (e.g. `1.15.7`)
- **advisory ID** (GHSA/CVE) and **criticality**
- **solution / patched version** (e.g. `>= 1.19.3`)

When a gem has **multiple advisories**, pick the **highest** required patched version so one bump clears them all (e.g. advisories needing `>= 1.18.3`, `>= 1.19.1`, `>= 1.19.3` → target `1.19.3`).

If `$ARGUMENTS` includes `--all` (or there are no CVEs), also run `bundle outdated --strict 2>&1` and collect gems with available updates.

### JS audit

```bash
npm audit 2>&1
```

For each finding extract: package name, installed version, severity, fix version. Note transitive-only vulns (fixable via the parent or a resolution, not a direct bump) and report them rather than forcing a direct update. If `--all`, also run `npm outdated`.

---

## Step 3 — For each vulnerable dependency, open one PR

Work through each dependency one at a time. For each:

### 3a — Skip if a PR already exists

```bash
gh pr list --head "deps/bundler/<gem-name>" --state open --json number,title
# JS:
gh pr list --head "deps/npm/<pkg-name>" --state open --json number,title
```

Also check whether GitHub Dependabot already has an open PR for the same bump (`gh pr list --search "<gem-name> in:title author:app/dependabot" --state open`). If either exists, print a notice and skip — no duplicate.

### 3b — Resolve current and target versions

Ruby — current locked version from `Gemfile.lock`:

```bash
grep -A1 "^    <gem-name> " Gemfile.lock | head -2
```

JS — read from `package-lock.json` or `package.json`.

Target = lowest version satisfying the advisory's patched range (or latest stable if `--all`).

### 3c — Create the branch from the default branch

```bash
git fetch origin main
git checkout -b deps/bundler/<gem-name>-<new-version> origin/main
# JS:
git checkout -b deps/npm/<pkg-name>-<new-version> origin/main
```

Branch namespace is `deps/` (not `dependabot/`) so this never collides with GitHub Dependabot's branches.

### 3d — Update the dependency

**Ruby** — update only the target gem, respect other constraints:

```bash
bundle update <gem-name> --conservative
```

Verify in `Gemfile.lock`:

```bash
grep -A1 "^    <gem-name> " Gemfile.lock
```

**If the version did not reach the patched range** (Bundler says "stayed the same", or it landed below the advisory's solution), the bump is BLOCKED by another gem's constraint. Do NOT open a PR. Identify and report the blocker:

```bash
bundle exec ruby -e "puts Bundler.load.specs.select{|s| s.dependencies.any?{|d| d.name=='<gem-name>'}}.map{|s| \"#{s.name} #{s.version} -> #{s.dependencies.find{|d| d.name=='<gem-name>'}.requirement}\"}"
```

Report it as `BLOCKED — <blocking-gem> requires <constraint>` in the summary so the human can decide (relax upstream, fork, replace, or accept the risk). Revert the lockfile (`git checkout Gemfile.lock`) before moving on.

**JS**:

```bash
npm install <package-name>@<target-version>   # updates package-lock.json
```

### 3e — Commit

Stage only the lockfile (and `Gemfile` / `package.json` if a constraint was pinned):

```bash
git add Gemfile.lock            # Ruby
git add package-lock.json package.json   # JS
```

Commit message matches this repo's dependency convention:

```
chore(deps): bump <name> from <old-version> to <new-version>
```

Example:

```bash
git commit -m "chore(deps): bump nokogiri from 1.15.7 to 1.19.3"
```

### 3f — Push the branch

```bash
git push origin HEAD
```

### 3g — Fetch metadata for the PR body

**Ruby** — homepage / source / changelog from RubyGems:

```bash
curl -s "https://rubygems.org/api/v1/gems/<gem-name>.json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('homepage:', d.get('homepage_uri',''))
print('source:', d.get('source_code_uri',''))
print('changelog:', d.get('changelog_uri',''))
"
```

**JS** — from the npm registry:

```bash
curl -s "https://registry.npmjs.org/<package-name>/latest" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('homepage:', d.get('homepage',''))
print('repository:', d.get('repository',{}).get('url','') if isinstance(d.get('repository'),dict) else d.get('repository',''))
"
```

### 3h — Open the PR (honest, standalone body)

Use `gh pr create`. Substitute all `<placeholders>`. The body is clear about what changed and why, with no GitHub-Dependabot service references, badges, or `@dependabot` commands (those would not work — no bot manages these PRs).

```bash
gh pr create \
  --title "chore(deps): bump <name> from <old-version> to <new-version>" \
  --label "dependencies" \
  --label "<ruby|javascript>" \
  --body "$(cat <<'PREOF'
Bumps **[<name>](<homepage-or-source-url>)** from `<old-version>` to `<new-version>`.

**Why:** <security fix for `<advisory-id>` (<criticality>) — <advisory title> | routine update>

| | |
|---|---|
| Advisory | [<advisory-id>](<advisory-url>) |
| Patched in | `<patched-range>` (updating to lowest safe `<new-version>`) |
| Changed files | `<lockfile>` only — other deps untouched (`--conservative`) |

📋 [Changelog](<changelog-url>) · 🔗 [Source / compare](<source-url>) · 🏠 [Homepage](<homepage-url>)

<sub>Opened by the local `/dependabot` skill (Claude Code) — independent of GitHub Dependabot. Rebase/update by re-running the skill, not via bot commands.</sub>
PREOF
)"
```

For routine (`--all`) updates with no advisory, drop the Advisory/Patched rows and set **Why** to a one-line update rationale.

---

## Step 4 — Return to the working branch

```bash
git checkout -
```

---

## Step 5 — Summary report

```
Package          | Ecosystem | Old version | New version | PR
-----------------|-----------|-------------|-------------|----
nokogiri         | bundler   | 1.15.7      | 1.19.3      | #44
hono             | npm       | …           | …           | transitive — see note
```

If no vulnerabilities were found: `✓ No security vulnerabilities found in Ruby or JS dependencies.`

---

## Important notes

- **One PR per dependency** — never bundle multiple packages into one PR.
- **Always branch from the default branch** (`main`), never from the current working branch.
- **Own `deps/` namespace** — keeps these PRs from colliding with GitHub Dependabot's `dependabot/` branches; both can run side by side.
- **Skip duplicates** — check both this skill's open PRs and Dependabot's before creating.
- **Never force-push** — if a branch already exists remotely, skip and report it.
- **Transitive JS vulns** — don't force a direct bump; report them and suggest the parent update or a `resolutions`/`overrides` entry.
- **Labels** — create them if missing:
  ```bash
  gh label create "dependencies" --color "0075ca" --description "Pull requests that update a dependency file" 2>/dev/null || true
  gh label create "ruby" --color "cc342d" 2>/dev/null || true
  gh label create "javascript" --color "f1e05a" 2>/dev/null || true
  ```
- If `bundle update --conservative` bumps more than the target gem, warn and ask before proceeding with that PR.
