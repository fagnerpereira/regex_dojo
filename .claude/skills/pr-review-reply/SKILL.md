---
name: pr-review-reply
description: >
  Triage and reply to open review comments on a GitHub pull request. For each
  comment, decide whether the suggestion makes sense, reply inline with the
  reasoning, and implement it (via TDD) when it does. NEVER resolve the threads —
  leave them open for the human to read. Use when the user says "answer the PR
  comments", "address the review feedback", "go through the review suggestions",
  or names a PR to respond to.
---

# Reply to PR review comments

Driver reads the discussion himself — your job is to engage each comment with
reasoning and code, not to close threads. See the `feedback_pr_review_comments`
memory: reply with reasoning + fix via TDD; **NEVER mark a thread resolved**.

## Step 1 — Collect the open inline comments

```bash
PR=<number>; REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
# Inline (review) comments — the ones anchored to a file/line:
gh api "repos/$REPO/pulls/$PR/comments" \
  --jq '.[] | "ID:\(.id)\t\(.path):\(.line // .original_line)\t@\(.user.login)\n\(.body)\n---"'
# Top-level review summaries (context, not always actionable):
gh pr view "$PR" --json reviews --jq '.reviews[] | "\(.author.login): \(.state)\n\(.body)"'
```

Skip comments already replied to (an existing reply in the same thread from you)
unless the user asks to revisit them. A `bot` author (e.g. `gemini-code-assist`,
`coderabbitai`) is fine to engage — judge the suggestion on its merits, not its source.

## Step 2 — Judge each suggestion on its merits

For every comment decide: **does this make sense for THIS repo?** Verify the claim
against the actual code and version-matched docs — do not accept or reject from
memory. Useful lenses:

- Is the bug/risk it describes real here? Reproduce it (a quick shell/spec check) before agreeing.
- Does it fit the repo's conventions (root `CLAUDE.md`, `.agents/rules/`)?
- Is it a genuine improvement, or style churn / a regression / out of scope?

## Step 3 — Respond

**If it makes sense:** implement it. Code change → follow TDD (failing test first
unless the change is non-logic, e.g. a script/regex/doc — then prove it with a
direct before/after run). Then reply quoting *why* it's right and what you changed:

```bash
gh api "repos/$REPO/pulls/$PR/comments/<COMMENT_ID>/replies" \
  -f body="Good catch — this makes sense because <concrete reason>. Implemented in <sha>: <one-line what changed>. Verified: <evidence>."
```

**If it does NOT make sense:** do not implement. Reply with the specific reason —
cite the code, convention, or doc that makes the suggestion wrong/unneeded here:

```bash
gh api "repos/$REPO/pulls/$PR/comments/<COMMENT_ID>/replies" \
  -f body="Thanks — I don't think this applies here because <specific reason: code ref / convention / version fact>. Leaving as-is."
```

Reply to EVERY open comment either way. One reply per thread, anchored to its
comment id (`/comments/<id>/replies` keeps it threaded).

## Step 4 — Commit, push, and STOP

- Commit the accepted changes to the PR branch and push (so replies can cite the sha).
- **NEVER** resolve/minimize the threads. Do not call any resolve mutation.
  The human reads each open thread to follow the reasoning himself.
- Report a per-comment summary: id → makes-sense? → action taken.

## Guardrails

- Stay on the PR's branch; never force-push or touch `main`.
- If a suggestion is large or risky, reply with your assessment and ask before
  implementing rather than guessing.
- Honour the root `CLAUDE.md` (TDD, smallest diff, double quotes, standardrb).
