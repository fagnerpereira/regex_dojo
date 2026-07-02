# frozen_string_literal: true

require "phlex"
require "json"

module RegexDojo
  module Components
    module Screens
      class Tree < Phlex::HTML
        def initialize(user:, solved_kata_ids: [], katas: [])
          @user = user
          @solved_kata_ids = solved_kata_ids.map(&:to_s)
          @katas = katas
        end

        def view_template
          # Belt progress, shared by the belt road and the kata group list below
          belt_order = ["white", "yellow", "orange", "green", "black"]
          current_belt_idx = belt_order.index(@user.belt.to_s.downcase) || 0
          line_pct = (current_belt_idx.to_f / (belt_order.size - 1) * 100).round

          render RegexDojo::Components::Ui::Card.new(class: "p-9 bg-gradient-to-b from-dojo-violet-wash to-white") do
            div(class: "flex justify-between items-center mb-8") do
              h3(class: "font-display text-[22px] font-extrabold") { "Your belt path" }
              div(class: "flex gap-2") do
                solved_count = @solved_kata_ids.size
                total_count = @katas.size
                render RegexDojo::Components::Ui::Belt.new(color: "bg-dojo-success-bg text-dojo-success-text") { "#{solved_count}/#{total_count} Katas Solved" }
              end
            end

            # Belt road nodes
            div(class: "flex items-center justify-between relative mt-4 mb-8 overflow-x-auto pb-4") do
              div(class: "absolute top-[60px] left-[60px] right-[60px] h-1 bg-dojo-violet-border rounded z-0")

              div(class: "absolute top-[60px] left-[60px] h-1 bg-gradient-to-r from-dojo-success to-dojo-violet rounded z-0 transition-all duration-1000", style: "width: #{line_pct}%;")

              # Render 5 nodes dynamically
              node_state("🥋", "White", 0, current_belt_idx)
              node_state("🥋", "Yellow", 1, current_belt_idx)
              node_state("🥋", "Orange", 2, current_belt_idx)
              node_state("🥋", "Green", 3, current_belt_idx)
              node_state("🖤", "Black", 4, current_belt_idx)
            end

            # Katas list grouped by belt
            div(class: "mt-12") do
              h4(class: "font-display text-[18px] font-extrabold mb-6") { "🥋 Select a challenge to train" }

              div(class: "flex flex-col gap-8") do
                belt_groups = [
                  {name: "White Belt Challenges", difficulty: "Easy", index_range: 0..2},
                  {name: "Yellow Belt Challenges", difficulty: "Easy", index_range: 3..5},
                  {name: "Orange Belt Challenges", difficulty: "Medium", index_range: 6..8},
                  {name: "Green Belt Challenges", difficulty: "Medium", index_range: 9..11},
                  {name: "Black Belt Challenges", difficulty: "Hard", index_range: 12..14}
                ]

                belt_groups.each_with_index do |group, g_idx|
                  is_belt_locked = g_idx > current_belt_idx

                  div(class: "flex flex-col gap-3 #{"opacity-50" if is_belt_locked}") do
                    div(class: "flex items-center gap-2 mb-1") do
                      span(class: "font-display text-sm font-bold text-dojo-slate") { group[:name] }
                      if is_belt_locked
                        span(class: "text-[11px] bg-dojo-violet-border text-dojo-slate px-2 py-0.5 rounded-full font-mono") { "Locked" }
                      else
                        span(class: "text-[11px] bg-dojo-success-bg text-dojo-success-text px-2 py-0.5 rounded-full font-mono") { "Unlocked" }
                      end
                    end

                    div(class: "grid grid-cols-1 md:grid-cols-3 gap-4") do
                      group_katas = @katas[group[:index_range]] || []
                      group_katas.each_with_index do |kata, k_idx|
                        next unless kata
                        solved = @solved_kata_ids.include?(kata[:id].to_s)

                        # Render kata button
                        button(
                          class: "w-full text-left p-4.5 rounded-[18px] border-2 transition-all duration-150 flex flex-col justify-between min-h-[120px] #{
                            if solved
                              "border-dojo-success-bg bg-dojo-success-bg/10 hover:bg-dojo-success-bg/20"
                            else
                              is_belt_locked ? "border-dojo-violet-border bg-white cursor-not-allowed" :
                                                          "border-dojo-violet-border bg-white hover:border-dojo-violet hover:bg-dojo-violet-wash cursor-pointer"
                            end
                          }",
                          disabled: is_belt_locked,
                          data: {
                            action: is_belt_locked ? nil : "click->dojo#selectKata click->tabs#switch",
                            tab: is_belt_locked ? nil : "lesson",
                            dojo_target: "kataButton",
                            kata_id: kata[:id],
                            kata_title: kata[:title],
                            kata_concept: kata[:concept],
                            kata_lesson: kata[:lesson],
                            kata_test_string: kata[:test_string],
                            kata_task: kata[:task],
                            kata_hint: kata[:hint],
                            kata_xp: kata[:xp],
                            kata_solved: solved.to_s,
                            kata_test_cases: kata[:test_cases].to_json
                          }
                        ) do
                          div do
                            div(class: "flex justify-between items-start mb-1") do
                              span(class: "text-[11px] text-dojo-slate font-mono") { "Kata #{group[:index_range].first + k_idx + 1}" }
                              span(class: "text-[11.5px] font-mono text-dojo-warning-text font-bold") { "+#{kata[:xp]} XP" }
                            end
                            h5(class: "font-display text-[15px] font-extrabold text-dojo-ink") { kata[:title] }
                          end

                          div(class: "flex justify-between items-center mt-3") do
                            span(class: "text-[11px] text-dojo-slate") { kata[:concept] }
                            if solved
                              span(class: "text-xs font-bold text-dojo-success") { "✓ Solved" }
                            elsif is_belt_locked
                              span(class: "text-xs font-semibold text-dojo-slate") { "🔒 Locked" }
                            else
                              span(class: "text-xs font-bold text-dojo-violet") { "▶ Play" }
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        private

        def node_state(icon, name, node_idx, current_belt_idx)
          if node_idx < current_belt_idx
            # Done
            node(icon, name, "bg-white border-4 border-dojo-success text-dojo-success-text shadow-sm", "bg-dojo-success-bg text-dojo-success-text", "✓ Done")
          elsif node_idx == current_belt_idx
            # Active
            node(icon, name, "bg-gradient-to-br from-violet-500 to-dojo-violet-dark text-white shadow-card border-4 border-transparent", "bg-dojo-violet-light text-dojo-violet", "▶ Now")
          else
            # Locked
            node("🔒", name, "bg-dojo-violet-light border-4 border-dojo-violet-border text-dojo-slate", "bg-dojo-violet-border text-dojo-slate", "Locked")
          end
        end

        def node(icon, name, node_class, pill_class, pill_text)
          div(class: "relative z-10 flex flex-col items-center gap-2.5 shrink-0") do
            div(class: "w-[120px] h-[120px] rounded-[26px] flex flex-col items-center justify-center gap-1 font-bold relative #{node_class}") do
              span(class: "text-[30px]") { icon }
              span(class: "text-[11px]") { name }
            end
            render RegexDojo::Components::Ui::Pill.new(bg: pill_class.split(" ")[0], text: pill_class.split(" ")[1]) { pill_text }
          end
        end
      end
    end
  end
end
