---
description: Core Hanami 3.0 environment commands, architectural conventions, and validation workflows
globs: **/*
---
# Hanami 3.0 Environment & Conventions

This guide defines core commands, coding style, and workflows for working with the Hanami stack in this repository.

## 1. Environment & Commands
- **Test Suite**: Run `mise exec -- bundle exec rspec` or `bundle exec rake`.
- **Linter & Style**: Use `bundle exec standardrb --fix` for linting and auto-correction.
- **Database Migrations**: Run `bundle exec hanami db migrate`.
- **Database Prepare**: Run `bundle exec hanami db prepare`.
- **Routing Info**: Run `bundle exec hanami routes`.
- **Development Server**: Run `bin/dev` or `bundle exec hanami server`.
- **Code Generators**:
  - Actions: `bundle exec hanami generate action NAME`
  - Operations: `bundle exec hanami generate operation NAME`
  - Relations: `bundle exec hanami generate relation NAME`
  - Repositories: `bundle exec hanami generate repo NAME`

## 2. Core Architectural Principles
- **Dry-System Dependency Injection**: Actions, repos, and operations use dry-system for dependency injection via the `Deps` mixin (e.g. `include Deps["repos.dojo_repo"]`).
- **No Global State**: Absolutely avoid class-level variable caches, globals (`$var`), or class-level configuration mutations during runtime.
- **Views & HTML**: Built exclusively using Phlex. Controllers instantiate views and pass variables in the constructor, rendering them into responses.

## 3. Workflows & Verification
- Before declaring any task "done", verify that:
  1. The linter runs cleanly.
  2. The target specs pass successfully.
  3. Memory footprint and SQL queries have been audited.
