# frozen_string_literal: true

require "phlex"
require "json"
require_relative "../../../lib/regex_dojo/kata_pool"

module RegexDojo
  module Views
    module Components
      class DojoPanel < Phlex::HTML
        def initialize(user:, solved_kata_ids: [], katas: [])
          @user = user
          @solved_kata_ids = solved_kata_ids
          @katas = katas
        end

        def view_template
          div(class: "grid grid-cols-1 lg:grid-cols-12 gap-8", data: {controller: "dojo"}) do
            # Left: Challenge Navigation List (4 cols)
            div(class: "lg:col-span-4 flex flex-col gap-4 bg-dojo-surface border border-dojo-border p-4 rounded-xl max-h-[600px] overflow-y-auto") do
              belts = [
                {name: "White Belt", icon: "🥋", color_class: "text-white border-white/20 bg-white/5 shadow-white/5", index_range: 0..2},
                {name: "Yellow Belt", icon: "🌟", color_class: "text-dojo-gold border-dojo-gold/20 bg-dojo-gold/5 shadow-dojo-gold/5", index_range: 3..5},
                {name: "Orange Belt", icon: "🔥", color_class: "text-orange-400 border-orange-400/20 bg-orange-400/5 shadow-orange-400/5", index_range: 6..8},
                {name: "Green Belt", icon: "🍃", color_class: "text-dojo-green border-dojo-green/20 bg-dojo-green/5 shadow-dojo-green/5", index_range: 9..11},
                {name: "Black Belt", icon: "💀", color_class: "text-purple-400 border-purple-400/20 bg-purple-400/5 shadow-purple-400/5", index_range: 12..14}
              ]

              belts.each do |belt|
                belt_katas = @katas.each_with_index.select { |_, idx| belt[:index_range].include?(idx) }
                next if belt_katas.empty?

                div(class: "flex flex-col gap-2") do
                  div(class: "flex items-center gap-2 px-3 py-1.5 rounded-lg border shadow-sm #{belt[:color_class]} mb-1") do
                    span(class: "text-sm") { belt[:icon] }
                    span(class: "text-xs font-mono font-semibold uppercase tracking-wider") { belt[:name] }
                  end

                  belt_katas.each do |kata, index|
                    solved = @solved_kata_ids.include?(kata[:id])

                    button(
                      class: "w-full text-left p-3 rounded-lg border border-transparent transition-all duration-150 flex items-center justify-between hover:bg-dojo-bg hover:border-dojo-border",
                      data: {
                        action: "click->dojo#selectKata",
                        dojo_target: "kataButton",
                        kata_id: kata[:id],
                        kata_title: kata[:title],
                        kata_concept: kata[:concept],
                        kata_lesson: kata[:lesson],
                        kata_test_string: kata[:test_string],
                        kata_task: kata[:task],
                        kata_hint: kata[:hint],
                        kata_xp: kata[:xp],
                        kata_solved: solved.to_s,
                        # JSON test cases for client side check
                        kata_test_cases: kata[:test_cases].to_json
                      }
                    ) do
                      div(class: "flex flex-col") do
                        span(class: "text-xs text-dojo-cyan font-mono") { "Challenge #{index + 1}" }
                        span(class: "text-sm font-semibold text-white") { kata[:title] }
                      end
                      div(class: "flex items-center gap-2") do
                        if solved
                          span(class: "kata-solved-badge") { "✅" }
                        end
                        span(class: "text-xs font-mono text-dojo-gold") { "+#{kata[:xp]} XP" }
                      end
                    end
                  end
                end
              end
            end

            # Right: Interactive Arena (8 cols)
            div(class: "lg:col-span-8 flex flex-col gap-6") do
              # Active Challenge Card
              div(class: "kata-card flex flex-col gap-6 relative overflow-hidden", data: {dojo_target: "kataCard"}) do
                # Decorative belt accent line
                div(class: "absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-dojo-purple to-dojo-cyan")

                # Active Kata Header
                div(class: "flex items-center justify-between mt-1") do
                  div do
                    span(class: "text-xs font-mono font-semibold uppercase tracking-wider text-dojo-cyan", data: {dojo_target: "concept"}) { "" }
                    h2(class: "text-xl font-bold text-white mt-1", data: {dojo_target: "title"}) { "Select a kata to begin →" }
                  end
                  span(class: "text-sm font-mono text-dojo-gold bg-dojo-gold/10 border border-dojo-gold/30 px-3 py-1 rounded", data: {dojo_target: "xpBadge"}) { "" }
                end

                # Lesson Block
                div(class: "bg-dojo-bg/60 border border-dojo-border/60 rounded-lg p-4 text-sm leading-relaxed text-gray-300", data: {dojo_target: "lesson"}) do
                  ""
                end

                # Goal Box
                div(class: "flex flex-col gap-2 bg-dojo-cyan/5 border border-dojo-cyan/20 p-4 rounded-lg") do
                  span(class: "text-xs font-mono text-dojo-cyan font-bold uppercase") { "⚔️ Objective:" }
                  p(class: "text-sm text-gray-200 font-medium", data: {dojo_target: "task"}) { "" }
                end

                # Test String Area
                div(class: "flex flex-col gap-2") do
                  span(class: "text-xs font-mono text-gray-400 uppercase") { "Target Text (Live Highlights):" }
                  # Visual container displaying text with highlights
                  div(
                    id: "dojo-highlight-container",
                    class: "bg-dojo-bg border border-dojo-border font-mono p-4 rounded-lg text-lg min-h-[60px] whitespace-pre-wrap break-all relative",
                    data: {dojo_target: "highlightArea"}
                  ) do
                    ""
                  end
                end

                # Pattern Input Form
                div(class: "flex flex-col gap-3", data: {dojo_target: "formContainer"}) do
                  div(class: "relative flex items-center") do
                    span(class: "absolute left-4 font-mono text-dojo-cyan select-none") { "/" }
                    input(
                      type: "text",
                      class: "regex-input pl-8 pr-12 text-lg font-mono",
                      placeholder: "type your regex pattern...",
                      autocomplete: "off",
                      spellcheck: "false",
                      data: {
                        dojo_target: "patternInput",
                        action: "input->dojo#evaluatePattern"
                      }
                    )
                    span(class: "absolute right-4 font-mono text-dojo-cyan select-none") { "/g" }
                  end

                  # Validation Error Banner
                  div(class: "hidden bg-dojo-red/10 border border-dojo-red/30 text-dojo-red text-xs font-mono p-3 rounded-lg", data: {dojo_target: "errorBanner"}) do
                    ""
                  end

                  # Success Banner (hidden by default)
                  div(class: "hidden", data: {dojo_target: "successBanner"}) do
                    ""
                  end
                end

                # Test Cases List
                div(class: "flex flex-col gap-3") do
                  span(class: "text-xs font-mono text-gray-400 uppercase") { "Test Cases Verification:" }
                  div(class: "grid grid-cols-1 md:grid-cols-2 gap-3", data: {dojo_target: "testCasesList"}) do
                    # Generated dynamically by JS controller
                  end
                end

                # Hint and Submission Actions
                div(class: "flex items-center gap-4 mt-2") do
                  # Hint reveal button
                  button(
                    type: "button",
                    class: "px-4 py-2 border border-dojo-border hover:bg-dojo-surface hover:border-gray-500 rounded text-xs font-mono text-gray-400 transition-all",
                    data: {action: "click->dojo#revealHint"}
                  ) do
                    "💡 Need Hint"
                  end

                  # The Hint text box (hidden by default)
                  div(class: "hidden text-xs font-mono text-dojo-gold bg-dojo-gold/5 border border-dojo-gold/20 p-2 rounded flex-1", data: {dojo_target: "hintText"}) do
                    ""
                  end

                  # Submit Button
                  button(
                    type: "button",
                    class: "btn-dojo px-6 py-2.5 rounded-lg flex-1 text-center font-bold text-sm select-none shadow-md cursor-pointer",
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
end
