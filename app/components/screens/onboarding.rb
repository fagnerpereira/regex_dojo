# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Components
    module Screens
      class Onboarding < Phlex::HTML
        def view_template
          div(class: "flex flex-wrap gap-6") do
            # left card
            render RegexDojo::Components::Ui::Card.new(max_w: "max-w-[560px]") do
              div(class: "flex flex-col items-center justify-center text-center p-14 bg-gradient-to-br from-dojo-violet-light to-white min-h-[560px]") do
                div(class: "font-display text-[64px] w-[110px] h-[110px] rounded-[32px] bg-gradient-to-br from-violet-500 to-dojo-violet-dark text-white flex items-center justify-center shadow-card mb-7") { "道" }
                h3(class: "font-display text-[34px] font-extrabold tracking-tight mb-3") { "Welcome to the Dojo" }
                p(class: "text-[15px] text-dojo-slate leading-relaxed max-w-[380px] mb-8") { "Master regex one kata at a time. Match patterns, defeat challenges, and climb the belts." }
                div(class: "flex gap-2 mb-8") do
                  span(class: "w-[26px] h-1.5 rounded-full bg-dojo-violet")
                  span(class: "w-2 h-1.5 rounded-full bg-dojo-violet-border")
                  span(class: "w-2 h-1.5 rounded-full bg-dojo-violet-border")
                end
                render RegexDojo::Components::Ui::Button.new(class: "w-[280px] py-[15px]", data: {action: "click->tabs#completeOnboarding"}) { "Begin training →" }
              end
            end
            # right card
            render RegexDojo::Components::Ui::Card.new(max_w: "max-w-[560px]") do
              div(class: "p-11 min-h-[560px]") do
                render RegexDojo::Components::Ui::Pill.new(bg: "bg-dojo-violet-light", text: "text-dojo-violet-dark") { "STEP 2 · CHOOSE YOUR LEVEL" }
                h3(class: "font-display text-[26px] font-extrabold mb-1.5 mt-4") { "Where do you stand?" }
                p(class: "text-[13.5px] text-dojo-slate mb-6") { "We'll place you at the right belt. You can retest anytime." }
                div(class: "flex flex-col gap-3.5") do
                  level_option(title: "Brand new", desc: "Never written a regex — start at white belt", color: "bg-white", border: "border-dojo-violet-border", selected: true)
                  level_option(title: "I know the basics", desc: "Anchors, classes, quantifiers — green belt", color: "bg-dojo-success", border: "border-transparent", selected: false)
                  level_option(title: "Regex veteran", desc: "Lookaheads, backrefs — take the black-belt test", color: "bg-dojo-editor-bg", border: "border-transparent", selected: false)
                end
                render RegexDojo::Components::Ui::Button.new(class: "w-full mt-6 py-3.5", data: {action: "click->tabs#completeOnboarding"}) { "Place me →" }
              end
            end
          end
        end

        def level_option(title:, desc:, color:, border:, selected:)
          active_border = selected ? "border-dojo-violet bg-dojo-violet-wash" : "border-dojo-violet-border"
          div(class: "flex items-center gap-4 p-5 rounded-[18px] border-2 #{active_border} cursor-pointer") do
            span(class: "w-11 h-11 rounded-xl #{color} border-2 #{border} shrink-0")
            div(class: "flex-1") do
              div(class: "font-bold text-[15px]") { title }
              div(class: "text-[12.5px] text-dojo-slate") { desc }
            end
            span(class: "text-[20px] #{selected ? "text-dojo-violet" : "text-dojo-violet-border"}") { selected ? "◉" : "○" }
          end
        end
      end
    end
  end
end
