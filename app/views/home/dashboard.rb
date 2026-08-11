# frozen_string_literal: true

require "phlex"
require "json"

module RegexDojo
  module Views
    module Home
      class Dashboard < Phlex::HTML
        def initialize(user:, solved_kata_ids: [], challenges: [], blitz_challenges: [], last_patterns: {}, ruby_track: {})
          @user = user
          @solved_kata_ids = solved_kata_ids
          @challenges = challenges
          @blitz_challenges = blitz_challenges
          @last_patterns = last_patterns
          @ruby_track = ruby_track
        end

        def view_template
          # Tabs controller wraps the entire dashboard
          div(class: "flex-1 flex flex-col", data: {controller: "tabs"}) do
            # HUD Bar
            render Views::Components::Hud.new(user: @user)

            # Tab Navigation
            div(class: "max-w-7xl mx-auto w-full px-4 sm:px-6 pt-6") do
              div(class: "flex items-center gap-2 flex-wrap") do
                button(class: "tab-btn active", data: {action: "click->tabs#switch", tabs_target: "tab", tab: "dojo"}) { "🥋 Dojo" }
                button(class: "tab-btn", data: {action: "click->tabs#switch", tabs_target: "tab", tab: "ruby"}) { "💎 Ruby" }
                button(class: "tab-btn", data: {action: "click->tabs#switch", tabs_target: "tab", tab: "sandbox"}) { "🧪 Sandbox" }
                button(class: "tab-btn", data: {action: "click->tabs#switch", tabs_target: "tab", tab: "blitz"}) { "⚡ Blitz" }
                button(class: "tab-btn", data: {action: "click->tabs#switch", tabs_target: "tab", tab: "codex"}) { "📖 Codex" }
              end
            end

            # Content Panels
            div(class: "max-w-7xl mx-auto w-full px-4 sm:px-6 py-6 flex-1") do
              # Dojo Panel
              div(data: {tabs_target: "panel", tab: "dojo"}) do
                render Views::Components::DojoPanel.new(user: @user, solved_kata_ids: @solved_kata_ids, katas: @challenges, last_patterns: @last_patterns)
              end

              # Ruby Panel — one server-selected challenge
              div(class: "panel-hidden", data: {tabs_target: "panel", tab: "ruby"}) do
                render Views::Components::RubyPanel.new(
                  challenge: @ruby_track[:challenge],
                  solved_count: @ruby_track[:solved_count].to_i,
                  total_count: @ruby_track[:total_count].to_i
                )
              end

              # Sandbox Panel
              div(class: "panel-hidden", data: {tabs_target: "panel", tab: "sandbox"}) do
                render Views::Components::SandboxPanel.new
              end

              # Blitz Panel
              div(class: "panel-hidden", data: {tabs_target: "panel", tab: "blitz"}) do
                render Views::Components::BlitzPanel.new(katas: @blitz_challenges)
              end

              # Codex Panel
              div(class: "panel-hidden", data: {tabs_target: "panel", tab: "codex"}) do
                render Views::Components::CodexPanel.new
              end
            end
          end
        end
      end
    end
  end
end
