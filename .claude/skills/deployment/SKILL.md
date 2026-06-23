---
name: deployment
description: >
  Build, run, and reason about the Anonymous Pix production image (Docker) and
  the local dev process model. Use when building the image, debugging the
  container, configuring environment variables, or diagnosing production issues.
  NOTE: this app does not use Kamal — there is no `config/deploy.yml`.
---

# Deployment (Docker image — no Kamal configured)

Anonymous Pix ships a production `Dockerfile`; there is **no Kamal / `config/deploy.yml`**.
Confirm the actual hosting target (PaaS, container host, CI pipeline) with the
developer before assuming a deploy mechanism — do not invent one.

## Local process model (`Procfile.dev`, run via `bin/dev`)

```
web: RUBY_DEBUG_OPEN=true bin/rails server
js:  yarn build --watch        # esbuild → app/assets/builds
css: bin/rails tailwindcss:watch
```

## Production image

- `Dockerfile` — production image. Build: `docker build -t anonymous-pix .`
- Assets are precompiled in the image (`assets:precompile`); JS via esbuild, CSS via tailwindcss-rails.
- Background jobs run through **Solid Queue** (gem `solid_queue`) — run its worker as a separate process/container (`bin/jobs` or the configured runner).
- Database is **PostgreSQL** — provide `DATABASE_URL` (or the discrete PG env vars).

## Environment / secrets

- App secrets come from ENV (`dotenv-rails` loads `.env` in dev). Never commit `.env`.
- Known env vars include `ADMIN_USER` / `ADMIN_PASSWORD` (HTTP Basic admin auth) and the OpenPix / Stripe / OpenAI / reCAPTCHA credentials used by `app/services/`.
- Logging ships to Logtail in production (`logtail-rails`).

## Pre-deploy checks

1. `bundle exec rspec`
2. `bundle exec standardrb`
3. `bundle exec brakeman -q`

## Health check

- Rails health endpoint: `get "up" => "rails/health#show"` (expects `200 OK`).
