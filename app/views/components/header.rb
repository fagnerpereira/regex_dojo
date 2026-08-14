# frozen_string_literal: true

require "phlex"
require_relative "../../../lib/regex_dojo/belt_scale"

module RegexDojo
  module Views
    module Components
      # Global Organic header (prototype nav): brand, level chip, XP bar,
      # static locale chip, dark-mode toggle, streak chip. Fully re-rendered
      # by the server on every navigation, so no client code patches it.
      class Header < Phlex::HTML
        include Views::Translatable

        def initialize(user:, dark: false)
          @user = user
          @dark = dark
        end

        def view_template
          nav(class: "flex flex-wrap items-center gap-5 px-11 py-6 max-w-[1228px] mx-auto max-md:px-6") do
            a(href: "/", class: "font-display text-[21px] mr-auto no-underline text-ink") { t("app.title") }

            # Level is always derived from XP — the stored belt column may
            # carry stale pre-rename labels.
            span(class: "chip bg-dune-100 text-dune-800 font-body") { BeltScale.for(@user[:xp]) }

            span(class: "inline-flex items-center gap-2.5") do
              span(class: "w-[220px] h-3 rounded-full bg-dune-200 border border-ink/15 overflow-hidden") do
                i(
                  id: "xpbar",
                  class: "block h-full rounded-full bg-terra-500 transition-all duration-700",
                  style: "width: #{bar_percentage}%;"
                )
              end
              span(class: "font-mono text-[13px] font-medium text-terra-700") do
                "#{@user[:xp]}/#{BeltScale::MAX_XP} XP"
              end
            end

            span(class: "chip border border-ink/15 text-dune-700") do
              plain "PT"
              render Icon.new(:chevron_down, classes: "w-3 h-3")
            end

            theme_toggle

            span(class: "chip bg-terra-100 text-terra-800") do
              render Icon.new(:flame)
              span { t("header.streak", count: @user[:streak]) }
            end
          end
        end

        private

        def bar_percentage
          [(@user[:xp].to_f / BeltScale::MAX_XP * 100).round, 100].min
        end

        def theme_toggle
          button(
            data: {controller: "theme", action: "click->theme#toggle"},
            aria_label: t("header.theme_toggle"),
            class: "w-9 h-9 grid place-items-center rounded-full border border-ink/15 " \
              "text-dune-700 cursor-pointer bg-transparent hover:bg-ink/5 active:bg-ink/10 transition-colors"
          ) do
            span(class: icon_classes(hidden: @dark), data: {theme_target: "moonIcon"}) { render Icon.new(:moon) }
            span(class: icon_classes(hidden: !@dark), data: {theme_target: "sunIcon"}) { render Icon.new(:sun) }
          end
        end

        def icon_classes(hidden:)
          hidden ? "hidden" : "grid place-items-center"
        end
      end
    end
  end
end
