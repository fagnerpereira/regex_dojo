---
name: hanami
description: Core Hanami 3.0 conventions, dry-system dependency injection, action controllers, routing, and environment commands. Use when working on Hanami controllers, actions, configuration, or CLI tasks.
---

# Hanami 3.0 Skill

This skill outlines guidelines and conventions for working with the Hanami 3.0 framework in this project.

## 1. Environment & Common Commands

Always use the standard CLI commands for the project:

- **Test Suite**: Run `mise exec -- bundle exec rspec` or `bundle exec rake`.
- **Linter & Style**: Use `bundle exec standardrb --fix` for linting.
- **Database Migrations**: Run `bundle exec hanami db migrate`.
- **Database Prepare**: Run `bundle exec hanami db prepare`.
- **Routing Info**: Run `bundle exec hanami routes`.
- **Development Server**: Run `bin/dev` or `bundle exec hanami server`.

### Generating Code

Use standard Hanami generators:

- Actions: `bundle exec hanami generate action NAME`
- Operations: `bundle exec hanami generate operation NAME`
- Relations: `bundle exec hanami generate relation NAME`
- Repositories: `bundle exec hanami generate repo NAME`

## 2. Dry-System Dependency Injection (`Deps`)

Hanami uses the `dry-system` container to resolve dependencies automatically.

- Avoid manual instantiations (`DojoRepo.new`) for application dependencies.
- Use the `Deps` mixin to inject dependencies:

  ```ruby
  # app/actions/kata/show.rb
  module Actions
    module Kata
      class Show < App::Action
        include Deps[
          "repos.dojo_repo",
          "operations.verify_solution"
        ]

        def handle(request, response)
          # Use injected dependencies as local methods
          kata = dojo_repo.find_kata(request.params[:id])
          response.render(Views::Kata::Show.new(kata: kata))
        end
      end
    end
  end
  ```

## 3. Action Controllers

- Inherit from `App::Action`.
- Implement `handle(request, response)`.
- Use strong parameters if validated via Dry-Validation in Hanami actions.
- Responses should render Phlex view components. E.g. `response.render(Views::Home::Index.new)`.
