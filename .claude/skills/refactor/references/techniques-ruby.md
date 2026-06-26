# Refactoring techniques — Fowler catalog in Ruby idioms

Six families (refactoring.guru/refactoring/techniques). Ruby-specific notes:
many techniques are one-liners here that take ceremony in Java.

## Composing Methods

**Extract Method** — the workhorse.

```ruby
# Before                              # After
def print_owing                       def print_owing
  puts "name: #{@name}"                 print_banner
  puts "amount: #{outstanding}"         print_details(outstanding)
end                                   end
```

Name the method after intent, not mechanics. Private methods are free.

**Inline Method** — body clearer than the name → inline it. Kills Lazy Class
helpers (`def active? = status == "active"` might stay; `def is_active = active?` dies).

**Extract Variable** — name a complex expression. Ruby: prefer this over comments.
**Inline Temp / Replace Temp with Query** — temps block Extract Method; turn
them into private query methods. Memoize (`@x ||=`) ONLY if measured-hot and side-effect-free.

**Split Temporary Variable** — one var, two purposes → two vars.
**Remove Assignments to Parameters** — mutating params is hostile in Ruby
(callers share references); assign to a local.

**Replace Method with Method Object** — a long method whose locals resist
extraction becomes a class; locals become ivars; then Extract Method freely.
THIS is the legitimate birth of `Order::PriceCalculator`. In Rails, namespace
it under the model.

**Substitute Algorithm** — replace the body wholesale with a clearer approach
(often: replace manual loop with Enumerable — `sum`, `tally`, `each_slice`,
`group_by`, `filter_map`).

## Moving Features Between Objects

**Move Method / Move Field** — to the class whose data it uses (kills Feature Envy).
**Extract Class** — split a class doing two jobs. Rails order of preference:
concern (lifecycle-bound) → model-namespaced PORO → standalone class.
**Inline Class** — the reverse; kills Lazy Class.
**Hide Delegate** — `delegate :street, to: :address` (Rails has it built-in).
**Remove Middle Man** — when a class is ONLY delegation, talk directly.
**Introduce Foreign Method / Local Extension** — Ruby: a refinement or a
wrapper class. AVOID monkey-patching core classes; prefer a module function
(`TimeMath.next_business_day(date)`).

## Organizing Data

**Self Encapsulate Field** — use accessors even internally when subclasses
may override. Ruby: `attr_reader` + override beats raw ivars.
**Replace Data Value with Object** — `Data.define(:cents, :currency)` (3.2+),
`Struct.new(keyword_init: true)`, or a frozen PORO. Equality by value.
**Change Value to Reference / Reference to Value** — identity vs equality;
value objects should be immutable (`freeze`).
**Replace Array with Object** — `[name, qty, price]` positional → object/Data.
**Replace Magic Number with Symbolic Constant** — `MAX_RETRIES = 3`. Rails:
config or `class_attribute` when tunable.
**Encapsulate Collection** — return dups/frozen views; expose `add_x`/`remove_x`
instead of the raw array. Rails: AR associations already do this — don't expose
mutable cached arrays from POROs.
**Replace Type Code with Class/Subclasses/State-Strategy** — Rails ladder:
`enum` (cheapest) → STI subclasses → delegated_type → State pattern PORO
(only when transitions carry behavior).
**Replace Subclass with Fields** — subclasses differing only in constant
return values → one class with attributes (collapse STI you didn't need).

## Simplifying Conditional Expressions

**Decompose Conditional** — extract condition AND branches into named methods:
`if eligible_for_discount?(order)` reads like the spec.
**Consolidate Conditional Expression** — multiple checks, same result → one
predicate method joining them.
**Replace Nested Conditional with Guard Clauses** — Ruby loves this:

```ruby
def pay_amount
  return deceased_amount if deceased?
  return separated_amount if separated?
  return retired_amount if retired?
  normal_pay_amount
end
```

**Remove Control Flag** — use `break`/`return`/`find` instead of `found = true`.
**Replace Conditional with Polymorphism** — case/when on type → method per type.
Lightweight Ruby alternative: hash dispatch `RATES.fetch(plan).call(usage)`.
**Introduce Null Object** —

```ruby
class GuestUser
  def name = "Guest"
  def can_administer?(_) = false
end
def current_user = super || GuestUser.new
```

Kills scattered `user&.name || "Guest"`.
**Introduce Assertion** — Ruby: raise early with a message; in Rails models
prefer validations + DB constraints over inline assertions.

## Simplifying Method Calls

**Rename Method** — cheapest, highest-value. Intention-revealing names.
**Add/Remove Parameter** — Ruby: keyword args with defaults absorb most Adds.
**Separate Query from Modifier** — `found_miscreant?` (query) vs `alert_guards!`
(command). Bang for mutation, `?` for predicates — never both jobs in one method.
**Parameterize Method** — `five_percent_raise`/`ten_percent_raise` → `raise_by(pct)`.
**Replace Parameter with Explicit Methods** — opposite: `set_value(:height, h)`
→ `height=`. When the param is always a literal, split.
**Preserve Whole Object** — pass `range` not `range.low, range.high`.
But beware coupling: passing the whole AR model into a PORO couples it to AR;
sometimes the two values are the better dependency.
**Introduce Parameter Object** — recurring arg group → Data/Struct.
**Remove Setting Method** — immutability: set in constructor, no writer.
**Hide Method** — `private` aggressively; public API is a liability.
**Replace Constructor with Factory Method** — `Payment.for(method)` returning
the right subclass; idiomatic for STI/delegated_type instantiation.
**Replace Error Code with Exception** — Ruby never returns error codes; the
Rails flavor: prefer `save` + handling over `save!` in expected-failure flows,
and raise domain errors (`InsufficientFunds < StandardError`) for exceptional ones.
**Replace Exception with Test** — using rescue for control flow → check first
(`hash.fetch(key, default)` instead of rescuing KeyError).

## Dealing with Generalization

**Pull Up Method/Field/Constructor Body** — shared subclass code → superclass.
Ruby: usually → a MODULE instead (composition over inheritance).
**Push Down Method/Field** — superclass behavior used by one subclass → move down.
**Extract Subclass** — features used by some instances only. Rails: consider
delegated_type before STI.
**Extract Superclass** — two classes, shared behavior. Ruby: Extract MODULE
is almost always better (no single-inheritance slot consumed).
**Extract Interface** — Ruby has no interfaces; duck typing + a shared spec
(`it_behaves_like "a notifier"`) IS the interface.
**Collapse Hierarchy** — subclass ≈ superclass → merge (kills Speculative Generality).
**Form Template Method** — same algorithm shape, different steps:

```ruby
class Report
  def generate = [header, body, footer].join("\n")  # template
  private
  def header = raise NotImplementedError
end
```

Ruby alternative: pass blocks/procs for the varying steps.
**Replace Inheritance with Delegation** — Refused Bequest fix. Ruby:
`SimpleDelegator`, or Forwardable's `def_delegators`.
**Replace Delegation with Inheritance** — when delegating EVERYTHING, inherit
(or in Ruby, include the module).
