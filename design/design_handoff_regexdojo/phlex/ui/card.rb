module UI
  # Base app "card" shell — the white rounded panel used for every screen.
  class Card < Phlex::HTML
    def initialize(max_w: nil, **attrs)
      @max_w = max_w
      @attrs = attrs
    end

    def view_template(&block)
      div(class: classes, **@attrs, &block)
    end

    private

    def classes
      [
        "bg-white rounded-card border border-dojo-violet-border shadow-card overflow-hidden",
        @max_w ? "w-full #{@max_w} min-w-[320px] flex-1" : "w-full"
      ].join(" ")
    end
  end
end
