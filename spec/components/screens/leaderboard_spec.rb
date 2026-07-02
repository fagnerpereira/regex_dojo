# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Screens::Leaderboard, type: :component do
  it "labels the current user's own row distinctly" do
    me = build_leaderboard_user(id: 1, xp: 500)
    other = build_leaderboard_user(id: 2, session_id: "22222222", xp: 300)

    fragment = render_fragment(described_class.new(top_users: [me, other], current_user: me))

    expect(fragment.text).to include("You (Warrior)")
  end

  it "shows medal emoji for the top 3 ranks and numeric rank after that" do
    users = (1..4).map { |i| build_leaderboard_user(id: i, session_id: "user#{i}00", xp: 500 - i) }
    fragment = render_fragment(described_class.new(top_users: users, current_user: users.first))

    expect(fragment.text).to include("🥇")
    expect(fragment.text).to include("🥈")
    expect(fragment.text).to include("🥉")
    expect(fragment.text).to include("4")
  end

  it "shows each user's XP and belt" do
    me = build_leaderboard_user(id: 1, belt: "green", xp: 265)
    fragment = render_fragment(described_class.new(top_users: [me], current_user: me))

    expect(fragment.text).to include("265 XP")
    expect(fragment.text).to include("Green Belt")
  end
end
