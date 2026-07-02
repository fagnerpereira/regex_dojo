module UI
  # <%= render UI::Pill.new(bg: "bg-dojo-success-bg", text: "text-dojo-success-text") { "✓ Done" } %>
  class Pill < Phlex::HTML
    def initialize(bg: "bg-dojo-violet-light", text: "text-dojo-violet-dark", **attrs)
      @bg = bg
      @text = text
      @attrs = attrs
    end

    def view_template(&block)
      span(class: "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11.5px] font-bold #{@bg} #{@text}", **@attrs, &block)
    end
  end
end
