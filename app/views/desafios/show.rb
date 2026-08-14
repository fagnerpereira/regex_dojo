# auto_register: false
# frozen_string_literal: true

# Kept out of the container so Actions::Desafios::Show doesn't auto-pair with
# it; the action builds this Phlex page by hand.

require "phlex"
require "json"

module RegexDojo
  module Views
    module Desafios
      # One challenge, one screen: lesson, task, live-graded test rows, the
      # shared pattern field and the 3-layer hint. The check form does a real
      # POST; the server redirects back here and the flash renders the
      # result banner server-side.
      class Show < Phlex::HTML
        include Views::Translatable

        def initialize(challenge:, challenges:, solved_ids:, last_pattern: nil, result: nil)
          @challenge = challenge
          @challenges = challenges
          @solved_ids = solved_ids
          @last_pattern = last_pattern
          @result = result
        end

        def view_template
          main(
            class: "max-w-[880px] mx-auto px-11 pb-24 max-md:px-6",
            data: {
              controller: "desafio",
              desafio_tests_value: JSON.generate(@challenge[:test_cases]),
              desafio_hints_value: JSON.generate(hint_layers),
              desafio_last_pattern_value: @last_pattern.to_s
            }
          ) do
            top_line

            header(class: "mt-7 mb-6") do
              h6(class: "font-body text-[13px] uppercase tracking-[0.08em] text-terra-600 font-semibold mb-2") do
                @challenge[:concept]
              end
              h1(class: "font-display text-[40px] leading-[1.1]") { @challenge[:title] }
            end

            # Challenge copy is trusted seed content with inline markup.
            p(class: "text-[16.5px] leading-[1.65] max-w-[62ch]") { raw safe(@challenge[:lesson].to_s) }

            task_box
            tests_list

            form(action: "/desafios/#{@challenge[:id]}/check", method: "post", data: {desafio_target: "form"}) do
              pattern_row
              explanation_row
              hint_box
              result_banner
              actions_row
            end
          end
        end

        private

        def position
          @challenges.index(@challenge).to_i + 1
        end

        def solved?
          @solved_ids.include?(@challenge[:id])
        end

        def hint_layers
          layers = JSON.parse(@challenge[:hint].to_s)
          layers.is_a?(Array) ? layers : [@challenge[:hint].to_s]
        rescue JSON::ParserError
          [@challenge[:hint].to_s]
        end

        def top_line
          div(class: "flex items-center gap-4 py-1") do
            a(class: "btn btn-ghost text-[14px]", href: "/") do
              render Components::Icon.new(:arrow_left)
              plain t("desafio.back")
            end

            span(class: "mx-auto flex items-center gap-4") do
              span(class: "font-mono text-[12.5px] text-ink/55") do
                t("desafio.context", position: position, total: @challenges.size)
              end
              span(class: "flex items-center") { progress_dots }
            end

            span(class: "chip border border-terra-500 text-terra-600 bg-transparent text-[11.5px]") do
              t("desafio.worth", xp: @challenge[:xp])
            end
          end
        end

        # Every dot navigates to its challenge; the visible dot is small but
        # the link box keeps a tall touch target.
        def progress_dots
          @challenges.each do |c|
            a(
              href: "/desafios/#{c[:id]}",
              title: c[:title],
              aria_label: c[:title],
              class: "grid place-items-center min-h-[44px] px-[3.5px]"
            ) { i(class: dot_classes(c)) }
          end
        end

        def dot_classes(challenge)
          if challenge[:id] == @challenge[:id]
            "block w-3 h-3 rounded-full bg-terra-500"
          elsif @solved_ids.include?(challenge[:id])
            "block w-[9px] h-[9px] rounded-full bg-sage-400"
          else
            "block w-[9px] h-[9px] rounded-full bg-dune-300"
          end
        end

        def task_box
          div(class: "flex items-center gap-3 bg-sage-100 rounded-[18px] px-5 py-4 my-6 max-w-[640px]") do
            span(class: "shrink-0 text-sage-800") { render Components::Icon.new(:info) }
            span(class: "text-[15px] text-sage-900") { raw safe(@challenge[:task].to_s) }
          end
        end

        # Initial server-rendered rows mirror the controller's empty-pattern
        # render; the controller re-renders them on every keystroke.
        def tests_list
          div(class: "flex flex-col gap-2.5 mb-7", data: {desafio_target: "testsList"}) do
            @challenge[:test_cases].each do |tc|
              div(class: "flex items-center gap-3.5 rounded-2xl bg-dune-100 px-5 py-3") do
                span(class: "font-mono text-[15px] flex-1") { tc[:input] }
                span(class: "text-[11.5px] text-ink/45") { expectation_label(tc) }
                span(class: "w-3 h-3 shrink-0 rounded-full border-[1.5px] border-ink/25")
              end
            end
          end
        end

        def expectation_label(test_case)
          if test_case[:should_match]
            t("desafio.should_match", expected: test_case[:expected_match])
          else
            t("desafio.should_not_match")
          end
        end

        def pattern_row
          div(class: "flex items-center gap-3") do
            div(class: "flex-1 flex items-center gap-2.5 bg-sand border border-ink/15 rounded-[28px] px-3 py-2.5 transition-colors focus-within:border-terra-500") do
              slash_chip
              span(class: "patstack") do
                div(class: "patfield pathl", aria_hidden: true, data: {desafio_target: "fieldHighlight"})
                textarea(
                  name: "answer",
                  rows: 1,
                  spellcheck: false,
                  autocomplete: "off",
                  placeholder: t("desafio.placeholder"),
                  aria_label: t("desafio.pattern_label"),
                  class: "patfield patta",
                  data: {desafio_target: "field"}
                )
              end
              slash_chip
              span(class: "font-mono text-[15px] text-dune-600 pr-2", data: {desafio_target: "flagsText"})
            end

            div(class: "flex gap-1.5", role: "group", aria_label: "Flags") do
              %w[g i m s].each do |flag|
                button(
                  type: "button",
                  class: "flagbtn",
                  title: t("desafio.flags.#{flag}"),
                  data: {flag: flag, desafio_target: "flagButton"}
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
            span(class: "flex items-center gap-2 flex-wrap", data: {desafio_target: "tokens"}) do
              span(class: "text-[12.5px] text-ink/35") { t("desafio.tokens_placeholder") }
            end
          end
        end

        def hint_box
          div(
            class: "hidden mt-5 bg-terra-100 rounded-[18px] px-5 py-4 text-[14.5px] text-terra-800 max-w-[640px]",
            data: {desafio_target: "hintBox"}
          )
        end

        def result_banner
          return unless @result

          case @result["status"]
          when "passing" then success_banner
          when "failing" then failure_banner(@result["feedback"] || t("desafio.failing"))
          when "error" then failure_banner(@result["message"])
          end
        end

        def success_banner
          xp = @result["xp_awarded"].to_i
          message = xp.positive? ? t("desafio.success", xp: xp) : t("desafio.success_already")

          div(class: "mt-5 pop flex items-center gap-3 bg-sage-200 rounded-[18px] px-5 py-4 max-w-[640px]") do
            span(class: "text-sage-800") { render Components::Icon.new(:check, classes: "w-5 h-5") }
            span(class: "text-[15px] text-sage-900 font-semibold") { message }
          end
        end

        def failure_banner(message)
          div(class: "mt-5 bg-terra-100 rounded-[18px] px-5 py-4 text-[14.5px] text-terra-800 max-w-[640px]") do
            message.to_s
          end
        end

        def actions_row
          div(class: "flex items-center gap-3 mt-9") do
            button(
              type: "submit",
              disabled: true,
              class: "btn btn-primary text-[15px] px-8 disabled:opacity-45 disabled:cursor-not-allowed",
              data: {desafio_target: "submit"}
            ) do
              plain t("desafio.submit")
              plain " "
              span(class: "font-mono text-[12px] opacity-75") { "↵" }
            end

            button(type: "button", class: "btn btn-secondary text-[15px]", data: {action: "desafio#revealHint"}) do
              t("desafio.hint")
            end

            next_link if solved?
          end
        end

        def next_link
          index = @challenges.index(@challenge)

          if index >= @challenges.size - 1
            a(class: "btn btn-ghost ml-auto text-[14px]", href: "/") { t("desafio.track_complete") }
          else
            a(class: "btn btn-ghost ml-auto text-[14px]", href: "/desafios/#{@challenges[index + 1][:id]}") do
              plain t("desafio.next")
              render Components::Icon.new(:chevron_right)
            end
          end
        end
      end
    end
  end
end
