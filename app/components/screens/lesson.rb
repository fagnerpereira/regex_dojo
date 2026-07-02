# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Components
    module Screens
      class Lesson < Phlex::HTML
        def view_template
          render RegexDojo::Components::Ui::Card.new do
            # Lesson Header
            div(class: "flex items-center justify-between h-[66px] px-6 bg-white border-b border-dojo-violet-border") do
              div(class: "flex items-center gap-4") do
                # Back button returns to the tree path
                button(
                  class: "py-2 px-3.5 bg-dojo-violet-light text-dojo-violet-dark hover:bg-violet-100 rounded-xl font-bold text-xs cursor-pointer border-0",
                  data: {action: "click->tabs#switch", tab: "challenges"}
                ) do
                  "← Back"
                end

                div(class: "flex flex-col") do
                  span(class: "text-[10px] font-bold text-dojo-slate font-mono uppercase tracking-wider", data: {dojo_target: "concept"}) { "Quantifiers & Greed" }
                  div(class: "font-display font-extrabold text-base text-dojo-ink", data: {dojo_target: "title"}) { "Kata 4" }
                end
              end

              div(class: "flex items-center gap-3") do
                span(
                  class: "text-xs font-mono font-bold text-dojo-warning-text bg-dojo-warning-bg border border-dojo-warning/30 px-3 py-1 rounded-xl",
                  data: {dojo_target: "xpBadge"}
                ) { "+120 XP" }
              end
            end

            # Lesson Body (Split layout)
            div(class: "flex flex-col lg:flex-row") do
              # Left Sidebar: Lesson and Instructions (40% width)
              div(class: "w-full lg:w-[420px] p-[30px] border-r border-dojo-violet-border flex flex-col gap-5 bg-white") do
                render RegexDojo::Components::Ui::Pill.new(bg: "bg-orange-50", text: "text-orange-700", class: "self-start") { "⚔️ CHALLENGE" }

                # Description
                div(class: "text-[13.5px] text-dojo-slate leading-relaxed", data: {dojo_target: "lesson"}) do
                  "Master regex matching and capture groups to unlock the next belt."
                end

                # Goal
                div(class: "bg-dojo-violet-wash border border-dojo-violet-border rounded-2xl p-4.5") do
                  div(class: "text-[11px] font-bold text-dojo-slate font-mono uppercase tracking-wider mb-2") { "Objective:" }
                  p(class: "text-sm text-dojo-ink font-semibold leading-relaxed", data: {dojo_target: "task"}) { "" }
                end

                # Hint panel (toggled by the JS controller)
                div(class: "flex flex-col gap-2") do
                  button(
                    type: "button",
                    class: "w-full py-2.5 border border-dojo-violet-border hover:border-dojo-violet hover:bg-dojo-violet-wash rounded-xl text-xs font-mono text-dojo-slate cursor-pointer transition-all",
                    data: {action: "click->dojo#revealHint"}
                  ) do
                    "💡 Need Hint?"
                  end

                  div(
                    class: "hidden text-xs font-mono text-dojo-warning-text bg-dojo-warning-bg border border-dojo-warning/20 p-3 rounded-xl leading-relaxed mt-2",
                    data: {dojo_target: "hintText"}
                  ) do
                    ""
                  end
                end
              end

              # Right Column: Editor and Test Cases (60% width)
              div(class: "flex-1 p-[30px] bg-dojo-violet-wash flex flex-col gap-6") do
                # Match Preview Area
                div(class: "flex flex-col gap-2") do
                  span(class: "text-xs font-bold text-dojo-slate") { "TARGET TEXT (LIVE HIGHLIGHTS)" }
                  div(
                    id: "dojo-highlight-container",
                    class: "bg-white border border-dojo-violet-border font-mono p-4.5 rounded-2xl text-lg min-h-[74px] whitespace-pre-wrap break-all relative text-dojo-ink",
                    data: {dojo_target: "highlightArea"}
                  ) do
                    ""
                  end
                end

                # Pattern Input
                div(class: "flex flex-col gap-2.5") do
                  span(class: "text-xs font-bold text-dojo-slate") { "YOUR PATTERN" }

                  div(class: "bg-dojo-editor-bg rounded-2xl px-5 py-4.5 font-mono text-lg text-dojo-editor-text flex items-center gap-0.5 border border-transparent focus-within:border-dojo-violet transition-all") do
                    span(class: "text-purple-400 select-none") { "/" }
                    input(
                      type: "text",
                      class: "flex-1 bg-transparent border-0 outline-none text-dojo-editor-text font-mono min-w-0 pl-1",
                      placeholder: "type your regex pattern...",
                      autocomplete: "off",
                      spellcheck: "false",
                      data: {
                        dojo_target: "patternInput",
                        action: "input->dojo#evaluatePattern"
                      }
                    )
                    span(class: "text-purple-400 select-none") { "/g" }
                  end

                  # Error Banner
                  div(
                    class: "hidden px-4 py-3 bg-dojo-danger-bg border border-dojo-danger-border rounded-xl text-dojo-danger-text text-xs font-mono font-semibold",
                    data: {dojo_target: "errorBanner"}
                  ) do
                    ""
                  end
                end

                # Test Cases
                div(class: "flex flex-col gap-3") do
                  span(class: "text-xs font-bold text-dojo-slate") { "TEST CASES VERIFICATION" }
                  div(
                    class: "grid grid-cols-1 md:grid-cols-2 gap-3",
                    data: {dojo_target: "testCasesList"}
                  ) do
                    # Populated dynamically by JS controller
                  end
                end

                # Submission Action
                button(
                  type: "button",
                  class: "w-full py-4 bg-dojo-violet hover:bg-dojo-violet-dark text-white rounded-2xl font-display text-base font-extrabold shadow-btn-primary hover:-translate-y-px transition-all cursor-pointer border-0",
                  data: {action: "click->dojo#submit"}
                ) do
                  "⚔️ Submit Pattern"
                end
              end
            end
          end
        end
      end
    end
  end
end
