---
description: Testing standards and quality guidelines for AI agents writing RSpec tests
globs: spec/**/*_spec.rb
---
# Testing Standards & Guidelines

## Useless & Low-Value Tests (DO NOT WRITE THEM)

- **DO NOT** write Shoulda Matchers for standard ActiveRecord columns, validations, or associations (e.g., `belongs_to(:user)` or `validate_presence_of(:name)`) unless there is a custom or conditional validator.
- **DO NOT** write unit tests for private methods directly. Test behavior through the public interface. Extract complex private methods to a separate, testable object.
- **DO NOT** write redundant integration tests testing the exact same branch behavior.
- **DO NOT** use paper-thin mock specs that stub out all database calls and integrations.

## RSpec Best Practices

- Use `described_class` instead of hardcoded class names.
- Use explicit named subjects: `subject(:order) { build(:order) }`.
- Use `let` / `let!` for setup — never `@instance_variables` inside specs.
- Use `:aggregate_failures` for blocks with multiple assertions.
- Wrap external API requests with VCR cassettes: `vcr: { cassette_name: '...' }`.
- Prefer `build` / `build_stubbed` over `create` where possible.
- Prefer request specs and system specs over controller specs.

## Phlex Component Testing

- **NEVER** use Capybara or headless browsers for individual Phlex component tests.
- Use the `PhlexComponentHelper` with `type: :view` (in `spec/support/phlex_component_helper.rb`).
- Render in-memory: `render described_class.new(...)` and use string assertions or Nokogiri.

## High-Priority Testing Targets

- Payment/charge flows (`Order`, OpenPix/Woovi service objects in `app/services/openpix/`)
- Money math (fees/credits — `price_fees_calculator`, `credit_package_calculator`)
- Webhook handling (`webhooks_controller`, `stripe/webhooks_controller`)
- Admin access control (HTTP Basic auth on `Admin::` controllers)
- Secret-link access scoping

## Verification Commands

```bash
bundle exec rspec                    # full suite
bundle exec standardrb --fix         # lint
yarn format                          # prettier/herb formatters (optional)
```

## Branch & Edge-Case Coverage

- For conditional logic (`||`, `&&`, `if/else`, `case`), cover EACH branch with a test.
- For ActiveRecord callbacks (`before_validation`, `before_save`, commit callbacks), write a unit spec that exercises the callback behavior specifically. Note: this project runs `use_transactional_fixtures = true`, so `after_commit` callbacks DO NOT fire by default in specs — disable transactional fixtures for that example or use a helper to run commit callbacks.
- For helper/PORO methods, add focused unit specs — do not rely on integration coverage alone.
- Cover the edge cases that actually break: nil/empty values, boundary conditions, `||` fallback paths, and error states.

## Spec File Hygiene

- DO NOT create a new spec file in a subdirectory when one already exists at the canonical path (modify `spec/requests/learning/writings_spec.rb`, DO NOT create `spec/requests/learning/writings/writings_spec.rb`).
- DO NOT delete existing shared examples when adding coverage — extend them or add new examples alongside.

## Documentation Sync

When making structural changes, features, or refactors:
- Update relevant docs in `docs/`, `README.md`, `TODO.md`.
- Keep `.agents/rules/` in sync with actual project conventions.
