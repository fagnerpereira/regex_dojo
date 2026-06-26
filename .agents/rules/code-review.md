---
description: Layered review methodology and verdict rules for reviewing changes in Anonymous Pix
globs: **/*
---

# Code Review Principles

Adapted for Anonymous Pix from GitLab's review playbook. Use when reviewing a diff,
an MR/PR, or your own change before declaring it done. Pairs with the
`code-reviewer` agent and the `pr-review-reply` skill.

## Review in layers (in order)

1. **Scope & intent** — understand what the change is for before judging how it does it.
2. **Architecture** — does it fit existing Anonymous Pix patterns (Phlex views, `app/services/` POROs for flows, association-scoped access, admin under `Admin::`)? Does it add debt?
3. **Blockers** — regressions, security holes, missing error handling, untested branches, N+1s, pattern violations, unreachable code.
4. **Improvements** — non-blocking but meaningful suggestions.
5. **Nitpicks** — style/naming/minor inconsistencies. Label them explicitly as nitpicks so the author knows they do not block.

## Verdict

- Any blocker present → **request changes**. DO NOT approve with unresolved blockers.
- Nitpicks only → approve; note them, do not block.
- No issues → approve.

## Minimal-change principle

Prefer the smallest change that correctly solves the problem. Flag scope creep —
files or layers touched beyond what the task requires add risk without benefit.
Question whether each extra change is genuinely load-bearing.

## Verify before flagging

When a diff modifies existing code, verify the current state from an
authoritative source before claiming a discrepancy. NEVER infer the pre-change
state from diff context alone. Examples:

- Migration `down`/schema: check `db/schema.rb` on the base branch (`git show main:db/schema.rb`), not the diff.
- Method/behavior changes: read the actual file on `main`, not just the surrounding hunk.

## Stop speculating — observe runtime

When a bug resists 1–2 fix attempts, stop guessing through code alone. Get a
direct runtime observation: failing spec output, `rails console` result, a log
line, the rendered Phlex HTML, the actual SQL. Ask one precise question
("what does this scope return?", "what classes are on this element?") — one
observation beats many rounds of code-reading.
