# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Screens::Profile, type: :component do
  it "shows the warrior name derived from the session id and the belt" do
    user = build_user_presenter(session_id: "abcdef123456", belt: "green")
    fragment = render_fragment(described_class.new(user: user))

    expect(fragment.text).to include("Warrior abcdef")
    expect(fragment.text).to include("Green belt")
  end

  it "shows katas solved, XP, and accuracy stats" do
    user = build_user_presenter(katas_solved: 5, xp: 300, accuracy: 90)
    fragment = render_fragment(described_class.new(user: user))

    expect(fragment.text).to include("5")
    expect(fragment.text).to include("300")
    expect(fragment.text).to include("90%")
  end

  it "shows the streak badge only when the streak is at least 1" do
    with_streak = render_fragment(described_class.new(user: build_user_presenter(streak: 3)))
    without_streak = render_fragment(described_class.new(user: build_user_presenter(streak: 0)))

    expect(with_streak.text).to include("Streak x3")
    expect(without_streak.text).not_to include("Streak x0")
  end

  it "shows the sharpshooter badge only when accuracy is at least 80%" do
    accurate = render_fragment(described_class.new(user: build_user_presenter(accuracy: 95)))
    inaccurate = render_fragment(described_class.new(user: build_user_presenter(accuracy: 50)))

    expect(accurate.text).to include("Sharpshooter")
    expect(inaccurate.text).not_to include("Sharpshooter")
  end
end
