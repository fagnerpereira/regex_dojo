# auto_register: false
# frozen_string_literal: true

# Kept out of the container: Actions::Inicio::Show would otherwise auto-pair
# with a registered "views.inicio.show" and instantiate it without kwargs.
# Phlex pages are plain classes the action builds by hand.

require "phlex"
require "date"
require "json"
require_relative "../../../lib/regex_dojo/belt_scale"
require_relative "../../../lib/regex_dojo/tracks"

module RegexDojo
  module Views
    module Inicio
      # The calm home hub: date greeting, "continue" hero with the ghost
      # answer, the two track cards and the three tool cards.
      class Show < Phlex::HTML
        include Views::Translatable

        def initialize(user:, challenges:, solved_ids:, ruby_track:)
          @user = user
          @challenges = challenges
          @solved_ids = solved_ids
          @ruby_track = ruby_track
        end

        def view_template
          main(class: "max-w-[1140px] mx-auto px-11 pb-20 max-md:px-6") do
            header(class: "mt-6 mb-9") do
              div(class: "font-body text-[13px] uppercase tracking-[0.08em] text-ink/50 mb-2") do
                l(Date.today, format: :greeting)
              end
              h1(class: "font-display text-[44px] leading-[1.1]") { t("inicio.greeting") }
            end

            div(class: "grid grid-cols-[1.55fr_1fr] gap-4 items-stretch max-lg:grid-cols-1") do
              continue_hero
              div(class: "flex flex-col gap-3.5") do
                regex_track_card
                ruby_track_card
              end
            end

            tools_section
          end
        end

        private

        def current_challenge
          @current_challenge ||=
            @challenges.find { |c| !@solved_ids.include?(c[:id]) } || @challenges.first
        end

        def current_position
          @challenges.index(current_challenge).to_i + 1
        end

        def continue_hero
          section(class: "bg-sand rounded-blob p-10 flex flex-col gap-5 shadow-soft") do
            h6(class: "font-body text-[13px] uppercase tracking-[0.08em] text-terra-600 font-semibold") do
              t("inicio.continue_kicker", position: current_position, total: @challenges.size)
            end

            div do
              h2(class: "font-display text-[32px] mb-1.5") { current_challenge[:title] }
              # Challenge copy is trusted seed content and carries inline
              # <code>/<strong> markup by design.
              p(class: "opacity-80") { raw safe(current_challenge[:task].to_s) }
            end

            div(class: "bg-cream rounded-[22px] px-6 py-5") do
              div(class: "font-mono text-[10.5px] uppercase tracking-[0.12em] text-ink/45 mb-1.5") do
                t("inicio.target_label")
              end
              div(class: "font-mono codesize text-ink/35") do
                plain ghost_answer
                span(class: "caret")
              end
            end

            div(class: "flex gap-3 mt-1") do
              a(class: "btn btn-primary", href: "/desafios/#{current_challenge[:id]}") do
                t("inicio.continue_button")
              end
            end
          end
        end

        # The hero teases the answer as a ghost target to retype from memory
        # (prototype behavior). The third hint layer is the answer.
        def ghost_answer
          layers = JSON.parse(current_challenge[:hint].to_s)
          layers.is_a?(Array) ? layers.last.to_s : "…"
        rescue JSON::ParserError
          "…"
        end

        def regex_track_card
          solved = @challenges.count { |c| @solved_ids.include?(c[:id]) }

          section(class: "flex-1 bg-sand rounded-blob px-8 py-6 flex flex-col justify-center gap-3") do
            div(class: "flex items-baseline justify-between") do
              span(class: "text-[10px] uppercase tracking-[0.1em] text-terra-600 font-semibold") do
                t("inicio.track_label")
              end
              span(class: "font-mono text-[12px] opacity-55") do
                t("inicio.challenges_count", solved: solved, total: @challenges.size)
              end
            end
            h3(class: "font-display text-[24px]") { Tracks.label_for("regex") }
            div(class: "h-2.5 rounded-full bg-dune-200 overflow-hidden") do
              i(
                class: "block h-full rounded-full bg-terra-500 transition-all duration-700",
                style: "width: #{percentage(solved, @challenges.size)}%;"
              )
            end
            div(class: "font-mono text-[12px] text-ink/55") { regex_xp_meta }
            a(class: "btn btn-secondary self-start mt-1", href: "/desafios") { t("inicio.practice") }
          end
        end

        def regex_xp_meta
          xp = @user[:xp]
          meta = "#{xp}/#{BeltScale::MAX_XP} XP · "
          next_tier = BeltScale::TIERS.select { |threshold, _| threshold > xp }.min_by(&:first)

          if next_tier
            meta + t("inicio.xp_remaining", missing: next_tier.first - xp, level: next_tier.last)
          else
            meta + t("inicio.xp_topped")
          end
        end

        def ruby_track_card
          solved = @ruby_track[:solved_count].to_i
          total = @ruby_track[:total_count].to_i
          ceiling = Tracks::REGISTRY.fetch("ruby")[:xp_ceiling]
          xp_each = total.positive? ? ceiling / total : 0

          section(class: "flex-1 bg-sand rounded-blob px-8 py-6 flex flex-col justify-center gap-3 opacity-80") do
            div(class: "flex items-baseline justify-between") do
              span(class: "text-[10px] uppercase tracking-[0.1em] text-sage-700 font-semibold") do
                t("inicio.experiment_track_label")
              end
              span(class: "font-mono text-[12px] opacity-55") do
                t("inicio.challenges_count", solved: solved, total: total)
              end
            end
            h3(class: "font-display text-[24px]") { Tracks.label_for("ruby") }
            div(class: "h-2.5 rounded-full bg-dune-200 overflow-hidden") do
              i(
                class: "block h-full rounded-full bg-sage-500 transition-all duration-700",
                style: "width: #{percentage(solved, total)}%;"
              )
            end
            div(class: "font-mono text-[12px] text-ink/55") do
              "#{solved * xp_each}/#{ceiling} XP · #{t("inicio.ruby_topic")}"
            end
            a(class: "btn btn-secondary self-start mt-1", href: "/ruby") { t("inicio.practice") }
          end
        end

        def tools_section
          section(class: "mt-12") do
            h6(class: "font-body text-[13px] uppercase tracking-[0.08em] text-ink/50 mb-3.5 font-semibold") do
              t("inicio.tools")
            end
            div(class: "grid grid-cols-3 gap-4 max-lg:grid-cols-1") do
              tool_card(href: "/sandbox", icon: :flask, tone: "bg-sage-200 text-sage-800",
                title: "Sandbox", description: t("inicio.sandbox_description"))
              tool_card(href: "/blitz", icon: :zap, tone: "bg-terra-200 text-terra-800",
                title: "Blitz", description: t("inicio.blitz_description"))
              tool_card(href: "/codex", icon: :book, tone: "bg-sage-200 text-sage-800",
                title: "Codex", description: t("inicio.codex_description"))
            end
          end
        end

        def tool_card(href:, icon:, tone:, title:, description:)
          a(href: href, class: "bg-dune-100 rounded-blob p-7 flex flex-col gap-2.5 hover:shadow-soft transition-shadow no-underline text-ink") do
            span(class: "w-11 h-11 rounded-full grid place-items-center #{tone}") do
              render Components::Icon.new(icon, classes: "w-5 h-5")
            end
            h4(class: "font-display text-[19px]") { title }
            p(class: "text-[13.5px] opacity-70 m-0") { description }
          end
        end

        def percentage(part, whole)
          return 0 unless whole.positive?

          [(part.to_f / whole * 100).round, 100].min
        end
      end
    end
  end
end
