---
name: security
description: >
  Security audit and hardening for Rails apps — SQL injection, XSS, CSRF,
  mass assignment, credential management, dependency scanning, and Brakeman
  findings. Use when reviewing code for security issues, adding auth features,
  handling user input, or responding to Brakeman warnings.
---

# Security best practices (Rails 7.1)

## Brakeman integration

Run `bundle exec brakeman -q` before any security-sensitive change.
Common findings and fixes:

| Warning            | Fix                                                                                           |
| ------------------ | --------------------------------------------------------------------------------------------- |
| SQL injection      | Use ActiveRecord query methods, never raw `sanitize_sql` or string interpolation in `where()` |
| XSS in view        | Phlex auto-escapes HTML. In legacy ERB, use `sanitize` or `strip_tags`                        |
| Mass assignment    | Use `params.require(...).permit(...)` — strong parameters are already enforced                |
| Redirect           | Use `redirect_to <named_path>` not `redirect_to params[:url]`                                 |
| Skip_before_action | Avoid; use `only:` / `except:` explicitly                                                     |
| Unsafe reflection  | Avoid `constantize` / `classify` on user input                                                |

## SQL injection prevention

- Always use ActiveRecord query methods: `User.where(email: params[:email])`
- Never interpolate user input into SQL strings: `where("email = '#{params[:email]}'")` — BAD
- For dynamic conditions: `User.where("email ILIKE ?", "%#{sanitized}%")`
- For IN clauses: `User.where(id: params[:ids])` — AR handles escaping
- Avoid `sanitize_sql` / `sanitize_sql_array` unless absolutely necessary

## Cross-Site Scripting (XSS)

- Phlex auto-escapes all string output — confirm no `.html_safe` or `raw()` calls
- User-generated content rendered in views must go through `sanitize()`
- Rich text: use ActionText or sanitize with a whitelist of allowed tags
- JSON endpoints: never render unsanitized user input in error messages
- Content-Security-Policy: configure in `config/initializers/content_security_policy.rb`

## Cross-Site Request Forgery (CSRF)

- Rails enables CSRF protection by default (`verify_authenticity_token`)
- Webhook endpoints intentionally skip it (`skip_before_action :verify_authenticity_token, only: :create` in `webhooks_controller` / `stripe/webhooks_controller`) — verify those instead authenticate the caller (signature/secret)
- Turbo + Hotwire handle CSRF tokens in forms automatically
- Custom AJAX: include `X-CSRF-Token` header from `<meta name="csrf-token">`

## Mass assignment

- Already enforced by strong parameters in Rails
- Use `params.require(...).permit(...)` in controllers (Rails 7.1 — `params.expect` is 8.0+)
- Be careful with `accepts_nested_attributes_for` — permit only the needed nested params
- Never use `attr_accessible` (Rails 3 legacy)

## Credential management

- API keys in `.env` file (gitignored) and accessed via `ENV["VARIABLE_NAME"]`
- Rails credentials for production: `bin/rails credentials:edit --environment production`
- Never commit `.env` or `credentials/*.key` files
- Brakeman flags `ENV["SECRET"]` — these are expected for env-based config
- Confirm `.env.example` doesn't contain real values

## Dependency scanning

- Ruby: `bundle audit check` (`bundler-audit` gem)
- JS: `yarn audit` (or `npm audit`)
- Also: `bundle outdated --strict` for stale deps

## Input validation

- Validate all user input at the model layer using ActiveRecord validations
- Use `format:` with regex for structured fields (email, URL, phone)
- Sanitize file uploads: validate content type, size, and filename
- Use `num` / `:integer` for numeric params in controllers
