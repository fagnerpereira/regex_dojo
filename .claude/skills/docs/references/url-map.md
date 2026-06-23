# Web fallback URLs — ONLY when the gem is not installed locally

Prefer raw GitHub READMEs (clean Markdown, no HTML stripping) pinned to the
project's version tag. `{V}` = exact version from Gemfile.lock.

## Hotwire
- Turbo handbook: `https://turbo.hotwired.dev/handbook/introduction` (also `/frames`, `/streams`, `/drive`)
- Turbo reference: `https://turbo.hotwired.dev/reference/streams` (also `/frames`, `/attributes`, `/events`)
- turbo-rails README: `https://raw.githubusercontent.com/hotwired/turbo-rails/v{V}/README.md`
- Stimulus handbook: `https://stimulus.hotwired.dev/handbook/introduction`
- Stimulus reference: `https://stimulus.hotwired.dev/reference/controllers` (also `/actions`, `/targets`, `/values`, `/outlets`, `/css-classes`)

## Components
- Phlex: `https://www.phlex.fun/` | `https://raw.githubusercontent.com/phlex-ruby/phlex/v{V}/README.md`
- ViewComponent: `https://viewcomponent.org/guide/getting-started.html` (also `/guide/slots.html`, `/guide/testing.html`)

## Auth / Authorization
- Action Policy: `https://actionpolicy.evilmartians.io/` | `https://raw.githubusercontent.com/palkan/action_policy/v{V}/README.md`
- bcrypt: `https://raw.githubusercontent.com/bcrypt-ruby/bcrypt-ruby/v{V}/README.md`

## Testing
- rspec-rails: `https://raw.githubusercontent.com/rspec/rspec-rails/v{V}/README.md`
- factory_bot: `https://raw.githubusercontent.com/thoughtbot/factory_bot/main/GETTING_STARTED.md`
- capybara: `https://raw.githubusercontent.com/teamcapybara/capybara/v{V}/README.md`
- shoulda-matchers: `https://matchers.shoulda.io/docs/v{MAJOR}/`

## API / Serializers
- grape: `https://raw.githubusercontent.com/ruby-grape/grape/v{V}/README.md`
- alba: `https://raw.githubusercontent.com/okuramasafumi/alba/v{V}/README.md`
- blueprinter: `https://raw.githubusercontent.com/procore-oss/blueprinter/v{V}/README.md`
- jbuilder: `https://raw.githubusercontent.com/rails/jbuilder/v{V}/README.md`

## Jobs / Cache / Cable
- solid_queue: `https://raw.githubusercontent.com/rails/solid_queue/v{V}/README.md`
- solid_cache: `https://raw.githubusercontent.com/rails/solid_cache/v{V}/README.md`
- solid_cable: `https://raw.githubusercontent.com/rails/solid_cable/v{V}/README.md`
- sidekiq: `https://raw.githubusercontent.com/sidekiq/sidekiq/v{V}/README.md` (wiki: github.com/sidekiq/sidekiq/wiki)

## Misc
- pagy: `https://ddnexus.github.io/pagy/`
- simple_form: `https://raw.githubusercontent.com/heartcombo/simple_form/v{V}/README.md`
- store_attribute: `https://raw.githubusercontent.com/palkan/store_attribute/v{V}/README.md`
- bullet: `https://raw.githubusercontent.com/flyerhzm/bullet/master/README.md`
- dry-validation: `https://dry-rb.org/gems/dry-validation/{MAJOR}.{MINOR}/`

## Rails (when tmp/rails_docs missing)
- Guides: `https://guides.rubyonrails.org/<guide_name>.html`
- API: `https://api.rubyonrails.org/v{V}/`

## Universal catch-all (any gem)
- `https://rubydoc.info/gems/{gem}/{V}`
- `https://rubygems.org/gems/{gem}/versions/{V}` (links + summary)

## Fetch + narrow pattern
```bash
curl -fsL --max-time 10 "URL" | sed 's/<[^>]*>//g' | tr -s ' \n' | grep -A 40 -i "KEYWORD" | head -60
```
