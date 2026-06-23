---
name: frontend
description: >
  Build and maintain Phlex views, Stimulus controllers, Hotwire/Turbo
  interactions, and Tailwind 3 CSS for Anonymous Pix. Use when creating or
  modifying view components, adding interactivity, styling UI, or debugging
  frontend behavior. Also use proactively when about to add a new view or
  Stimulus controller.
---

# Frontend conventions (Phlex + Stimulus + Hotwire + Tailwind 3)

## Phlex views

- Pages live in `app/views/` as `Views::*` classes (e.g. `app/views/dashboard/index_view.rb` → `Views::Dashboard::Index`)
- Reusable UI lives in `app/views/components/` as `Ui::*` classes extending `ApplicationComponent` (`app/views/components/application_component.rb`)
- Always define `view_template` — never the deprecated `template` method
- Controllers render via `render Views::X.new(...)` — pass data through constructors, never set ivars for views
- Use the `Phlex::Rails::Helpers::*` adapters (already mixed into `ApplicationComponent`: `Routes`, `LinkTo`); never `include` raw `ActionView::Helpers::*` modules (they clobber Phlex internals like `capture`)
- Icons via `lucide_icon(name, **opts)` (lucide-rails)
- **Migration in progress:** legacy ViewComponents (`app/components/*_component.rb` + matching `.html.erb`) are being moved to Phlex. Write all new views as Phlex; don't add new ERB or extend the legacy components.
- Generators: `bin/rails generate phlex:component Ui::MyComponent`, `bin/rails generate phlex:view ControllerName::ActionName`

### Example Phlex component (matches `app/views/components/ui/button.rb`)
```ruby
# frozen_string_literal: true

class Ui::Badge < ApplicationComponent
  def initialize(variant: :default, **attrs)
    @variant = variant
    @attrs = attrs
  end

  def view_template(&block)
    span(class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{variant_classes}", **@attrs, &block)
  end

  private

  def variant_classes
    case @variant.to_sym
    when :success then "bg-green-100 text-green-800"
    when :warning then "bg-yellow-100 text-yellow-800"
    else "bg-gray-100 text-gray-800"
    end
  end
end
```

## Stimulus controllers

- One controller per file, kebab-case filename: `app/javascript/controllers/<name>_controller.js`
- Declare `static targets` and `static values` explicitly
- Wire with `data-controller` and `data-action` attributes
- Use `@rails/request.js` for AJAX (not raw `fetch`)

### Example controller
```javascript
import { Controller } from "@hotwired/stimulus"
import { get, post } from "@rails/request.js"

export default class extends Controller {
  static targets = ["output"]
  static values = { url: String }

  connect() {
    this.load()
  }

  async load() {
    const response = await get(this.urlValue, { responseKind: "turbo-stream" })
    if (response.ok) {
      // Turbo Streams auto-render
    }
  }
}
```

## Build pipeline

- JS is bundled with **esbuild** (`yarn build --watch`, output to `app/assets/builds`) — see `package.json` `build` script; importmap-rails is also present
- CSS is compiled by **tailwindcss-rails** (`bin/rails tailwindcss:watch`)
- `bin/dev` runs web + js + css together (`Procfile.dev`)

## Hotwire / Turbo

- Use Turbo Drive for page navigation (turbo-rails 8)
- Turbo Streams for live updates (`<turbo-stream>`)
- Turbo Frames for scoped page sections
- Broadcast model changes via `after_create_commit`, `after_update_commit`, `after_destroy_commit`
- Use `turbo_frame_tag` for frame wrapping, `turbo_stream_from` for subscriptions

## Tailwind 3

- **Tailwind 3** (tailwindcss-rails) — no DaisyUI, no inline CSS
- Configured in `config/tailwind.config.js`; entry CSS at `app/assets/stylesheets/application.tailwind.css`
- Utility classes only: compose styles in HTML/Phlex, not in CSS files
- Custom values use arbitrary syntax: `w-[32rem]`, `top-[calc(100%+0.5rem)]`
- Dark mode uses the `dark:` variant
- Responsive design uses `sm:`, `md:`, `lg:`, `xl:` breakpoints
- Animations use built-in Tailwind classes (`animate-spin`, `animate-pulse`, `transition-all`)

## Accessibility

- Semantic HTML: `nav`, `main`, `section`, `article`, `aside`
- Labels on all form inputs
- `aria-label` and `aria-describedby` for icon-only buttons
- Focus indicators visible (never `outline: none` without replacement)
- Color contrast meets WCAG AA (4.5:1 normal text)
- Form errors use `aria-invalid` and `aria-describedby` linking to error messages
