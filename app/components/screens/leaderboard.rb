# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Components
    module Screens
      class Leaderboard < Phlex::HTML
        def initialize(top_users:, current_user:)
          @top_users = top_users
          @current_user = current_user
        end

        def view_template
          render RegexDojo::Components::Ui::Card.new do
            div(class: "px-7 py-6 border-b border-dojo-violet-border flex justify-between items-center") do
              h3(class: "font-display text-lg font-extrabold") { "🏆 Weekly leaderboard" }
              div(class: "flex gap-1.5") do
                render RegexDojo::Components::Ui::Pill.new(bg: "bg-dojo-violet", text: "text-white") { "All-time" }
              end
            end
            div(class: "p-5 flex flex-col gap-2") do
              @top_users.each_with_index do |u, idx|
                is_you = u.id == @current_user.id
                initials = u.session_id[0..1].upcase
                belt_info = "#{u.belt.capitalize} Belt"

                rank_emoji = case idx
                when 0 then "🥇"
                when 1 then "🥈"
                when 2 then "🥉"
                else (idx + 1).to_s
                end

                row_bg = is_you ? "bg-white border-2 border-dojo-violet" : "bg-dojo-violet-wash"
                text_color = is_you ? "text-dojo-violet" : "text-dojo-slate"
                avatar_bg = is_you ? "bg-gradient-to-br from-pink-400 to-pink-600" : "bg-gradient-to-br from-slate-400 to-slate-600"

                rank_row(rank_emoji, initials, avatar_bg, is_you ? "You (Warrior)" : "Warrior #{u.session_id[0..3]}", belt_info, row_bg, text_color, "#{u.xp} XP", is_you)
              end
            end
          end
        end

        def rank_row(rank, initials, avatar_bg, name, belt_info, row_bg, text_color, xp, is_you)
          rank_class = is_you ? "text-[15px] font-extrabold #{text_color}" : "text-[18px]"
          rank_class = "text-[20px]" if rank == "🥇"

          div(class: "flex items-center gap-3.5 p-3.5 rounded-xl #{row_bg}") do
            span(class: "w-7 text-center #{rank_class}") { rank }
            span(class: "w-9 h-9 rounded-full flex items-center justify-center text-white font-bold text-[14px] #{avatar_bg}") { initials }
            div(class: "flex-1") do
              div(class: "font-bold text-[14px]") { name }
              div(class: "text-[11.5px] font-semibold #{text_color}") { belt_info }
            end
            span(class: "font-display font-extrabold #{text_color}") { xp }
          end
        end
      end
    end
  end
end
