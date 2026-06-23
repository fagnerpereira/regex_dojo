---
name: api
description: >
  Design and implement JSON APIs in Rails following REST best practices —
  versioning, consistent error envelopes, pagination, filtering, auth, and
  serialization. Covers both Rails (API mode / namespaced controllers) and
  Grape. Use when creating API endpoints, designing API responses, adding
  versioning, or reviewing API code.
---

# API implementation — native-first

## Step 0 — Detect the stack

```bash
grep -E "^\s+(grape|jbuilder|alba|blueprinter|jsonapi-serializer) " Gemfile.lock
ls app/api 2>/dev/null && echo "Grape structure present"
```
Grape present → follow Grape forms below. Otherwise → Rails controllers.
Full request/response contract details: `references/rest-contract.md`.

## REST conventions (non-negotiable)

- **Nouns, plural, no verbs**: `GET /api/v1/orders`, never `/getOrders`.
  Custom actions become nested resources (Fizzy rule applies to APIs too):
  `POST /orders/:id/cancellation` not `POST /orders/:id/cancel`.
- **Status codes carry meaning**: 200 read, 201 create (+ Location header),
  204 delete/no-body, 400 malformed, 401 unauthenticated, 403 unauthorized,
  404 not found (also for cross-tenant — don't leak existence), 409 conflict,
  422 validation, 429 rate-limited, 500 never intentional.
- **Versioning**: URL path (`/api/v1/`) — most discoverable, cache-friendly.
  Header versioning only when URL stability is a hard requirement.
  New version ONLY for breaking changes; additive changes don't bump.

## The error envelope (one shape, everywhere)

```json
{ "error": { "code": "validation_failed", "message": "Title can't be blank",
             "details": [{ "field": "title", "code": "blank" }] } }
```
Rails: centralize in a concern with `rescue_from` (RecordNotFound→404,
RecordInvalid→422, ParameterMissing→400, your AuthError→401/403).
Grape: `rescue_from` blocks + `error!({ error: {...} }, 422)`.
NEVER leak exception classes/backtraces in production responses.

## Controller shape (Rails API)

```ruby
module Api::V1
  class OrdersController < Api::BaseController   # auth + rescue_from live in Base
    def index
      orders = current_user.orders                 # scope-before-find ALWAYS
        .then { filter(_1) }                       # whitelisted params only
      pagy, records = pagy(orders)                 # see pagination below
      render json: OrderSerializer.many(records, meta: pagy_meta(pagy))
    end

    def create
      order = current_user.orders.create!(order_params)  # 422 via rescue_from
      render json: OrderSerializer.one(order), status: :created,
             location: api_v1_order_url(order)
    end

    private
      # Rails 7.1: params.require(...).permit(...). (params.expect is 8.0+.)
      def order_params = params.require(:order).permit(:product_id, :quantity)
  end
end
```

## Pagination, filtering, sorting

- Paginate EVERY collection endpoint from day one (unbounded lists are
  incidents waiting). Expose `page[number]`/`page[size]` or `page`/`per_page`;
  cap `per_page` (≤100); return meta: `{ page, pages, count, next }`.
  Cursor pagination (`after: <id>`) for feeds/infinite scroll — stable under
  inserts, no OFFSET cost.
- Filtering: whitelist explicitly (`filterable = %w[status category_id]`);
  never interpolate params into SQL.
- Sorting: whitelist columns AND directions; default deterministic
  (`order(created_at: :desc, id: :desc)` — tiebreaker prevents cursor bugs).

## Auth for APIs

- Same-app (Hotwire + a few JSON endpoints): session auth works fine.
- External consumers: Bearer token — native first:
  `has_secure_token :api_token` + `authenticate_or_request_with_http_token`.
  Scope-before-find applies doubly: API controllers bypass HTML before_actions.
- Re-authorize in the API layer; never trust that "the app already checked".
- Rate limit: Rails 7.2+ native `rate_limit to: 100, within: 1.minute`
  in controllers; Rack::Attack (external gem) for global/IP rules.

## Serialization — native first, then gems

1. **`render json:` + model `as_json` overrides** — fine for small surfaces.
2. **Plain PORO serializers** (zero gems, fast, explicit):
   ```ruby
   class OrderSerializer
     def self.one(o) = { id: o.id, status: o.status, total_cents: o.total_cents,
                         created_at: o.created_at.iso8601 }
     def self.many(list, meta: {}) = { data: list.map { one(_1) }, meta: }
   end
   ```
3. External gems when justified (see references/rest-contract.md):
   Jbuilder (ships with Rails, view-style), Alba (fast, modern),
   Blueprinter (declarative). AMS is unmaintained — never for new code.
Rules regardless of tool: expose ONLY needed fields; `iso8601` timestamps;
cents-as-integers for money; ids as strings if JS consumers (53-bit limit).

## Grape projects (work stack)

Structure: `app/api/v1/api.rb` mounts resources; `version "v1", using: :path`;
params blocks ARE the contract (`requires :title, type: String`);
`declared(params)` only — never raw params into models; entities or the same
PORO serializers for output; `rescue_from` for the envelope; helpers for
`authenticate!`/`current_user`. Add `cascade: false` so Grape owns 404s.

## API checklist (per endpoint PR)

```
- [ ] Route is a plural noun; custom action → nested resource
- [ ] Scoped-before-find (no Model.find on raw params)
- [ ] params.require(...).permit(...) / Grape params block (no unfiltered mass-assignment)
- [ ] Correct status codes incl. 404-for-foreign-tenant
- [ ] Error envelope shape (not default Rails error JSON)
- [ ] Collection paginated + meta; per_page capped
- [ ] Filters/sorts whitelisted
- [ ] Request specs: happy path + 401 + 403/404-cross-tenant + 422
- [ ] N+1 checked (includes for serialized associations)
```

## External gems (separate from base conventions)

Evaluate per gem policy: `rack-cors` (needed for browser cross-origin),
`rswag`/`grape-swagger` (OpenAPI docs from specs/DSL), `rack-attack`
(throttling beyond native rate_limit), `jwt` (only if stateless tokens truly
needed — has_secure_token covers most cases), `pagy` (fastest pagination —
near-native weight, generally worth it).
