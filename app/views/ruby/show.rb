# auto_register: false
# frozen_string_literal: true

# Kept out of the container so Actions::Ruby::Show doesn't auto-pair with
# it; the action builds this Phlex page by hand.

require "phlex"
require "json"

module RegexDojo
  module Views
    module Ruby
      # The Ruby experiment: objective, given data, expected result, a code
      # box, and — once solved — the ways to solve it. Checking is the same
      # form + PRG flow as the regex track; previous/next are plain links.
      class Show < Phlex::HTML
        include Views::Translatable

        def initialize(challenge:, position:, total:, previous_id:, next_id:, solved: false, last_answer: nil, result: nil)
          @challenge = challenge
          @payload = JSON.parse(challenge.payload.to_s)
          @position = position
          @total = total
          @previous_id = previous_id
          @next_id = next_id
          @solved = solved
          @last_answer = last_answer
          @result = result
        rescue JSON::ParserError
          @payload = {}
        end

        def view_template
          main(class: "max-w-[880px] mx-auto px-11 pb-24 max-md:px-6", data: {controller: "reveal"}) do
            top_line

            header(class: "mt-7 mb-6") do
              h6(class: "font-body text-[13px] uppercase tracking-[0.08em] text-sage-700 font-semibold mb-2") do
                @challenge.concept
              end
              h1(class: "font-display text-[40px] leading-[1.1]") { @challenge.title }
            end

            objective_box
            given_block
            expected_block

            form(action: "/ruby/#{@challenge.id}/check", method: "post") do
              textarea(
                name: "answer",
                rows: 3,
                spellcheck: false,
                placeholder: t("ruby.placeholder"),
                aria_label: t("ruby.code_label"),
                class: "w-full bg-sand border border-ink/15 rounded-[22px] px-5 py-4 font-mono text-[16px] leading-relaxed resize-y focus:border-terra-500"
              ) { @last_answer.to_s }

              hint_box
              result_banner
              ways_box if @solved

              div(class: "flex items-center gap-3 mt-8") do
                button(type: "submit", class: "btn btn-primary px-8") { t("ruby.verify") }
                button(type: "button", class: "btn btn-secondary", data: {action: "reveal#show"}) do
                  t("desafio.hint")
                end
              end
            end

            track_links
          end
        end

        private

        def top_line
          div(class: "flex items-center gap-4 py-1") do
            a(class: "btn btn-ghost text-[14px]", href: "/") do
              render Components::Icon.new(:arrow_left)
              plain t("desafio.back")
            end
            span(class: "mx-auto font-mono text-[12.5px] text-ink/55") do
              t("ruby.context", position: @position, total: @total)
            end
            span(class: "chip border border-ink/15 text-dune-700 text-[11px]") { t("ruby.experiment") }
          end
        end

        def objective_box
          div(class: "flex items-center gap-3 bg-sage-100 rounded-[18px] px-5 py-4 mb-6 max-w-[640px]") do
            span(class: "shrink-0 text-sage-800") { render Components::Icon.new(:info) }
            # Challenge copy is trusted seed content with inline markup.
            span(class: "text-[15px] text-sage-900") { raw safe(@payload["prompt"].to_s) }
          end
        end

        def given_block
          div(class: "font-mono text-[10.5px] uppercase tracking-[0.12em] text-ink/40 mb-2") do
            t("ruby.given_label")
          end
          div(class: "bg-dune-100 rounded-2xl px-5 py-3.5 font-mono text-[15px] mb-4 whitespace-pre-wrap") do
            Array(@payload["setup"]).join("\n")
          end
        end

        def expected_block
          div(class: "font-mono text-[10.5px] uppercase tracking-[0.12em] text-ink/40 mb-2") do
            t("ruby.expected_label")
          end
          div(class: "bg-dune-100 rounded-2xl px-5 py-3.5 font-mono text-[15px] text-terra-700 mb-6") do
            @payload["expected_output"].to_s
          end
        end

        def hint_box
          div(
            class: "hidden mt-4 bg-terra-100 rounded-[18px] px-5 py-4 text-[14.5px] text-terra-800 max-w-[640px]",
            data: {reveal_target: "item"}
          ) { raw safe(@challenge.hint.to_s) }
        end

        def result_banner
          return unless @result

          case @result["status"]
          when "passing" then success_banner
          when "failing" then failure_banner(@result["feedback"] || t("ruby.failing"))
          when "error" then failure_banner(@result["message"])
          end
        end

        def success_banner
          xp = @result["xp_awarded"].to_i
          message = xp.positive? ? t("desafio.success", xp: xp) : t("desafio.success_already")

          div(class: "mt-4 pop flex items-center gap-3 bg-sage-200 rounded-[18px] px-5 py-4 max-w-[640px]") do
            span(class: "text-sage-800") { render Components::Icon.new(:check, classes: "w-5 h-5") }
            span(class: "text-[15px] text-sage-900 font-semibold") { message }
          end

          feedback = @result["feedback"].to_s
          return if feedback.empty?

          div(class: "mt-2 bg-dune-100 rounded-[18px] px-5 py-3 text-[13.5px] text-ink/70 max-w-[640px]") do
            feedback
          end
        end

        def failure_banner(message)
          div(class: "mt-4 bg-terra-100 rounded-[18px] px-5 py-4 text-[14.5px] text-terra-800 max-w-[640px]") do
            message.to_s
          end
        end

        def ways_box
          approaches = Array(@payload["approaches"])
          return if approaches.empty?

          div(class: "mt-5 bg-dune-100 rounded-[22px] p-6 max-w-[640px]") do
            div(class: "font-mono text-[10.5px] uppercase tracking-[0.12em] text-ink/40 mb-3") do
              t("ruby.ways_label")
            end
            approaches.each_with_index do |approach, index|
              div(class: "bg-cream rounded-xl px-4 py-2.5 font-mono text-[14px] mb-1") { approach["code"].to_s }
              div(class: "text-[12.5px] opacity-60 #{"mb-3" if index < approaches.size - 1}") do
                approach["note"].to_s
              end
            end
          end
        end

        def track_links
          div(class: "flex items-center gap-3 mt-9") do
            a(class: "btn btn-ghost text-[14px]", href: "/ruby/#{@previous_id}") do
              render Components::Icon.new(:arrow_left)
              plain t("ruby.previous")
            end
            a(class: "btn btn-ghost ml-auto text-[14px]", href: "/ruby/#{@next_id}") do
              plain t("desafio.next")
              render Components::Icon.new(:chevron_right)
            end
          end
        end
      end
    end
  end
end
