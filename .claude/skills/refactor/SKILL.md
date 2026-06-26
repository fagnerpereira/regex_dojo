---
name: refactor
description: >
  Refactor Ruby/Rails code by identifying code smells (Fowler/refactoring.guru
  taxonomy) and applying the matching refactoring technique with Ruby idioms.
  Use when the user asks to refactor, clean up, simplify, improve, or "this code
  smells", or when a method/class has grown too large or complex. Also use
  proactively when about to modify code that exhibits clear smells.
---

# Smell-driven refactoring (Fowler catalog, Rails idioms)

## Iron rules (XP discipline)

1. **Green before and after.** Never refactor without passing tests. If tests
   are missing, write a characterization spec FIRST that pins current behavior.
2. **One smell → one technique → one commit.** Small reversible steps.
3. **Behavior-preserving.** Refactoring changes structure, never behavior.
   If you're changing behavior, that's a feature/fix — separate commit.
4. **Rule of three.** Don't abstract duplication until the third occurrence.
5. **Rails Way first.** Before any GoF-style extraction, check if a Rails
   construct solves it: concern, scope, delegated_type, normalizes, store_accessor.

## Workflow

1. **Diagnose** — name the smell(s) using the taxonomy in
   `references/smells-rails.md` (Bloaters, OO Abusers, Change Preventers,
   Dispensables, Couplers — each with its Rails-specific manifestation).
2. **Verify coverage** — `bundle exec rspec <related specs>`. Missing? Write
   characterization specs first.
3. **Apply the technique** — pick from `references/techniques-ruby.md`
   (Fowler's catalog translated to Ruby idioms). Cite the technique by name
   in the commit message: `Refactor: Extract Method on Order#total_with_tax`.
4. **Re-run** specs + linter after EACH step, not just at the end.
5. **Stop** at "good enough to change" — not perfection. No speculative generality.

## Quick smell → technique map (full tables in references/)

| Smell                          | First-choice technique (Ruby/Rails)                          |
| ------------------------------ | ------------------------------------------------------------ |
| Long Method                    | Extract Method (private methods reading like a sentence)     |
| Large Class / fat model        | Extract Concern (cohesive!) or model-namespaced PORO         |
| Primitive Obsession            | Replace Data Value with Object (Value object, `Data.define`) |
| Long Parameter List            | Introduce Parameter Object / keyword args                    |
| Switch/case on type            | Replace Conditional with Polymorphism (or hash dispatch)     |
| Nested conditionals            | Replace Nested Conditional with Guard Clauses                |
| Feature Envy                   | Move Method to the class whose data it craves                |
| Message Chains (`a.b.c.d`)     | Hide Delegate (`delegate :street, to: :address`)             |
| nil checks everywhere          | Introduce Null Object                                        |
| Temp variables obscuring logic | Replace Temp with Query / Extract Variable                   |
| Duplicate Code (3rd time)      | Extract Method/Class/Concern; partials in views              |
| Speculative Generality         | DELETE it (inline class, collapse hierarchy, remove param)   |
| Comments explaining "how"      | Extract Method named after the comment                       |

## Deep dives (fetch only when needed — allowed doc references)

- Catalog index: https://refactoring.guru/refactoring/catalog
- Specific technique: https://refactoring.guru/<technique-slug>
  (e.g. /extract-method, /replace-temp-with-query, /introduce-null-object)
- Specific smell: https://refactoring.guru/smells/<smell-slug>
- Fetch pattern: `curl -fsL URL | sed 's/<[^>]*>//g' | grep -A 40 -i "How to Refactor"`

## Anti-goals

- Don't introduce service objects/DI/interfaces to "fix" a smell vanilla Rails
  handles (see /rails-review and /design-pattern skills).
- Don't refactor and reformat unrelated code in the same diff.
- Don't chase RuboCop Metrics cops into unreadable micro-methods —
  readability is the goal, the metric is a proxy.
