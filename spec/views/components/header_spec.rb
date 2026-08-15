# frozen_string_literal: true

require "nokogiri"

RSpec.describe RegexDojo::Views::Components::Header do
  def render(xp: 0, streak: 1, belt: "Novato", dark: false)
    user = {xp: xp, belt: belt, streak: streak, session_id: "abcdefgh-1234"}
    Nokogiri::HTML.fragment(described_class.new(user: user, dark: dark).call)
  end

  it "computes the level from XP instead of trusting the stored belt column" do
    fragment = render(xp: 200, belt: "stale-label")

    expect(fragment.text).to include("Intermediário")
    expect(fragment.text).not_to include("stale-label")
  end

  it "shows cumulative XP against the BeltScale ceiling" do
    fragment = render(xp: 25)

    expect(fragment.text).to include("25/#{RegexDojo::BeltScale::MAX_XP} XP")
  end

  it "caps the XP bar at 100%" do
    fragment = render(xp: RegexDojo::BeltScale::MAX_XP + 500)

    expect(fragment.at_css("#xpbar")["style"]).to eq("width: 100%;")
  end

  it "pluralizes the streak chip in Portuguese" do
    expect(render(streak: 1).text).to include("1 dia")
    expect(render(streak: 3).text).to include("3 dias")
  end

  it "wires the dark-mode toggle with both icon states" do
    fragment = render

    expect(fragment.at_css('[data-controller="theme"]')).not_to be_nil
    expect(fragment.at_css('[data-theme-target="moonIcon"]')).not_to be_nil
    expect(fragment.at_css('[data-theme-target="sunIcon"]')).not_to be_nil
  end

  it "links the brand back to the home page" do
    brand = render.at_css('a[href="/"]')

    expect(brand).not_to be_nil
    expect(brand.text).to include("Regex Dojo")
  end
end
