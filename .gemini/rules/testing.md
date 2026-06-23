# Testing Standards

- TDD: red → green → refactor
- FactoryBot: `build`/`build_stubbed` > `create`
- VCR + WebMock for external HTTP
- Phlex components: `type: :view` + `PhlexComponentHelper`, in-memory rendering
- No Capybara for component specs
- No Shoulda Matchers for trivial validations
- Use `let`/`let!`, `described_class`, `:aggregate_failures`
- Before completing: `bundle exec rspec`, `standardrb --fix`, `bun run format`
