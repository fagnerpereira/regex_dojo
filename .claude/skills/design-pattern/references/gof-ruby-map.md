# GoF 22 → Ruby/Rails dissolution map (with code)

For each pattern: intent, Ruby verdict, idiomatic implementation.
Verdicts: DISSOLVES (language feature), RAILS-NATIVE (framework built-in),
SURVIVES (worth implementing as designed), RARE (almost never in app code).

## Creational

### Factory Method — RAILS-NATIVE / dissolves to class method

Intent: defer instantiation choice to a method.

```ruby
class Payment
  def self.for(method, **attrs)
    { pix: PixPayment, card: CardPayment, boleto: BoletoPayment }
      .fetch(method.to_sym).new(**attrs)
  end
end
```

Rails-native: STI + delegated_type ARE factory infrastructure (`entry.entryable`).

### Abstract Factory — RARE

Families of related objects. App code: a config-selected module usually suffices:
`Billing.gateway` returning Stripe/Pagarme wrapper per env. Full pattern only
in library code shipping pluggable backends.

### Builder — DISSOLVES (keyword args, blocks)

```ruby
Card.new(title:, board:, due_on: 1.week.from_now) { |c| c.tags << urgent }
# Multi-step construction that must end valid → AR's new+block, or a form object
```

A real Builder class is justified for telescoping construction of immutable
values (rare; consider Data.define with `with`).

### Prototype — DISSOLVES (`dup`/`deep_dup`)

```ruby
template = Board.find_by!(template: true)
new_board = template.deep_dup.tap { |b| b.template = false }
```

Rails: `record.dup` (unsaved copy, no id/timestamps); amoeba gem only for
deep association cloning at scale.

### Singleton — DISSOLVES / RAILS-NATIVE

Almost never the GoF class. Ruby ladder:

```ruby
module Clock; module_function; def now = Time.current; end   # stateless
Rails.application.config.x.feature_flags                      # app config
Current.user                                                  # per-request (CurrentAttributes)
```

`require "singleton"` exists; using it in app code is usually a smell
(global mutable state). Solid Cache/Queue connections are managed for you.

## Structural

### Adapter — SURVIVES (the most legitimate pattern in Rails apps)

Isolate third-party APIs behind your own interface:

```ruby
class Sms::TwilioAdapter
  def deliver(to:, body:)
    client.messages.create(from: from_number, to: to, body: body)
  rescue Twilio::REST::RestError => e
    raise Sms::DeliveryError, e.message
  end
end
# Swap in specs: Sms.adapter = Sms::FakeAdapter.new — no WebMock in unit specs
```

### Bridge — RARE

Abstraction/implementation split. Ruby: composition + duck typing gets you
there without the formal hierarchy. If you're drawing the UML, stop.

### Composite — SURVIVES (when trees are the domain)

Comments-with-replies, nested folders. Rails-native helpers: `ancestry` or
closure_tree gems; pure version is each node responding to the same interface
with children. Don't force it on flat data.

### Decorator — DISSOLVES (SimpleDelegator) / view-layer = helpers

```ruby
class CardPresenter < SimpleDelegator
  def due_badge = overdue? ? "🔴 #{due_on}" : due_on.to_s
end
CardPresenter.new(card)  # responds to everything Card does + extras
```

37signals verdict: helpers + partials before presenters; presenters when view
logic clusters around one model. Never gem-sized (draper) by default.

### Facade — SURVIVES (as a module function)

```ruby
module Onboarding
  module_function
  def run(user)
    Account.provision(user)
    WelcomeMailer.with(user:).hello.deliver_later
    Analytics.track(user, :signed_up)
  end
end
```

This is the acceptable face of "service" — a named entry point over subsystems.

### Flyweight — RARE

Memory sharing for massive object counts. Ruby: frozen string literals,
`Symbol`s, and constants already are flyweights. App-level need ≈ never.

### Proxy — DISSOLVES

Lazy loading: AR associations ARE lazy proxies (`user.cards` is a Relation,
not an Array). Access control: a SimpleDelegator that raises on forbidden
methods. Remote proxy: your API client class.

## Behavioral

### Chain of Responsibility — DISSOLVES (array + find)

```ruby
HANDLERS = [Refund::FullHandler, Refund::PartialHandler, Refund::DenyHandler]
def handler_for(request) = HANDLERS.map(&:new).find { _1.handles?(request) }
```

Rack middleware IS this pattern — you use it daily.

### Command — DISSOLVES (method object = the legit service object)

```ruby
class Card::Closer
  def initialize(card, by:) = (@card, @by = card, by)
  def call = Card.transaction { @card.create_closure!(user: @by); notify }
end
```

Undo/queueing variants: Active Job IS Command (serialized invocation).

### Iterator — DISSOLVES COMPLETELY

`include Enumerable` + define `each`. Writing an Iterator class in Ruby is
a category error.

### Mediator — RARE / RAILS-NATIVE

Centralized object communication. Rails: the controller already mediates;
Turbo Streams mediate UI updates. A Mediator class in app code usually means
the model layer is anemic.

### Memento — DISSOLVES (state-as-records)

Snapshot/restore. Rails way: don't snapshot in memory — persist state changes
as records (Fizzy's Closure pattern), or paper_trail for audit/undo.

### Observer — RAILS-NATIVE (three flavors, choose by scope)

```ruby
after_commit :sync_search_index           # same-model lifecycle
broadcasts_to :board                       # UI observers via Turbo
ActiveSupport::Notifications.instrument("card.closed", card:)  # cross-cutting
```

Plus Active Job for async observers. Never hand-roll subscribe/notify.

### State — DISSOLVES (enum) until behavior-heavy, then SURVIVES

```ruby
enum :status, { draft: 0, published: 1, archived: 2 }  # predicates + scopes free
# Graduate to state classes ONLY when each state carries multiple behaviors:
def state = STATES.fetch(status).new(self)   # state.editable?, state.transition_to(...)
```

AASM/state_machines gems: the 37signals test says enum + explicit methods first.

### Strategy — DISSOLVES (procs/method objects/hash dispatch)

```ruby
SHIPPING = {
  standard: ->(o) { o.weight * 1.0 },
  express:  ->(o) { o.weight * 2.5 + 10 },
}.freeze
SHIPPING.fetch(order.shipping_method.to_sym).call(order)
```

Classes when strategies need deps/config/individual specs:
`Pricing::Tiered.new(tiers).price(usage)`.

### Template Method — DISSOLVES (modules + hooks, or blocks)

```ruby
module Exportable
  def export = [headers, rows, footer].compact.join("\n")
  private
  def footer = nil          # hook with default
  def headers = raise NotImplementedError
end
```

Or invert: `def export = yield(rows)` — pass the varying step as a block.

### Visitor — DISSOLVES (pattern matching, Ruby 3+)

```ruby
case node
in Heading(level:, text:) then render_heading(level, text)
in Paragraph(text:)       then render_para(text)
in CodeBlock(lang:, code:) then highlight(lang, code)
end
```

Double-dispatch Visitor classes only for open-ended node sets in library code.

## Cross-reference: pattern ↔ smell it fixes

| Smell                          | Pattern-shaped fix                                    |
| ------------------------------ | ----------------------------------------------------- |
| Switch Statements              | Strategy (hash dispatch) / State / Polymorphism       |
| Primitive Obsession            | Value Object (Data.define)                            |
| nil-check sprawl               | Null Object                                           |
| 3rd-party API leakage          | Adapter                                               |
| Long Method w/ stubborn locals | Command (method object)                               |
| Refused Bequest                | Replace Inheritance with Delegation (SimpleDelegator) |
