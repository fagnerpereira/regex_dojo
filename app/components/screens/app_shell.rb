# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Components
    module Screens
      class AppShell < Phlex::HTML
        def initialize(user:, top_users: [], challenges: [], solved_kata_ids: [])
          @user = user
          @top_users = top_users
          @challenges = challenges
          @solved_kata_ids = solved_kata_ids
        end

        def view_template
          # Entire SPA is controlled by tabs and dojo controllers
          div(
            class: "flex-grow flex flex-col min-h-screen",
            data: {controller: "tabs dojo"}
          ) do
            # 1. Global Header (Sticky navigation)
            header(
              id: "global-header",
              class: "sticky top-0 z-50 bg-white/85 backdrop-blur-md border-b border-dojo-violet-border py-4 px-8 shadow-sm transition-all duration-300"
            ) do
              div(class: "max-w-[1240px] mx-auto flex items-center justify-between") do
                div(class: "flex items-center gap-7") do
                  div(class: "flex items-center gap-2.5 font-display font-extrabold text-lg cursor-pointer", data: {action: "click->tabs#switch", tab: "home"}) do
                    span(class: "w-8.5 h-8.5 rounded-xl bg-gradient-to-br from-violet-500 to-dojo-violet-dark text-white flex items-center justify-center font-display shadow-sm") { "道" }
                    plain "RegexDojo"
                  end

                  nav(class: "flex gap-1") do
                    button(
                      class: "tab-btn text-sm font-semibold px-3.5 py-2 rounded-xl text-dojo-slate hover:bg-dojo-violet-light hover:text-dojo-violet cursor-pointer border-0 transition-all",
                      data: {action: "click->tabs#switch", tabs_target: "tab", tab: "home"}
                    ) { "Dojo" }

                    button(
                      class: "tab-btn text-sm font-semibold px-3.5 py-2 rounded-xl text-dojo-slate hover:bg-dojo-violet-light hover:text-dojo-violet cursor-pointer border-0 transition-all",
                      data: {action: "click->tabs#switch", tabs_target: "tab", tab: "challenges"}
                    ) { "Challenges" }

                    button(
                      class: "tab-btn text-sm font-semibold px-3.5 py-2 rounded-xl text-dojo-slate hover:bg-dojo-violet-light hover:text-dojo-violet cursor-pointer border-0 transition-all",
                      data: {action: "click->tabs#switch", tabs_target: "tab", tab: "playground"}
                    ) { "Playground" }

                    button(
                      class: "tab-btn text-sm font-semibold px-3.5 py-2 rounded-xl text-dojo-slate hover:bg-dojo-violet-light hover:text-dojo-violet cursor-pointer border-0 transition-all",
                      data: {action: "click->tabs#switch", tabs_target: "tab", tab: "leaderboard"}
                    ) { "Leaderboard" }
                  end
                end

                div(class: "flex items-center gap-3.5") do
                  span(class: "flex items-center gap-1.5 bg-orange-50 text-orange-700 font-bold text-sm px-3 py-1.5 rounded-xl border border-orange-200 shadow-sm") { "🔥 #{@user.streak} day streak" }

                  button(
                    class: "w-9 h-9 rounded-full bg-gradient-to-br from-pink-400 to-pink-600 text-white font-bold text-sm flex items-center justify-center cursor-pointer border-0 shadow-md hover:scale-105 transition-all",
                    data: {action: "click->tabs#switch", tabs_target: "tab", tab: "profile"}
                  ) do
                    @user.initials
                  end
                end
              end
            end

            # 2. Global HUD Bar (Progress feedback)
            div(
              id: "global-hud",
              class: "max-w-[1240px] mx-auto w-full px-8 mt-6 transition-all duration-300"
            ) do
              render RegexDojo::Components::Hud.new(user: @user)
            end

            # 3. Main SPA Panels Container
            main(class: "max-w-[1240px] mx-auto w-full px-8 py-6 flex-grow flex flex-col justify-start") do
              # A. Onboarding Panel
              div(
                class: "panel-hidden w-full flex justify-center py-4",
                data: {tabs_target: "panel", tab: "onboarding"}
              ) do
                render RegexDojo::Components::Screens::Onboarding.new
              end

              # B. Home/Dashboard Panel
              div(
                class: "panel-hidden w-full",
                data: {tabs_target: "panel", tab: "home"}
              ) do
                render RegexDojo::Components::Screens::Home.new(user: @user)
              end

              # C. Challenges/Tree Path Panel
              div(
                class: "panel-hidden w-full",
                data: {tabs_target: "panel", tab: "challenges"}
              ) do
                render RegexDojo::Components::Screens::Tree.new(
                  user: @user,
                  solved_kata_ids: @solved_kata_ids,
                  katas: @challenges
                )
              end

              # D. Lesson/Interactive Arena Panel
              div(
                class: "panel-hidden w-full",
                data: {tabs_target: "panel", tab: "lesson"}
              ) do
                render RegexDojo::Components::Screens::Lesson.new
              end

              # E. Regex Playground Panel
              div(
                class: "panel-hidden w-full",
                data: {tabs_target: "panel", tab: "playground"}
              ) do
                render RegexDojo::Components::Screens::Playground.new
              end

              # F. Leaderboard Panel
              div(
                class: "panel-hidden w-full",
                data: {tabs_target: "panel", tab: "leaderboard"}
              ) do
                render RegexDojo::Components::Screens::Leaderboard.new(
                  top_users: @top_users,
                  current_user: @user
                )
              end

              # G. Profile Panel
              div(
                class: "panel-hidden max-w-md mx-auto w-full",
                data: {tabs_target: "panel", tab: "profile"}
              ) do
                render RegexDojo::Components::Screens::Profile.new(user: @user)
              end
            end
          end
        end
      end
    end
  end
end
