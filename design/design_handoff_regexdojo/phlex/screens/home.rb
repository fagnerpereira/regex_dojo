module Screens
  # Home / Dashboard — worked example translating the design's inline styles
  # into Tailwind, using the shared UI:: components.
  class Home < Phlex::HTML
    def initialize(user:)
      @user = user # expects xp, katas_solved, accuracy, rank, belt_percent, streak_days
    end

    def view_template
      render UI::Card.new do
        topbar
        div(class: "p-7 bg-dojo-violet-wash") do
          hero_row
          stats_row
          continue_panel
        end
      end
    end

    private

    def topbar
      div(class: "flex items-center justify-between h-[66px] px-6 bg-white border-b border-dojo-violet-border") do
        div(class: "flex items-center gap-7") do
          div(class: "flex items-center gap-2.5 font-display font-extrabold text-lg") do
            span(class: "w-8.5 h-8.5 rounded-xl bg-gradient-to-br from-violet-500 to-dojo-violet-dark text-white flex items-center justify-center font-display") { plain "道" }
            plain "RegexDojo"
          end
          nav(class: "flex gap-1") do
            a(href: "/dojo", class: "text-sm font-semibold px-3.5 py-2 rounded-xl bg-dojo-violet text-white") { "Dojo" }
            a(href: "/playground", class: "text-sm font-semibold px-3.5 py-2 rounded-xl text-dojo-slate hover:bg-dojo-violet-light hover:text-dojo-violet") { "Playground" }
            a(href: "/challenges", class: "text-sm font-semibold px-3.5 py-2 rounded-xl text-dojo-slate hover:bg-dojo-violet-light hover:text-dojo-violet") { "Challenges" }
            a(href: "/leaderboard", class: "text-sm font-semibold px-3.5 py-2 rounded-xl text-dojo-slate hover:bg-dojo-violet-light hover:text-dojo-violet") { "Leaderboard" }
          end
        end
        div(class: "flex items-center gap-3.5") do
          span(class: "flex items-center gap-1.5 bg-orange-50 text-orange-700 font-bold text-sm px-3 py-1.5 rounded-xl border border-orange-200") { "🔥 #{@user.streak_days} day streak" }
          span(class: "w-9 h-9 rounded-full bg-gradient-to-br from-pink-400 to-pink-600 text-white font-bold text-sm flex items-center justify-center") { @user.initials }
        end
      end
    end

    def hero_row
      div(class: "flex gap-5 mb-5") do
        # Daily kata — violet gradient hero card
        div(class: "flex-[1.6] rounded-[22px] p-7 bg-gradient-to-br from-dojo-violet to-dojo-violet-dark text-white relative overflow-hidden") do
          render UI::Pill.new(bg: "bg-white/20", text: "text-white") { "☀️ DAILY KATA" }
          h3(class: "font-display text-2xl font-extrabold mt-4 mb-2 max-w-sm") { "Match every valid hex color code" }
          p(class: "text-sm opacity-85 mb-5 max-w-sm") { "Handle #fff and #ffffff, reject bad ones. +150 XP if you nail it first try." }
          render UI::Button.new(variant: "on-white") { "Start today's kata →" }
          div(class: "font-display absolute -right-2.5 -bottom-6 text-[130px] opacity-10 select-none") { "忍" }
        end
        # Belt progress ring
        div(class: "flex-1 rounded-[22px] p-6 bg-white border border-dojo-violet-border flex flex-col items-center justify-center text-center") do
          div(class: "relative w-[120px] h-[120px] mb-3") do
            # progress ring — render as inline SVG, percent from @user.belt_percent
            svg(viewBox: "0 0 120 120", class: "w-[120px] h-[120px] -rotate-90") do |s|
              s.circle(cx: "60", cy: "60", r: "52", fill: "none", stroke: "#f0ebfa", "stroke-width": "12")
              s.circle(cx: "60", cy: "60", r: "52", fill: "none", stroke: "#22c55e", "stroke-width": "12",
                "stroke-linecap": "round", "stroke-dasharray": "327",
                "stroke-dashoffset": (327 * (1 - @user.belt_percent / 100.0)).to_s)
            end
            div(class: "absolute inset-0 flex flex-col items-center justify-center") do
              span(class: "font-display text-3xl font-extrabold") { "#{@user.belt_percent}%" }
              span(class: "text-[11px] text-dojo-slate font-semibold") { "Green belt" }
            end
          end
          p(class: "text-xs text-dojo-slate") {
            plain "14 of 20 katas to "
            strong(class: "text-dojo-ink") { "Blue belt" }
          }
        end
      end
    end

    def stats_row
      div(class: "flex gap-4 mb-5") do
        stat_tile("Total XP", @user.xp, "text-dojo-violet")
        stat_tile("Katas solved", @user.katas_solved, "text-amber-500")
        stat_tile("Accuracy", "#{@user.accuracy}%", "text-green-500")
        stat_tile("World rank", "##{@user.rank}", "text-pink-500")
      end
    end

    def stat_tile(label, value, color_class)
      div(class: "flex-1 bg-white border border-dojo-violet-border rounded-2xl p-5") do
        div(class: "text-xs text-dojo-slate font-semibold mb-1.5") { label }
        div(class: "font-display text-[28px] font-extrabold #{color_class}") { value.to_s }
      end
    end

    def continue_panel
      div(class: "bg-white border border-dojo-violet-border rounded-[20px] p-6") do
        div(class: "flex justify-between items-center mb-4") do
          h4(class: "font-display text-lg font-bold") { "Continue your path" }
          a(href: "/challenges", class: "text-sm text-dojo-violet font-bold no-underline") { "View all →" }
        end
        div(class: "flex gap-3.5") do
          # done / in-progress / locked — see full markup pattern in the design reference;
          # in Rails this loops @user.topics, switching pill + bar color on topic.status
        end
      end
    end
  end
end
