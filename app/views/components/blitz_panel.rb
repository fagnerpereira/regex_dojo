# frozen_string_literal: true

require "phlex"
require "json"

module RegexDojo
  module Views
    module Components
      class BlitzPanel < Phlex::HTML
        def initialize(katas:)
          @katas = katas
        end

        def view_template
          div(class: "flex flex-col gap-6", data: {controller: "blitz"}) do
            # Blitz Katas Data (hidden JSON for JS)
            script(type: "application/json", id: "blitz-katas-data") do
              raw safe(@katas.map { |k|
                {
                  id: k[:id],
                  title: k[:title],
                  concept: k[:concept],
                  test_string: k[:test_string],
                  task: k[:task],
                  hint: k[:hint],
                  xp: k[:xp],
                  test_cases: k[:test_cases]
                }
              }.to_json)
            end

            # Start Screen
            div(data: {blitz_target: "startScreen"}) do
              div(class: "kata-card text-center py-12 flex flex-col items-center gap-6") do
                div(class: "text-6xl animate-float") { "⚡" }
                h2(class: "text-3xl font-bold text-white") { "Blitz Mode" }
                p(class: "text-gray-400 max-w-md") { "Race against the clock! Solve as many regex challenges as you can in 30 seconds. The faster you solve, the higher your score multiplier." }

                div(class: "flex items-center gap-8 mt-4") do
                  div(class: "text-center") do
                    span(class: "block text-2xl font-mono font-bold text-dojo-cyan") { "30s" }
                    span(class: "text-xs text-gray-500 font-mono uppercase") { "Time Limit" }
                  end
                  div(class: "text-center") do
                    span(class: "block text-2xl font-mono font-bold text-dojo-gold") { "2x" }
                    span(class: "text-xs text-gray-500 font-mono uppercase") { "Max Multiplier" }
                  end
                  div(class: "text-center") do
                    span(class: "block text-2xl font-mono font-bold text-dojo-purple") { "∞" }
                    span(class: "text-xs text-gray-500 font-mono uppercase") { "Challenges" }
                  end
                end

                button(
                  class: "btn-dojo px-10 py-3 rounded-lg text-lg font-bold mt-4",
                  data: {action: "click->blitz#start", blitz_target: "startButton"}
                ) { "⚡ Start Blitz" }
              end
            end

            # Game Screen (hidden initially)
            div(class: "panel-hidden", data: {blitz_target: "gamePanel"}) do
              # Timer Bar
              div(class: "flex items-center justify-between mb-4") do
                div(class: "flex items-center gap-4") do
                  span(class: "blitz-timer", data: {blitz_target: "timer"}) { "30" }
                  span(class: "text-xs font-mono text-gray-400 uppercase") { "seconds" }
                end
                div(class: "flex items-center gap-4") do
                  div(class: "text-right") do
                    span(class: "text-xs font-mono text-gray-400 uppercase block") { "Score" }
                    span(class: "text-2xl font-mono font-bold text-dojo-gold", data: {blitz_target: "score"}) { "0" }
                  end
                  div(class: "text-right") do
                    span(class: "text-xs font-mono text-gray-400 uppercase block") { "Solved" }
                    span(class: "text-2xl font-mono font-bold text-dojo-green", data: {blitz_target: "solvedCount"}) { "0" }
                  end
                end
              end

              # Timer progress bar
              div(class: "w-full bg-dojo-bg border border-dojo-border h-2 rounded-full overflow-hidden mb-6") do
                div(class: "belt-bar h-full rounded-full transition-all duration-1000", style: "width: 100%;", data: {blitz_target: "timerBar"})
              end

              # Challenge Card
              div(class: "kata-card flex flex-col gap-4") do
                div(class: "flex items-center justify-between") do
                  div do
                    span(class: "text-xs font-mono font-semibold uppercase tracking-wider text-dojo-cyan", data: {blitz_target: "concept"}) { "" }
                    h3(class: "text-lg font-bold text-white mt-1", data: {blitz_target: "kataTitle"}) { "" }
                  end
                  span(class: "text-sm font-mono text-dojo-gold bg-dojo-gold/10 border border-dojo-gold/30 px-3 py-1 rounded", data: {blitz_target: "xpBadge"}) { "" }
                end

                # Task
                div(class: "bg-dojo-cyan/5 border border-dojo-cyan/20 p-3 rounded-lg") do
                  p(class: "text-sm text-gray-200 font-medium", data: {blitz_target: "task"}) { "" }
                end

                # Test string
                div(
                  class: "bg-dojo-bg border border-dojo-border font-mono p-3 rounded-lg text-base whitespace-pre-wrap break-all",
                  data: {blitz_target: "testString"}
                ) { "" }

                # Pattern input
                div(class: "relative flex items-center") do
                  span(class: "absolute left-4 font-mono text-dojo-cyan select-none") { "/" }
                  input(
                    type: "text",
                    class: "regex-input pl-8 pr-12 text-lg font-mono",
                    placeholder: "type fast...",
                    autocomplete: "off",
                    spellcheck: "false",
                    data: {
                      blitz_target: "patternInput",
                      action: "keydown.enter->blitz#submit input->blitz#liveCheck"
                    }
                  )
                  span(class: "absolute right-4 font-mono text-dojo-cyan select-none") { "/g" }
                end

                # Feedback
                div(class: "hidden text-xs font-mono p-2 rounded", data: {blitz_target: "feedback"}) { "" }

                button(
                  class: "btn-dojo px-6 py-2 rounded-lg font-bold text-sm",
                  data: {action: "click->blitz#submit"}
                ) { "⚡ Submit" }
              end
            end

            # Results Screen (hidden initially)
            div(class: "panel-hidden", data: {blitz_target: "resultPanel"}) do
              div(class: "kata-card text-center py-12 flex flex-col items-center gap-6") do
                div(class: "text-6xl") { "🏆" }
                h2(class: "text-3xl font-bold text-white") { "Blitz Complete!" }

                div(class: "flex items-center gap-8 mt-4") do
                  div(class: "text-center") do
                    span(class: "block text-4xl font-mono font-bold text-dojo-gold", data: {blitz_target: "finalScore"}) { "0" }
                    span(class: "text-xs text-gray-500 font-mono uppercase") { "Total Score" }
                  end
                  div(class: "text-center") do
                    span(class: "block text-4xl font-mono font-bold text-dojo-green", data: {blitz_target: "finalSolved"}) { "0" }
                    span(class: "text-xs text-gray-500 font-mono uppercase") { "Katas Solved" }
                  end
                end

                button(
                  class: "btn-dojo px-10 py-3 rounded-lg text-lg font-bold mt-4",
                  data: {action: "click->blitz#restart"}
                ) { "⚡ Play Again" }
              end
            end
          end
        end
      end
    end
  end
end
