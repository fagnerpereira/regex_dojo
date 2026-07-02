# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Components
    module Screens
      class Profile < Phlex::HTML
        def initialize(user:)
          @user = user
        end

        def view_template
          render RegexDojo::Components::Ui::Card.new do
            div(class: "p-[30px] bg-gradient-to-br from-dojo-violet to-dojo-violet-dark text-white flex items-center gap-[18px]") do
              span(class: "w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold bg-gradient-to-br from-pink-400 to-pink-600 border-4 border-white/40") { @user.initials }
              div(class: "flex-1") do
                h3(class: "font-display text-[22px] font-extrabold") { "Warrior #{@user.session_id[0..5]}" }
                div(class: "text-[12.5px] opacity-85") { "#{@user.belt.capitalize} belt · Joined recently · 🔥 #{@user.streak} day streak" }
              end
            end
            div(class: "p-6") do
              div(class: "flex gap-3 mb-6") do
                stat_tile(@user.katas_solved.to_s, "text-dojo-violet", "Katas")
                stat_tile(@user.xp.to_s, "text-dojo-warning", "XP")
                stat_tile("#{@user.accuracy}%", "text-dojo-success", "Accuracy")
              end
              div(class: "text-xs font-bold text-dojo-slate mb-3") { "BADGES EARNED" }
              div(class: "flex gap-3 flex-wrap") do
                if @user.streak >= 1
                  badge("🔥", "Streak x#{@user.streak}", "bg-dojo-warning-bg")
                end
                if @user.accuracy >= 80
                  badge("🎯", "Sharpshooter", "bg-dojo-success-bg")
                end
                badge("⚡", "Speed demon", "bg-dojo-violet-light")
                badge("🧩", "Group guru", "bg-pink-100")
              end
            end
          end
        end

        def stat_tile(value, color, label)
          div(class: "flex-1 text-center p-4 bg-dojo-violet-wash rounded-xl") do
            div(class: "font-display text-2xl font-extrabold #{color}") { value }
            div(class: "text-[11px] text-dojo-slate font-semibold") { label }
          end
        end

        def badge(icon, label, bg_class)
          div(class: "text-center w-[76px]") do
            div(class: "w-14 h-14 mx-auto mb-1.5 rounded-2xl flex items-center justify-center text-[26px] #{bg_class}") { icon }
            div(class: "text-[10.5px] text-dojo-slate font-semibold") { label }
          end
        end
      end
    end
  end
end
