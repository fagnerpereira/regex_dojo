# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Components
    module Ui
      class Button < Phlex::HTML
        VARIANTS = {
          primary: "bg-dojo-violet text-white shadow-btn-primary hover:bg-dojo-violet-dark hover:-translate-y-px px-6 py-3",
          secondary: "bg-dojo-violet-light text-dojo-violet-dark hover:bg-violet-200 px-6 py-3",
          ghost: "bg-dojo-violet-light text-dojo-violet-dark hover:bg-violet-100 px-5 py-3",
          "on-gradient": "bg-white/20 text-white hover:bg-white/30 px-4 py-2.5",
          "on-white": "bg-white text-dojo-violet-dark hover:bg-violet-50 px-6 py-3"
        }.freeze

        def initialize(variant: :primary, full_width: false, **attrs)
          @variant = variant.to_sym
          @full_width = full_width
          @attrs = attrs
        end

        def view_template(&block)
          button(class: classes, **@attrs, &block)
        end

        private

        def classes
          [
            "inline-flex items-center justify-center gap-2 rounded-2xl font-bold text-sm",
            "font-sans transition-all duration-150 cursor-pointer border-0",
            @full_width ? "w-full" : nil,
            VARIANTS.fetch(@variant)
          ].compact.join(" ")
        end
      end
    end
  end
end
