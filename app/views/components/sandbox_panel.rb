# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Views
    module Components
      class SandboxPanel < Phlex::HTML
        def view_template
          div(class: "flex flex-col gap-6", data: {controller: "sandbox"}) do
            # Header
            div(class: "flex items-center justify-between") do
              div do
                h2(class: "text-xl font-bold text-white") { "🧪 Regex Sandbox" }
                p(class: "text-sm text-gray-400 mt-1") { "Free-play environment. Paste any text, test any pattern, explore what matches." }
              end
              button(
                class: "px-4 py-2 border border-dojo-border hover:border-gray-500 rounded-lg text-xs font-mono text-gray-400 hover:text-white transition-all",
                data: {action: "click->sandbox#clear"}
              ) { "🗑️ Clear" }
            end

            div(class: "grid grid-cols-1 lg:grid-cols-2 gap-6") do
              # Left: Input Area
              div(class: "flex flex-col gap-4") do
                # Pattern Input
                div(class: "flex flex-col gap-2") do
                  span(class: "text-xs font-mono text-gray-400 uppercase") { "Pattern:" }
                  div(class: "relative") do
                    # Decorations pin to the first and last line so the field
                    # reads as a literal even when the pattern wraps
                    span(class: "absolute left-4 top-3 font-mono text-dojo-cyan select-none") { "/" }
                    # A one-row textarea that auto-grows (sandbox_controller),
                    # so a long pattern wraps instead of hiding off-screen
                    textarea(
                      rows: 1,
                      class: "regex-input pl-8 pr-16 font-mono resize-none overflow-hidden",
                      placeholder: "type your regex pattern...",
                      autocomplete: "off",
                      spellcheck: "false",
                      data: {
                        sandbox_target: "pattern",
                        action: "input->sandbox#evaluate"
                      }
                    )
                    # Live literal tail: sandbox_controller keeps this in sync
                    # with the toggled flags (/g, /gi, ... /gims)
                    span(
                      class: "absolute right-4 bottom-3 font-mono text-dojo-cyan select-none",
                      data: {sandbox_target: "flagsDisplay"}
                    ) { "/g" }
                  end
                end

                # Flags
                div(class: "flex items-center gap-3") do
                  span(class: "text-xs font-mono text-gray-400 uppercase") { "Flags:" }
                  button(class: "flag-toggle active", data: {sandbox_target: "flagG", action: "click->sandbox#toggleFlag", flag: "g"}) { "g" }
                  button(class: "flag-toggle", data: {sandbox_target: "flagI", action: "click->sandbox#toggleFlag", flag: "i"}) { "i" }
                  button(class: "flag-toggle", data: {sandbox_target: "flagM", action: "click->sandbox#toggleFlag", flag: "m"}) { "m" }
                  button(class: "flag-toggle", data: {sandbox_target: "flagS", action: "click->sandbox#toggleFlag", flag: "s"}) { "s" }
                end

                # Test Text
                div(class: "flex flex-col gap-2") do
                  span(class: "text-xs font-mono text-gray-400 uppercase") { "Test Text:" }
                  textarea(
                    class: "sandbox-textarea",
                    placeholder: "Paste or type your test text here...",
                    data: {
                      sandbox_target: "input",
                      action: "input->sandbox#evaluate"
                    }
                  ) { "The quick brown fox jumps over the lazy dog.\nEmail: user@example.com\nPhone: (555) 123-4567\nDate: 2024-01-15\nURL: https://hanakai.org" }
                end

                # Match counter
                div(class: "flex items-center gap-2 text-sm font-mono") do
                  span(class: "text-gray-400") { "Matches:" }
                  span(class: "text-dojo-cyan font-bold", data: {sandbox_target: "matchCount"}) { "0" }
                end
              end

              # Right: Results
              div(class: "flex flex-col gap-4") do
                # Highlighted output
                div(class: "flex flex-col gap-2") do
                  span(class: "text-xs font-mono text-gray-400 uppercase") { "Highlighted Output:" }
                  div(
                    class: "bg-dojo-bg border border-dojo-border font-mono p-4 rounded-lg text-sm min-h-[150px] whitespace-pre-wrap break-all",
                    data: {sandbox_target: "highlightArea"}
                  ) { "" }
                end

                # Regex Explainer
                div(class: "flex flex-col gap-2") do
                  span(class: "text-xs font-mono text-gray-400 uppercase") { "🔍 Pattern Breakdown:" }
                  div(
                    class: "bg-dojo-surface border border-dojo-border rounded-lg p-4 min-h-[100px] flex flex-wrap gap-2 items-start",
                    data: {sandbox_target: "explainer"}
                  ) do
                    span(class: "text-xs text-gray-500 italic") { "Enter a pattern above to see its breakdown..." }
                  end
                end

                # Error display
                div(class: "hidden bg-dojo-red/10 border border-dojo-red/30 text-dojo-red text-xs font-mono p-3 rounded-lg", data: {sandbox_target: "errorBanner"}) { "" }
              end
            end
          end
        end
      end
    end
  end
end
