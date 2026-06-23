# Code smells — Fowler taxonomy with Rails manifestations

Five families (refactoring.guru/refactoring/smells). For each: how it shows up
in Rails specifically, and the idiomatic fix.

## 1. Bloaters (grow over time, hard to work with)

**Long Method** — Rails: controller actions doing find + authorize + mutate +
notify + respond; model callbacks with embedded business processes.
→ Extract Method; in controllers, push logic to the model (`card.close(by: Current.user)`).
Sandi Metz heuristic: methods ≤ 5 lines is aspirational, > 15 is a smell.

**Large Class** — Rails: the God model (User/Order with 800 lines).
→ Extract Concern — but COHESIVE ones (Fizzy style: `Closeable`, `Watchable`),
never junk drawers (`UserMethods`). If behavior isn't model-lifecycle-bound,
extract a model-namespaced PORO (`User::Filtering`, `Order::Pricing`).

**Primitive Obsession** — Rails: `amount_cents` integer + `currency` string
passed as a pair everywhere; status strings compared by literal.
→ Replace Data Value with Object: `Data.define(:cents, :currency)` value object,
or composed_of; for statuses, `enum` (AR) gives predicate methods free.

**Long Parameter List** — Rails: service `.call(user, board, card, notify, async)`.
→ Keyword arguments (Ruby-native fix); Introduce Parameter Object when params
travel together repeatedly; or question why this isn't a method ON one of them.

**Data Clumps** — same 2-3 attributes appearing together across signatures
(street/city/zip, start_date/end_date).
→ Extract Class (Address, DateRange — Ruby's Range often suffices).

## 2. Object-Orientation Abusers

**Switch Statements** (case/when on type) — Rails: `case record.type` or
`case status` re-implemented in N methods.
→ Replace Conditional with Polymorphism: STI methods, delegated_type targets,
or simple hash dispatch `HANDLERS.fetch(status).call`. ONE case statement in a
factory is fine; the same case duplicated is the smell.

**Temporary Field** — instance vars only set during one operation.
→ Replace Method with Method Object (the operation becomes its own PORO —
this is how legit service objects are BORN, not decreed).

**Refused Bequest** — subclass overrides parent methods to raise/no-op.
Rails: STI subclasses stubbing out irrelevant parent behavior (LSP violation).
→ Replace Inheritance with Delegation, or delegated_type instead of STI.

**Alternative Classes with Different Interfaces** — two classes doing the same
job with different method names (duck-typing broken).
→ Rename Method until ducks quack alike; extract shared module.

## 3. Change Preventers

**Divergent Change** — one class edited for many unrelated reasons.
Rails: model changed for pricing AND notifications AND export logic.
→ Extract Class/Concern per axis of change (this IS SRP, applied when pain is real).

**Shotgun Surgery** — one conceptual change requires edits in many files.
Rails: a status value checked by literal string in 12 places.
→ Move Method/Field to consolidate; enum + predicate methods; constants.

**Parallel Inheritance Hierarchies** — adding SomethingA forces SomethingAPolicy,
SomethingASerializer, SomethingAJob...
→ Often acceptable in Rails (conventional pairing); smell only when hierarchies
are deep. Collapse via convention-based lookup (`"#{model}Policy".constantize`).

## 4. Dispensables (delete with joy)

**Comments** — explaining WHAT code does (vs WHY).
→ Extract Method named after the comment; rename variables. Keep WHY-comments.

**Duplicate Code** — → Extract Method/Concern/partial — AFTER third occurrence.
In views: partials with strict locals. In specs: shared_examples (sparingly).

**Lazy Class** — class not earning its keep (the 3-line service object!).
→ Inline Class back into its caller/model.

**Data Class** — attributes + accessors, zero behavior. Rails: a model used as
a dumb struct while its logic lives in "managers"/services (anemic domain).
→ Move Methods INTO the model — this is the anti-service-object smell.

**Dead Code** — → Delete. Coverage + grep before removing public API.

**Speculative Generality** — hooks/params/abstractions for futures that never
came ("we might need multiple payment providers someday").
→ Collapse Hierarchy, Inline Class, Remove Parameter. YAGNI enforced.

## 5. Couplers

**Feature Envy** — method using another object's data more than its own.
Rails: helper/controller reaching into model internals to compute something.
→ Move Method into the envied class.

**Inappropriate Intimacy** — classes touching each other's privates.
Rails: model A querying model B's table directly, bypassing B's API.
→ Move Method/Field; have B expose an intention-revealing method or scope.

**Message Chains** — `order.customer.address.city` (Law of Demeter).
→ Hide Delegate: `delegate :city, to: :address, prefix: true` on Customer.
Exception: AR association chains in queries are idiomatic; the smell is in
domain logic traversal, not `includes(customer: :address)`.

**Middle Man** — class delegating everything, adding nothing.
→ Remove Middle Man (talk to the real object). The inverse of Hide Delegate —
balance per Demeter pain, not dogma.
