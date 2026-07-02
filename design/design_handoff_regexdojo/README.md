# Handoff: RegexDojo — UI Design

## Overview
RegexDojo is a playful, gamified web app for learning regular expressions. Users earn belts (white → black), keep daily streaks, complete "katas" (challenges), and climb a leaderboard. This package covers 7 screens: onboarding, home/dashboard, an interactive regex playground, a lesson/challenge detail view, a belt skill-tree, a leaderboard, and a profile.

## About the design files
The bundled `RegexDojo.dc.html` is a **design reference**, built in an internal prototyping tool (inline-styled HTML/React, not production code). It is *not* meant to be copied verbatim into the Rails app. Your task is to **recreate these screens as Phlex components styled with Tailwind CSS**, wired into your existing Rails + Hotwire (Stimulus/Turbo) app, following the patterns below.

Open `RegexDojo.dc.html` in a browser to see every screen full-size, plus 3 explored variations of the playground (only variation "3a" — the live split editor — is interactive; treat it as the reference for the real playground).

## Fidelity
**High-fidelity.** Colors, type, spacing, and copy below are final — implement pixel-for-pixel where practical, adjusting only for your existing Tailwind config scale.

## Design tokens
See `tokens.md` for the full extracted palette/type/radius scale and a ready-to-paste `tailwind.config` fragment.

## Stack mapping
- **Views** → Phlex components (see `phlex/`), one class per reusable piece (`UI::Button`, `UI::Pill`, `UI::Card`, `UI::Belt`) plus one per screen (`Screens::Home`, `Screens::Playground`, …).
- **Styling** → Tailwind utility classes only, using the token extensions in `tokens.md`. No custom CSS files needed beyond `@font-face` for the three webfonts.
- **The regex playground's live behavior** (typing a pattern/flags/test string and seeing matches update instantly) → implemented client-side only, no server round trip needed. See `stimulus/regex_playground_controller.js` — a Stimulus controller that runs `new RegExp(...)` in the browser and re-renders match pills + highlighted preview on every keystroke. Sketch included in `phlex/screens/playground.rb`.
- Everything else (nav clicks, "Submit solution", "Start today's kata") is a normal Turbo-driven Rails link/button — no special JS needed.

## Screens

### 1. Onboarding
Two-step flow, two cards side by side (stack on narrow viewports): a centered welcome card with a step-dot indicator and CTA, then a level-picker card with 3 selectable rows (radio-style, active row gets a 2px violet border + tinted background).

### 2. Home / Dashboard
Top bar (logo, nav, streak chip, avatar) → hero row: a large violet gradient "Daily Kata" card (title, blurb, CTA, giant faded kanji watermark) beside a circular progress ring card (belt %, "X of Y katas to next belt") → 4 stat tiles (XP, katas solved, accuracy, rank) → a "Continue your path" panel with 3 lesson-progress cards (done / in-progress / locked states, each with a progress bar).

### 3. Playground (the interactive one — build this for real)
Split layout: left = pattern input (monospace, dark editor chrome) with clickable g/i/m flag toggle pills, an inline error banner when the regex is invalid, an editable test-string textarea, and a live-highlighted preview (matches wrapped in `<mark>`). Right = a scrollable match list (each match + its `start:end` range) with a match-count badge and a green "pattern is valid" banner when there's ≥1 match.

Two more variations exist as static design exploration only (inline-highlight-only layout, and an "explain mode" that labels capture groups) — not required for v1, but good reference for a "regex explainer" feature later.

### 4. Lesson / Challenge detail
Left column: challenge brief (badge, title, description, a hint box, solved-count/first-try-rate stats). Right column: the user's pattern (read-only editor chrome + a "lazy quantifier detected" validation line), a list of test cases each showing pass/fail, and Submit/Reset buttons.

### 5. Challenges — skill tree
A horizontal belt path (white → yellow → green → blue → brown → black) as circular nodes connected by a progress line (green where complete, violet gradient node = current, locked nodes greyed with a lock icon). Below: 3 topic cards (done / current / locked) each with their own progress bar.

### 6. Leaderboard
Ranked list rows (gold/silver/bronze special background tint for top 3, "You" row gets a 2px violet border), each row: rank, avatar, name, belt, XP. Week/All-time toggle pills at top.

### 7. Profile
Gradient header (avatar, name, belt + join date + streak, Edit button) → 3 stat tiles → a badge grid (earned badges full-color, locked badges at 40% opacity with a lock glyph).

## Interactions & behavior
- **Flag toggle pills** (g/i/m): click toggles that flag on/off; active = solid violet bg + white text, inactive = light violet bg + violet text.
- **Pattern/test-string inputs**: on every change, recompute matches client-side (see Stimulus controller). Invalid regex → red error banner, matches list empty, badge shows "—".
- **Reset button**: restores the default hex-color example pattern/flags/test string.
- **Lesson test cases**: static pass/fail for the mock; in the real app these should reflect actual regex evaluation against each test string using the same client-side match logic as the playground.
- No page-level animations; card hover states are just the existing Tailwind `hover:` treatments described per-component below.

## Design tokens
See `tokens.md`.

## Assets
No image assets — all icons are emoji (🥋 🔥 🏆 etc.) and the small "道" kanji glyph, rendered as text, not images. If your brand guidelines prefer real iconography instead of emoji, swap 1:1, keeping sizes.

## Files in this package
- `RegexDojo.dc.html` — full interactive design reference (open in a browser).
- `tokens.md` — color/type/radius tokens + Tailwind config fragment.
- `phlex/ui/button.rb`, `phlex/ui/pill.rb`, `phlex/ui/card.rb`, `phlex/ui/belt.rb` — shared Phlex components.
- `phlex/screens/home.rb` — full worked example screen.
- `phlex/screens/playground.rb` — the interactive playground screen + Stimulus hookup.
- `stimulus/regex_playground_controller.js` — client-side live regex evaluation.

A developer who wasn't in this conversation should be able to implement the app from this README + the two example Phlex files + tokens.md alone; the remaining 5 screens follow the same component vocabulary (`UI::Card`, `UI::Pill`, `UI::Belt`, `UI::Button`) described in the screens section above.
