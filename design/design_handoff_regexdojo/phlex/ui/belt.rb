module UI
  # Belt chip, e.g. UI::Belt.new(name: "Green belt", emoji: "🟢", bg: "bg-amber-100", text: "text-amber-700")
  class Belt < Phlex::HTML
    def initialize(name:, emoji:, bg: "bg-dojo-violet-light", text: "text-dojo-violet-dark")
      @name = name
      @emoji = emoji
      @bg = bg
      @text = text
    end

    def view_template
      span(class: "inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-bold #{@bg} #{@text}") do
        plain "#{@emoji} #{@name}"
      end
    end
  end
end
