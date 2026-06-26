---
name: phlex
description: Phlex component development, HTML DSL, component composition, rendering conventions, Tailwind flexbox/grid layout systems, and premium UI aesthetics. Use when creating or editing Phlex views, components, layouts, or stylesheets.
---

# Phlex View Components Skill

This skill provides guidelines for building views and components using Phlex and Tailwind CSS inside this project.

## 1. Defining a Phlex Component

Phlex replaces traditional templates with Ruby classes that generate HTML.

- Component files reside in `app/views/components/` or inside slice-specific directories.
- Components inherit from `Phlex::HTML` and define a `view_template` method.
- Pass state/inputs through the constructor.

### Example Component:

```ruby
# app/views/components/card.rb
module Views
  module Components
    class Card < Phlex::HTML
      def initialize(title:, description:, link_url: nil)
        @title = title
        @description = description
        @link_url = link_url
      end

      def view_template
        div(class: "p-6 bg-white rounded-xl shadow-md border border-gray-100 space-y-4") do
          h2(class: "text-xl font-medium text-black") { @title }
          p(class: "text-gray-500") { @description }

          if @link_url
            a(
              href: @link_url,
              class: "inline-block px-4 py-2 text-sm font-semibold text-white bg-indigo-500 rounded-lg hover:bg-indigo-600 transition"
            ) do
              "Learn More"
            end
          end
        end
      end
    end
  end
end
```

## 2. Composition and Rendering

Render a child component inside another component or template by instantiating it with `render`:

```ruby
render Views::Components::Card.new(
  title: "Level 1",
  description: "Literal matching",
  link_url: "/kata/1"
)
```

## 3. Tailwind CSS Layout Cheat Sheet

### Flexbox Layouts (Single-axis menus, rows, centered content)

- `flex` - Starts flexbox container.
- `flex-row` / `flex-col` - Layout items horizontally / vertically.
- `items-center` - Align items along the cross axis.
- `justify-between` / `justify-center` - Spends leftover space evenly / centers items.
- `gap-4` / `gap-6` - Spacing between sibling items.

### Grid Layouts (Multi-column dashboards, cards)

- `grid` - Starts grid container.
- `grid-cols-1 md:grid-cols-2 lg:grid-cols-3` - Spans 1, 2, or 3 columns depending on screen size.
- `gap-6` - Spacing of 1.5rem between grid cells.
- `col-span-2` - Make an element span multiple columns.

## 4. Design & Premium UI Aesthetics

- **Smooth transitions**: Use `transition duration-200` with interactive hover effects (`hover:bg-...`).
- **Aesthetic Colors**: Avoid generic primary colors (e.g. standard red/blue). Prefer Slate, Zinc, Neutral, Indigo, Violet, Emerald, Amber, etc.
- **Rhythm**: Use consistent layout spacing (`p-6`, `gap-6`, `space-y-4`).
