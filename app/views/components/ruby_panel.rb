# frozen_string_literal: true

require "phlex"
require "json"

module RegexDojo
  module Views
    module Components
      # The ruby track's arena. Unlike DojoPanel, this renders exactly ONE
      # server-selected challenge — no sidebar, no bulk data attributes — so
      # the page stays light when the harvest grows the track to hundreds of
      # items, and challenge selection stays a server concern (which is where
      # the spaced-repetition scheduler plugs in later).
      class RubyPanel < Phlex::HTML
        def initialize(challenge:, solved_count: 0, total_count: 0)
          @challenge = challenge
          @solved_count = solved_count
          @total_count = total_count
          @payload = challenge ? JSON.parse(challenge.payload.to_s) : {}
        end

        def view_template
          unless @challenge
            return div(class: "kata-card text-gray-300") { "No ruby challenges seeded yet — run: hanami db seed" }
          end

          div(
            class: "max-w-3xl mx-auto",
            data: {
              controller: "ruby-dojo",
              ruby_dojo_challenge_id_value: @challenge.id
            }
          ) do
            div(class: "kata-card flex flex-col gap-6 relative overflow-hidden") do
              div(class: "absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-dojo-purple to-dojo-cyan")

              # Header: concept + progress through the track
              div(class: "flex items-center justify-between mt-1") do
                div do
                  span(class: "text-xs font-mono font-semibold uppercase tracking-wider text-dojo-cyan") { @challenge.concept.to_s }
                  h2(class: "text-xl font-bold text-white mt-1") { @challenge.title }
                end
                span(class: "text-sm font-mono text-dojo-gold bg-dojo-gold/10 border border-dojo-gold/30 px-3 py-1 rounded") do
                  "#{@solved_count}/#{@total_count} solved"
                end
              end

              # The task
              div(class: "flex flex-col gap-2 bg-dojo-cyan/5 border border-dojo-cyan/20 p-4 rounded-lg") do
                span(class: "text-xs font-mono text-dojo-cyan font-bold uppercase") { "⚔️ Objective:" }
                p(class: "text-sm text-gray-200 font-medium") { @payload["prompt"].to_s }
              end

              # Given setup + expected output — everything needed to answer
              div(class: "flex flex-col gap-2") do
                span(class: "text-xs font-mono text-gray-400 uppercase") { "Given:" }
                div(class: "bg-dojo-bg border border-dojo-border font-mono p-4 rounded-lg text-sm text-gray-200 whitespace-pre-wrap") do
                  plain Array(@payload["setup"]).join("\n")
                end
                span(class: "text-xs font-mono text-gray-400 uppercase mt-2") { "Expected result:" }
                div(class: "bg-dojo-bg border border-dojo-border font-mono p-4 rounded-lg text-sm text-dojo-gold whitespace-pre-wrap") do
                  plain @payload["expected_output"].to_s
                end
              end

              # The answer — typed, never autocompleted; graded server-side only
              div(class: "flex flex-col gap-3") do
                textarea(
                  class: "regex-input font-mono text-lg p-4 min-h-[80px] resize-y",
                  placeholder: "type your ruby here...",
                  autocomplete: "off",
                  spellcheck: "false",
                  data: {
                    ruby_dojo_target: "input",
                    action: "keydown.meta+enter->ruby-dojo#submit keydown.ctrl+enter->ruby-dojo#submit"
                  }
                )

                div(class: "hidden bg-dojo-red/10 border border-dojo-red/30 text-dojo-red text-xs font-mono p-3 rounded-lg", data: {ruby_dojo_target: "errorBanner"}) { "" }
                div(class: "hidden bg-dojo-cyan/10 border border-dojo-cyan/30 text-dojo-cyan text-sm font-mono p-3 rounded-lg", data: {ruby_dojo_target: "successBanner"}) { "" }

                div(class: "flex items-center gap-4") do
                  button(
                    type: "button",
                    class: "px-4 py-2 border border-dojo-border hover:bg-dojo-surface hover:border-gray-500 rounded text-xs font-mono text-gray-400 transition-all",
                    data: {action: "click->ruby-dojo#revealHint"}
                  ) { "💡 Need Hint" }

                  div(class: "hidden text-xs font-mono text-dojo-gold bg-dojo-gold/5 border border-dojo-gold/20 p-2 rounded flex-1", data: {ruby_dojo_target: "hintText"}) do
                    plain @challenge.hint.to_s
                  end

                  button(
                    type: "button",
                    class: "btn-dojo px-6 py-2.5 rounded-lg flex-1 text-center font-bold text-sm select-none shadow-md cursor-pointer",
                    data: {action: "click->ruby-dojo#submit"}
                  ) { "⚔️ Submit (⌘⏎)" }
                end
              end
            end
          end
        end
      end
    end
  end
end
