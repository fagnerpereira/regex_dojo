---
name: design-pattern
description: >
  Apply (or correctly AVOID) GoF design patterns in Ruby/Rails. Use when the
  user mentions a pattern by name (factory, strategy, observer, decorator,
  adapter, singleton...), asks "what pattern fits here", or when about to
  introduce an abstraction that a pattern formalizes. Prevents Java-style
  over-engineering by mapping each pattern to its idiomatic Ruby equivalent.
---

# GoF patterns in Ruby — apply the idiom, not the diagram

## The prime directive

In Ruby, many patterns DISSOLVE into language features. Before writing
pattern classes, check `references/gof-ruby-map.md`: if the pattern column
says "language feature" or "Rails built-in", use THAT. A pattern's intent
matters; its Java class structure usually doesn't.

Refactoring.guru's own criticism page concedes patterns can be "inefficient
solutions" formalizing what dynamic languages do natively — Ruby is the
canonical example.

## Decision protocol

1. **Name the problem, not the pattern.** "I need to swap pricing algorithms"
   — not "I need Strategy."
2. **Check the dissolution table** (`references/gof-ruby-map.md`):
   - Language feature? (blocks, modules, duck typing) → use it, zero classes
   - Rails built-in? (delegated_type, enum, broadcasts, CurrentAttributes) → use it
   - Genuine pattern territory? → smallest Ruby implementation (see references)
3. **Apply the 37signals test**: can vanilla Rails do this? Is the complexity
   worth it? Will it make the codebase harder to understand?
4. **Implement with a spec first**, behaviors not structure: test WHAT it does,
   not that it "is a Strategy."

## Quick dissolution table (full version + code in references/)

| You're about to write... | Use instead |
|---|---|
| Strategy classes | A lambda/proc, method object, or hash dispatch |
| Template Method hierarchy | Module with hook methods, or yield a block |
| Observer infrastructure | AR callbacks (same-model), Turbo broadcasts (UI), ActiveSupport::Notifications (cross-cutting) |
| Singleton class | A module with module_function, or Rails config/CurrentAttributes |
| Decorator chain | SimpleDelegator, or a helper/partial (view concerns) |
| Factory Method classes | `Payment.for(type)` class method; delegated_type |
| Command objects | A method object PORO with #call (= legit service object) |
| Adapter | A thin wrapper class — this one survives intact in Ruby |
| Facade | A module function orchestrating subsystems — survives intact |
| Builder | Keyword args + with_options; AR's `new` + block |
| State machine | enum + guard methods; state classes only when transitions carry behavior |
| Iterator | NEVER — Enumerable + each IS the pattern |
| Visitor | Pattern matching (`case ... in`) or double-dispatch via duck typing |
| Proxy | method_missing + define_method, or SimpleDelegator |
| Chain of Responsibility | Array of handlers + `find { |h| h.handles?(req) }` |

## When a full pattern IS right

- **Adapter/Facade** around third-party APIs (isolate the boundary — also makes
  VCR/WebMock specs clean)
- **Strategy as classes** when strategies have their own dependencies/config/specs
- **State as classes** when each state has multiple behaviors + transition rules
- **Null Object** always cheap, frequently right

## Deep dives (allowed doc references — fetch on demand)

- Pattern pages: https://refactoring.guru/design-patterns/<pattern-slug>
  (e.g. /strategy, /observer, /decorator) — each has a "Pseudocode" and
  language-specific examples including Ruby at /design-patterns/<slug>/ruby/example
- Catalog: https://refactoring.guru/design-patterns/catalog
- Ruby examples index: https://refactoring.guru/design-patterns/ruby
- Fetch: `curl -fsL URL | sed 's/<[^>]*>//g' | grep -A 30 -i "Applicability"`
