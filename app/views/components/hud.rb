# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Views
    module Components
      class Hud < Phlex::HTML
        def initialize(user:)
          @user = user # users SQLite struct
        end

        def view_template
          div(id: "hud-bar", class: "sticky top-0 z-50 bg-dojo-surface/80 backdrop-blur-md border-b border-dojo-border py-4 px-6 shadow-lg shadow-dojo-bg/20") do
            div(class: "max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4") do
              # Logo / Title
              div(class: "flex items-center gap-3") do
                span(class: "text-2xl") { "🥋" }
                span(class: "font-mono font-bold text-lg tracking-wider bg-gradient-to-r from-dojo-purple to-dojo-cyan bg-clip-text text-transparent") { "RegexDojo" }
              end

              # XP and Belt Progress
              div(class: "flex-1 max-w-md w-full flex items-center gap-4") do
                # Dynamic styling based on current belt level
                belt_styles = {
                  "white" => "text-white border-white/20 bg-white/5 shadow-white/5",
                  "yellow" => "text-dojo-gold border-dojo-gold/20 bg-dojo-gold/5 shadow-dojo-gold/5",
                  "orange" => "text-orange-400 border-orange-400/20 bg-orange-400/5 shadow-orange-400/5",
                  "green" => "text-dojo-green border-dojo-green/20 bg-dojo-green/5 shadow-dojo-green/5",
                  "black" => "text-purple-400 border-purple-400/20 bg-purple-400/5 shadow-purple-400/5"
                }
                current_belt_style = belt_styles[@user[:belt].to_s.downcase] || "text-dojo-cyan border-dojo-border bg-dojo-bg"

                # Current Belt Badge
                span(
                  id: "hud-belt-badge",
                  class: "px-3 py-1 text-xs font-mono font-semibold uppercase tracking-wider rounded border shadow-sm transition-all duration-500 #{current_belt_style}"
                ) do
                  "#{@user[:belt].capitalize} Belt"
                end

                # Progress Bar
                div(class: "flex-grow bg-dojo-bg border border-dojo-border h-4 rounded-full overflow-hidden p-[2px] relative") do
                  xp_limit = 520
                  percentage = [(@user[:xp].to_f / xp_limit * 100).round, 100].min

                  div(
                    class: "belt-bar h-full rounded-full transition-all duration-500",
                    style: "width: #{percentage}%;"
                  )
                end

                # XP Label
                span(class: "font-mono text-sm text-dojo-gold min-w-[70px] text-right") do
                  "#{@user[:xp]}/520 XP"
                end
              end

              # Streak and Status
              div(class: "flex items-center gap-6") do
                # Streak
                div(class: "flex items-center gap-2 bg-dojo-bg/40 border border-dojo-border px-3 py-1 rounded-full") do
                  span { "🔥" }
                  span(class: "font-mono text-sm font-semibold") { "#{@user[:streak]} Day Streak" }
                end

                # Session ID (shortened)
                div(class: "hidden sm:flex flex-col items-end text-[10px] text-dojo-border font-mono") do
                  span { "WARRIOR ID" }
                  span(class: "text-dojo-cyan/60") { @user[:session_id][0..7] }
                end
              end
            end
          end
        end
      end
    end
  end
end
