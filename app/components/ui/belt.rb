# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Components
    module Ui
      # Belt chip, e.g. render RegexDojo::Components::Ui::Belt.new(color: "bg-amber-100 text-amber-700") { "🟡 Green belt" }
      class Belt < Phlex::HTML
        def initialize(color: "bg-dojo-violet-light text-dojo-violet-dark")
          @color = color
        end

        def view_template(&block)
          span(class: "inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-bold #{@color}", &block)
        end
      end
    end
  end
end
