# frozen_string_literal: true

require "spec_helper"

RSpec.describe RegexDojo::Views::Components::Hud do
  let(:user) do
    {xp: 150, belt: "white", streak: 3, session_id: "abcd1234-0000-0000-0000-000000000000"}
  end

  it "renders the HUD bar with the user's stats" do
    html = described_class.new(user: user).call

    expect(html).to include('id="hud-bar"')
    expect(html).to include("White Belt")
    expect(html).to include("150/200 XP")
    expect(html).to include("3 Day Streak")
  end

  it "does not fall back to Phlex's missing-view_template warning" do
    html = described_class.new(user: user).call

    expect(html).not_to include("Phlex Warning")
  end
end
