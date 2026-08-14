# auto_register: false
# frozen_string_literal: true

# Kept out of the container so Actions::Blitz::Show doesn't auto-pair with
# it; the action builds this Phlex page by hand.

require "phlex"
require "json"

module RegexDojo
  module Views
    module Blitz
      # The timed mode: start card with the database-backed record, the
      # running game (timer, score, random challenge, live auto-advance) and
      # the end card. The game itself is client-side; only the final score
      # goes to the server.
      class Show < Phlex::HTML
        include Views::Translatable

        def initialize(challenges:, best_score: 0)
          @challenges = challenges
          @best_score = best_score
        end

        def view_template
          main(
            class: "max-w-[880px] mx-auto px-11 pb-24 max-md:px-6",
            data: {
              controller: "blitz-page",
              blitz_page_challenges_value: JSON.generate(@challenges),
              blitz_page_best_value: @best_score
            }
          ) do
            top_line
            start_screen
            run_screen
            end_screen
          end
        end

        private

        def top_line
          div(class: "flex items-center gap-4 py-1") do
            a(class: "btn btn-ghost text-[14px]", href: "/") do
              render Components::Icon.new(:arrow_left)
              plain t("desafio.back")
            end
            span(class: "mx-auto font-mono text-[12.5px] text-ink/55") { t("blitz.context") }
            span(class: "w-[76px]")
          end
        end

        def start_screen
          section(
            class: "bg-sand rounded-blob p-12 mt-8 text-center flex flex-col items-center gap-4 shadow-soft",
            data: {blitz_page_target: "startScreen"}
          ) do
            span(class: "w-14 h-14 rounded-full grid place-items-center bg-terra-200 text-terra-800") do
              render Components::Icon.new(:zap, classes: "w-6 h-6")
            end
            h1(class: "font-display text-[36px] m-0") { "Blitz" }
            p(class: "opacity-75 max-w-[42ch] m-0") { t("blitz.intro") }
            div(class: "flex gap-8 font-mono text-[13px] text-ink/55 my-2") do
              span do
                b(class: "text-ink") { "30s" }
                plain " #{t("blitz.time_label")}"
              end
              span do
                b(class: "text-ink", data: {blitz_page_target: "best"}) { @best_score.to_s }
                plain " #{t("blitz.record_label")}"
              end
            end
            button(type: "button", class: "btn btn-primary px-8", data: {action: "blitz-page#start"}) do
              t("blitz.start")
            end
          end
        end

        def run_screen
          section(class: "hidden mt-8", data: {blitz_page_target: "runScreen"}) do
            div(class: "flex items-center gap-5 mb-5") do
              span(class: "font-display text-[40px] w-16", data: {blitz_page_target: "time"}) { "30" }
              span(class: "flex-1 h-2.5 rounded-full bg-dune-200 overflow-hidden") do
                i(
                  class: "block h-full rounded-full bg-terra-500 transition-all duration-1000",
                  style: "width: 100%;",
                  data: {blitz_page_target: "bar"}
                )
              end
              span(class: "font-mono text-[14px]") do
                b(data: {blitz_page_target: "score"}) { "0" }
                plain " #{t("blitz.solved_label")}"
              end
            end

            div(class: "bg-sand rounded-blob p-8 flex flex-col gap-4 shadow-soft") do
              div(class: "text-[16px]", data: {blitz_page_target: "task"})
              div(class: "flex flex-col gap-2", data: {blitz_page_target: "testsList"})

              div(class: "flex items-center gap-2.5 bg-cream border border-ink/15 rounded-[26px] px-3 py-2 transition-colors focus-within:border-terra-500") do
                slash_chip
                textarea(
                  rows: 1,
                  spellcheck: false,
                  autocomplete: "off",
                  placeholder: t("blitz.placeholder"),
                  aria_label: t("desafio.pattern_label"),
                  class: "patfield",
                  style: "--code-size: 19px;",
                  data: {blitz_page_target: "field"}
                )
                slash_chip
              end

              button(
                type: "button",
                class: "btn btn-ghost self-end text-[14px]",
                data: {action: "blitz-page#skip"}
              ) { t("blitz.skip") }
            end
          end
        end

        def end_screen
          section(
            class: "hidden bg-sand rounded-blob p-12 mt-8 text-center flex flex-col items-center gap-4 shadow-soft",
            data: {blitz_page_target: "endScreen"}
          ) do
            h2(class: "font-display text-[32px] m-0") { t("blitz.time_up") }
            p(class: "opacity-75 m-0", data: {blitz_page_target: "result"})
            div(class: "flex gap-3") do
              button(type: "button", class: "btn btn-primary", data: {action: "blitz-page#start"}) do
                t("blitz.again")
              end
              a(class: "btn btn-secondary", href: "/") { t("desafio.back") }
            end
          end
        end

        def slash_chip
          span(class: "w-8 h-8 shrink-0 grid place-items-center rounded-full bg-dune-200 text-dune-700 font-mono text-[15px] font-medium") { "/" }
        end
      end
    end
  end
end
