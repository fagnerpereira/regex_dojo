# auto_register: false
# frozen_string_literal: true

# Kept out of the container so Actions::Sandbox::Show doesn't auto-pair with
# it; the action builds this Phlex page by hand.

require "phlex"

module RegexDojo
  module Views
    module Sandbox
      # Free-play: pattern field with live explanation, an editable test
      # text, and the result with every occurrence marked.
      class Show < Phlex::HTML
        include Views::Translatable

        DEFAULT_TEXT = <<~TEXT.chomp
          The quick brown fox jumps over the lazy dog.
          Email: user@example.com
          Phone: (555) 123-4567
          Date: 2024-01-15
          URL: https://hanakai.org
        TEXT

        def initialize(pattern: nil)
          @pattern = pattern.to_s
        end

        def view_template
          main(class: "max-w-[880px] mx-auto px-11 pb-24 max-md:px-6", data: {controller: "sandbox-page"}) do
            top_line

            header(class: "mt-7 mb-6") do
              h1(class: "font-display text-[40px] leading-[1.1]") { "Sandbox" }
              p(class: "opacity-70 mt-1.5") { t("sandbox.subtitle") }
            end

            pattern_row
            explanation_row
            test_text_block
            result_block
          end
        end

        private

        def top_line
          div(class: "flex items-center gap-4 py-1") do
            a(class: "btn btn-ghost text-[14px]", href: "/") do
              render Components::Icon.new(:arrow_left)
              plain t("desafio.back")
            end
            span(class: "mx-auto font-mono text-[12.5px] text-ink/55") { t("sandbox.context") }
            span(class: "w-[76px]")
          end
        end

        def pattern_row
          div(class: "flex items-center gap-3") do
            div(class: "flex-1 flex items-center gap-2.5 bg-sand border border-ink/15 rounded-[28px] px-3 py-2.5 transition-colors focus-within:border-terra-500") do
              slash_chip
              span(class: "patstack") do
                div(class: "patfield pathl", aria_hidden: true, data: {sandbox_page_target: "fieldHighlight"})
                textarea(
                  rows: 1,
                  spellcheck: false,
                  autocomplete: "off",
                  placeholder: t("desafio.placeholder"),
                  aria_label: t("desafio.pattern_label"),
                  class: "patfield patta",
                  data: {sandbox_page_target: "field"}
                ) { @pattern }
              end
              slash_chip
              span(class: "font-mono text-[15px] text-dune-600 pr-2", data: {sandbox_page_target: "flagsText"})
            end

            div(class: "flex gap-1.5", role: "group", aria_label: "Flags") do
              %w[g i m s].each do |flag|
                button(
                  type: "button",
                  class: "flagbtn",
                  title: t("desafio.flags.#{flag}"),
                  data: {flag: flag, sandbox_page_target: "flagButton"}
                ) { flag }
              end
            end
          end
        end

        def slash_chip
          span(class: "w-9 h-9 shrink-0 grid place-items-center rounded-full bg-dune-200 text-dune-700 font-mono text-[17px] font-medium") { "/" }
        end

        def explanation_row
          div(class: "flex items-center gap-2 flex-wrap mt-3.5 min-h-8") do
            span(class: "font-mono text-[10.5px] uppercase tracking-[0.12em] text-ink/40 mr-1") do
              t("desafio.explanation_label")
            end
            a(href: "/codex", class: "font-mono text-[10.5px] uppercase tracking-[0.12em] text-terra-600 no-underline mr-1") do
              t("desafio.codex_link")
            end
            span(class: "flex items-center gap-2 flex-wrap", data: {sandbox_page_target: "tokens"}) do
              span(class: "text-[12.5px] text-ink/35") { t("sandbox.tokens_placeholder") }
            end
          end
        end

        def test_text_block
          div(class: "flex items-center justify-between mt-6 mb-2") do
            span(class: "font-mono text-[10.5px] uppercase tracking-[0.12em] text-ink/40") do
              t("sandbox.test_text_label")
            end
            button(
              type: "button",
              class: "inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-[12px] text-dune-700 border border-ink/15 bg-transparent cursor-pointer hover:bg-ink/5 transition-colors",
              data: {action: "sandbox-page#copyText"}
            ) do
              render Components::Icon.new(:copy, classes: "w-3.5 h-3.5")
              span(data: {sandbox_page_target: "copyLabel"}) { t("sandbox.copy") }
            end
          end

          textarea(
            rows: 5,
            spellcheck: false,
            class: "w-full bg-sand border border-ink/15 rounded-[22px] px-5 py-4 font-mono text-[14px] leading-relaxed resize-y focus:border-terra-500",
            data: {sandbox_page_target: "text", action: "input->sandbox-page#evaluate"}
          ) { DEFAULT_TEXT }
        end

        def result_block
          div(class: "flex items-baseline justify-between mt-5 mb-2") do
            span(class: "font-mono text-[10.5px] uppercase tracking-[0.12em] text-ink/40") do
              t("sandbox.result_label")
            end
            span(class: "font-mono text-[12.5px] text-terra-700", data: {sandbox_page_target: "count"}) do
              t("sandbox.zero_occurrences")
            end
          end

          div(
            class: "bg-dune-100 rounded-[22px] px-5 py-4 font-mono text-[14px] leading-relaxed whitespace-pre-wrap min-h-[110px]",
            data: {sandbox_page_target: "output"}
          ) { DEFAULT_TEXT }
        end
      end
    end
  end
end
