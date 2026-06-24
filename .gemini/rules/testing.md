# Testing Standards

- TDD: red → green → refactor. Write failing test first.
- FactoryBot: `build`/`build_stubbed` > `create` where possible.
- VCR + WebMock for external HTTP calls.
- Phlex components: render in memory and assert HTML outputs.
- Use `let`/`let!`, `described_class`, and `:aggregate_failures` in RSpec.
- Before completing: `mise exec -- bundle exec rspec`, `bundle exec standardrb --fix`.
