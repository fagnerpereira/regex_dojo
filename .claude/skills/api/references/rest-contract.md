# REST contract details (request/response shapes)

## Response envelopes

Single resource:
```json
{ "data": { "id": "42", "status": "paid", "total_cents": 1990,
            "created_at": "2026-06-01T12:00:00Z" } }
```
Collection:
```json
{ "data": [ {...}, {...} ],
  "meta": { "page": 2, "pages": 14, "count": 333, "per_page": 25 } }
```
Cursor variant meta: `{ "next_cursor": "eyJpZCI6OTk5fQ", "has_more": true }`

Error (the one shape — repeat from SKILL.md for completeness):
```json
{ "error": { "code": "validation_failed", "message": "Human-readable summary",
             "details": [ { "field": "title", "code": "blank",
                            "message": "can't be blank" } ] } }
```
`code` is machine-stable (clients switch on it); `message` is human, may change.

## rescue_from concern (Rails)

```ruby
module Api::ErrorHandling
  extend ActiveSupport::Concern
  included do
    rescue_from ActiveRecord::RecordNotFound do
      render_error :not_found, "Resource not found", status: :not_found
    end
    rescue_from ActiveRecord::RecordInvalid do |e|
      render_error :validation_failed, e.record.errors.full_messages.to_sentence,
        details: e.record.errors.map { { field: _1.attribute, code: _1.type, message: _1.message } },
        status: :unprocessable_entity
    end
    rescue_from ActionController::ParameterMissing do |e|
      render_error :bad_request, e.message, status: :bad_request
    end
  end

  private
    def render_error(code, message, details: [], status:)
      render json: { error: { code:, message:, details: } }, status:
    end
end
```

## Status code decision table

| Situation | Code |
|---|---|
| Read OK | 200 |
| Created (return body + Location) | 201 |
| Accepted for async processing (return job/status URL) | 202 |
| Deleted / no body | 204 |
| Malformed request (unparseable, missing root param) | 400 |
| No/invalid credentials | 401 |
| Authenticated but forbidden (resource known to exist for them) | 403 |
| Not found AND cross-tenant access (hide existence) | 404 |
| State conflict (duplicate, stale version) | 409 |
| Valid syntax, failed validations | 422 |
| Throttled (+ Retry-After header) | 429 |

## Versioning mechanics

URL path (default):
```ruby
namespace :api do
  namespace :v1 do resources :orders end
  namespace :v2 do resources :orders end   # only on breaking change
end
```
Shared logic: `Api::BaseController` → `Api::V1::BaseController`. Serializers
versioned with controllers (they ARE the contract): `Api::V1::OrderSerializer`.
Deprecation: `Deprecation` + `Sunset` headers on v1 responses, deadline
communicated, then 410 Gone.

Breaking vs additive:
- Additive (new fields, new endpoints, new optional params) → same version
- Breaking (remove/rename field, change type/semantics, tighten validation) → new version

## Pagy integration (if chosen)

```ruby
include Pagy::Backend
pagy, records = pagy(scope, items: [params.fetch(:per_page, 25).to_i, 100].min)
def pagy_meta(p) = { page: p.page, pages: p.pages, count: p.count, per_page: p.vars[:items] }
```

## Cursor pagination (native, no gem)

```ruby
def index
  scope = current_user.orders.order(id: :desc).limit(per_page + 1)
  scope = scope.where("id < ?", decode_cursor(params[:after])) if params[:after]
  records = scope.to_a
  has_more = records.size > per_page
  records = records.first(per_page)
  render json: { data: records.map { OrderSerializer.one(_1) },
                 meta: { next_cursor: (encode_cursor(records.last.id) if has_more),
                         has_more: } }
end
# encode/decode: Base64.urlsafe_encode64(id.to_s) — opaque to clients
```

## Serializer gem comparison (when PORO isn't enough)

| | Jbuilder | Alba | Blueprinter |
|---|---|---|---|
| Style | view templates (.json.jbuilder) | Ruby DSL, blocks | declarative class DSL |
| Speed | slowest | fastest | fast |
| Ships with Rails | yes | no | no |
| Best for | HTML+API apps, complex nesting | performance-sensitive APIs | team-readable contracts |
AMS (active_model_serializers): unmaintained — migrate away, never adopt.

## OpenAPI documentation

Rails: `rswag` — specs ARE the docs (request specs generate swagger.json).
Grape: `grape-swagger` — the params DSL generates docs for free.
Either way: documentation generated from code/specs, never hand-maintained.
