# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Screens::Home, type: :component do
  it "shows the user's streak, XP, katas solved, accuracy, and rank" do
    user = build_user_presenter(streak: 7, xp: 240, katas_solved: 9, accuracy: 88, rank: 3)
    fragment = render_fragment(described_class.new(user: user))

    expect(fragment.text).to include("🔥 7 day streak")
    expect(fragment.text).to include("240")
    expect(fragment.text).to include("9")
    expect(fragment.text).to include("88%")
    expect(fragment.text).to include("#3")
  end

  it "derives the avatar initials from the session id" do
    user = build_user_presenter(session_id: "ab-something")
    fragment = render_fragment(described_class.new(user: user))

    button = fragment.at_css('[data-tab="profile"]')
    expect(button.text.strip).to eq("AB")
  end

  it "renders the belt progress percentage" do
    user = build_user_presenter(belt_percent: 42)
    fragment = render_fragment(described_class.new(user: user))

    expect(fragment.text).to include("42%")
  end
end
