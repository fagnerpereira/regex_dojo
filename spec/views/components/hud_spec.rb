# frozen_string_literal: true

require "nokogiri"

RSpec.describe RegexDojo::Views::Components::Hud do
  def render(xp:, belt:)
    user = {xp: xp, belt: belt, streak: 3, session_id: "abcdefgh-1234"}
    Nokogiri::HTML.fragment(described_class.new(user: user).call)
  end

  it "shows the XP ceiling from BeltScale, not a literal of its own" do
    fragment = render(xp: 25, belt: "white")

    expect(fragment.text).to include("25/#{RegexDojo::BeltScale::MAX_XP} XP")
  end

  it "fills the bar completely only at the top belt" do
    fragment = render(xp: RegexDojo::BeltScale::MAX_XP, belt: "black")

    expect(fragment.at_css(".belt-bar")["style"]).to eq("width: 100%;")
  end

  it "does not overflow past 100% when XP exceeds the top belt" do
    fragment = render(xp: RegexDojo::BeltScale::MAX_XP + 500, belt: "black")

    expect(fragment.at_css(".belt-bar")["style"]).to eq("width: 100%;")
  end

  it "renders the user's current belt name" do
    fragment = render(xp: 200, belt: "orange")

    expect(fragment.text).to include("Orange Belt")
  end
end
