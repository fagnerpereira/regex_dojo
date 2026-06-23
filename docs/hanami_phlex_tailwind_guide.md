# Hanami 3.0 + Phlex + Tailwind CSS Integration Guide

This guide provides developer reference documentation for integrating Phlex views and Tailwind CSS into a Hanami 3.0 application.

---

## 1. Phlex Views in Hanami 3.0

Phlex replaces standard templates (like ERB) with object-oriented Ruby classes that generate HTML. This provides performance, clean testing, type safety, and full Ruby control (mixins, loops, conditionals) over the UI.

### Defining a Phlex Component
In Hanami 3.0, custom UI components are stored in `app/views/components/` or inside slice-specific directories. A typical Phlex component inherits from `Phlex::HTML` and defines a `view_template` method.

```ruby
# app/views/components/card.rb
module Views
  module Components
    class Card < Phlex::HTML
      # Initialize with component state / inputs
      def initialize(title:, description:, link_url: nil)
        @title = title
        @description = description
        @link_url = link_url
      end

      # Define the HTML template DSL
      def view_template
        div(class: "p-6 max-w-sm bg-white rounded-xl shadow-md space-y-4 border border-gray-100") do
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

### Rendering Components Inside Actions/Views
To render a component in your main views or actions, simply instantiate it and call it, or render it inside another Phlex class:

```ruby
# Rendering in a parent Phlex view
render Views::Components::Card.new(
  title: "Regex Basics",
  description: "Learn how to use anchors and character classes.",
  link_url: "/lessons/basics"
)
```

---

## 2. Tailwind CSS Flexbox & Grid Cheat Sheet

Tailwind CSS provides low-level utility classes to construct layouts. Here is a cheat sheet for the most common layout controls needed for UI design.

### Flexbox Layouts
Flexbox is ideal for single-axis alignments (menus, rows of items, centered blocks).

| Class | CSS Equivalent | Description |
| :--- | :--- | :--- |
| `flex` | `display: flex;` | Starts a flexbox container |
| `flex-row` | `flex-direction: row;` | Lays out items horizontally (default) |
| `flex-col` | `flex-direction: column;` | Lays out items vertically |
| `flex-wrap` | `flex-wrap: wrap;` | Wraps items onto multiple lines |
| `justify-start` | `justify-content: flex-start;` | Aligns items to the start |
| `justify-center` | `justify-content: center;` | Centers items along the main axis |
| `justify-between`| `justify-content: space-between;` | Spends leftover space evenly between items |
| `items-center` | `align-items: center;` | Centers items along the cross axis |
| `gap-4` | `gap: 1rem;` | Adds 1rem spacing between sibling items |
| `flex-1` | `flex: 1 1 0%;` | Allows an item to grow and shrink to fill space |
| `flex-shrink-0`| `flex-shrink: 0;` | Prevents an item from shrinking |

#### Example: Responsive Navigation Bar (Phlex + Tailwind CSS)
```ruby
nav(class: "flex flex-col md:flex-row items-center justify-between p-4 bg-gray-900 text-white gap-4") do
  div(class: "flex items-center gap-2") do
    span(class: "text-lg font-bold tracking-wider text-indigo-400") { "RegexDojo" }
  end
  div(class: "flex items-center gap-6") do
    a(href: "/lessons", class: "hover:text-indigo-300 transition") { "Lessons" }
    a(href: "/cheatsheet", class: "hover:text-indigo-300 transition") { "Cheatsheet" }
    a(href: "/playground", class: "hover:text-indigo-300 transition") { "Playground" }
  end
end
```

### Grid Layouts
Grid is best for two-dimensional layouts (cards, dashboards, sidebars).

| Class | Description |
| :--- | :--- |
| `grid` | Starts a grid container |
| `grid-cols-1` | 1-column layout |
| `md:grid-cols-2` | 2-column layout on medium screens and up |
| `lg:grid-cols-3` | 3-column layout on large screens and up |
| `gap-6` | Spacing of 1.5rem between grid cells |
| `col-span-2` | Makes an element span 2 columns |

#### Example: Responsive Card Grid
```ruby
div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6") do
  render Views::Components::Card.new(title: "Level 1", description: "Literal matching")
  render Views::Components::Card.new(title: "Level 2", description: "Character classes")
  render Views::Components::Card.new(title: "Level 3", description: "Quantifiers")
end
```

---

## 3. Best Practices for Premium UI in Phlex

1. **Leverage Hover/Active/Focus States**: Always add `transition duration-200` to buttons and links combined with `hover:bg-...` or `hover:text-...`.
2. **Implement Consistent Spacing**: Use standard gap parameters (`gap-4`, `gap-6`) and margins/padding (`p-4`, `p-6`, `space-y-4`) to ensure rhythm.
3. **Avoid Hardcoded Color Schemes**: Use curated palettes (like `indigo`, `slate`, `zinc`) instead of basic `blue` or `red`.
