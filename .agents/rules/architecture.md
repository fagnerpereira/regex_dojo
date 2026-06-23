---
description: Rules for general Rails application architecture and design patterns
globs: app/controllers/**/*.rb, app/models/**/*.rb, app/services/**/*.rb, app/jobs/**/*.rb
---
# Rails Architectural Principles

Enforce clean, scalable Rails application design.

## 1. Fat Models, Skinny Controllers
- Keep controller actions thin and focused strictly on request coordination (authentication, parameter sanitization, format negotiation).
- Encapsulate multi-step business transactions or orchestration logic into Plain Old Ruby Objects (POROs) acting as Service Objects.
- Model logic should handle state mutations and validations, but complex business flows should reside in service objects rather than bloating model files.

## 2. No Global State
- Absolutely avoid class-level variable caches, globals (`$var`), or class-level configuration mutations during runtime.
- If you need request-scoped context, use `CurrentAttributes` or `Thread.current` safely and clear it after each request. NOTE: this app has no `Current` model today — admin auth is HTTP Basic and user auth is session-based; don't assume `Current.user`.

## 3. Rails Stack
- This app runs **Rails 7.1**, not the Rails 8 Solid trifecta:
  - Database-backed asynchronous processing via `Solid Queue` (present).
  - Caching and ActionCable use their standard Rails 7.1 backends — there is no Solid Cache / Solid Cable here.
