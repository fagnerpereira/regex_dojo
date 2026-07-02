# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Components
    # Slim belt-progress strip below the global header.
    # JS contract (dojo_controller updates these after a solved kata):
    #   #hud-bar, #hud-belt-badge, #hud-xp-label, .belt-bar
    class Hud < Phlex::HTML
      XP_LIMIT = 520

      BELT_STYLES = {
        "white" => "text-dojo-slate border-dojo-violet-border bg-white",
        "yellow" => "text-dojo-warning-text border-dojo-warning/30 bg-dojo-warning-bg",
        "orange" => "text-orange-700 border-orange-200 bg-orange-50",
        "green" => "text-dojo-success-text border-dojo-success/30 bg-dojo-success-bg",
        "black" => "text-dojo-violet border-dojo-violet/30 bg-dojo-violet-light"
      }.freeze

      def initialize(user:)
        @user = user
      end

      def view_template
        div(id: "hud-bar", class: "bg-white border border-dojo-violet-border rounded-card shadow-card py-3 px-5") do
          div(class: "flex flex-col md:flex-row items-center justify-between gap-4") do
            # Current belt badge
            span(
              id: "hud-belt-badge",
              class: "px-3 py-1 text-xs font-mono font-semibold uppercase tracking-wider rounded-full border transition-all duration-500 #{belt_style}"
            ) do
              "#{@user[:belt].capitalize} Belt"
            end

            # Belt progress bar
            div(class: "flex-1 max-w-md w-full flex items-center gap-3") do
              div(class: "flex-grow bg-dojo-violet-light border border-dojo-violet-border h-3.5 rounded-full overflow-hidden p-[2px]") do
                div(
                  class: "belt-bar h-full rounded-full bg-gradient-to-r from-dojo-success to-dojo-violet transition-all duration-500",
                  style: "width: #{xp_percentage}%;"
                )
              end

              span(id: "hud-xp-label", class: "font-mono text-sm font-semibold text-dojo-violet min-w-[80px] text-right") do
                "#{@user[:xp]}/#{XP_LIMIT} XP"
              end
            end

            # Session ID (shortened)
            div(class: "hidden sm:flex flex-col items-end text-[10px] text-dojo-slate font-mono") do
              span { "WARRIOR ID" }
              span(class: "text-dojo-violet/70") { @user[:session_id][0..7] }
            end
          end
        end
      end

      private

      def belt_style
        BELT_STYLES.fetch(@user[:belt].to_s.downcase, "text-dojo-slate border-dojo-violet-border bg-white")
      end

      def xp_percentage
        [(@user[:xp].to_f / XP_LIMIT * 100).round, 100].min
      end
    end
  end
end
