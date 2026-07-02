# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Screens::AppShell, type: :component do
  def shell_for(**overrides)
    user = overrides.delete(:user) || build_user_presenter
    described_class.new(user: user, **overrides)
  end

  it "renders the global HUD for the current user" do
    fragment = render_fragment(shell_for(user: build_user_presenter(xp: 200)))

    expect(fragment.at_css("#hud-bar")).not_to be_nil
    expect(fragment.at_css("#hud-xp-label").text).to include("200")
  end

  it "shows the user's streak and initials in the header" do
    user = build_user_presenter(streak: 4, initials: "ZZ")
    fragment = render_fragment(shell_for(user: user))

    expect(fragment.text).to include("🔥 4 day streak")
    expect(fragment.at_css('[data-tab="profile"]').text.strip).to eq("ZZ")
  end

  it "renders every SPA panel with its tab hook" do
    fragment = render_fragment(shell_for)

    %w[onboarding home challenges lesson playground leaderboard profile].each do |tab|
      panel = fragment.at_css(%([data-tabs-target="panel"][data-tab="#{tab}"]))
      expect(panel).not_to be_nil, "expected a panel for tab \"#{tab}\""
    end
  end

  it "passes challenges through to the tree/challenges panel" do
    katas = [build_kata(id: "7", title: "Passed-through kata")]
    fragment = render_fragment(shell_for(challenges: katas, solved_kata_ids: []))

    button = fragment.at_css('[data-kata-id="7"]')
    expect(button).not_to be_nil
    expect(button["data-kata-title"]).to eq("Passed-through kata")
  end
end
