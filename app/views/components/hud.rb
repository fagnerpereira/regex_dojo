# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Views
    module Components
      class Hud < Phlex::HTML
        def initialize(user:)
          @user = user # users SQLite struct
        end

        def template
          div(id: "hud-bar", class: "sticky top-0 z-50 bg-dojo-surface/80 backdrop-blur-md border-b border-dojo-border py-4 px-6 shadow-lg shadow-dojo-bg/20") do
            div(class: "max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4") do
              # Logo / Title
              div(class: "flex items-center gap-3") do
                span(class: "text-2xl") { "🥋" }
                span(class: "font-mono font-bold text-lg tracking-wider bg-gradient-to-r from-dojo-purple to-dojo-cyan bg-clip-text text-transparent") { "RegexDojo" }
              end

              # XP and Belt Progress
              div(class: "flex-1 max-w-md w-full flex items-center gap-4") do
                # Current Belt Badge
                span(class: "px-3 py-1 text-xs font-mono font-semibold uppercase tracking-wider rounded border border-dojo-border bg-dojo-bg text-dojo-cyan shadow-sm shadow-dojo-cyan/10") do
                  "#{@user[:belt].capitalize} Belt"
                end

                # Progress Bar
                div(class: "flex-grow bg-dojo-bg border border-dojo-border h-4 rounded-full overflow-hidden p-[2px] relative") do
                  # Determine percentage based on current belt levels
                  # Let's say White Belt requires 200 XP to level up to Yellow.
                  # Simple math for MVP: % of current level (max 200 XP for White)
                  xp_limit = 200
                  percentage = [(@user[:xp].to_f / xp_limit * 100).round, 100].min

                  div(
                    class: "belt-bar h-full rounded-full transition-all duration-500",
                    style: "width: #{percentage}%;"
                  )
                end

                # XP Label
                span(class: "font-mono text-sm text-dojo-gold min-w-[70px] text-right") do
                  "#{@user[:xp]}/200 XP"
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
