# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Hud, type: :component do
  def hud_for(**overrides)
    described_class.new(user: build_user_presenter(**overrides))
  end

  it "renders the belt name capitalized in the badge" do
    fragment = render_fragment(hud_for(belt: "yellow"))

    expect(fragment.at_css("#hud-belt-badge").text.strip).to eq("Yellow Belt")
  end

  it "renders the XP label as current/limit" do
    fragment = render_fragment(hud_for(xp: 250))

    expect(fragment.at_css("#hud-xp-label").text.strip).to eq("250/520 XP")
  end

  it "sets the belt bar width proportional to XP" do
    fragment = render_fragment(hud_for(xp: 260))

    bar_style = fragment.at_css(".belt-bar")["style"]
    expect(bar_style).to eq("width: 50%;")
  end

  it "clamps the belt bar width at 100% when XP exceeds the limit" do
    fragment = render_fragment(hud_for(xp: 9999))

    bar_style = fragment.at_css(".belt-bar")["style"]
    expect(bar_style).to eq("width: 100%;")
  end

  it "applies a known style class for each defined belt" do
    fragment = render_fragment(hud_for(belt: "black"))

    badge_class = fragment.at_css("#hud-belt-badge")["class"]
    expect(badge_class).to include("text-dojo-violet")
  end

  it "falls back to the neutral style for an unrecognized belt" do
    fragment = render_fragment(hud_for(belt: "mystery"))

    badge_class = fragment.at_css("#hud-belt-badge")["class"]
    expect(badge_class).to include("text-dojo-slate", "bg-white")
  end

  it "shows a shortened session id" do
    fragment = render_fragment(hud_for(session_id: "abcdefgh-1234"))

    expect(fragment.text).to include("abcdefgh")
  end
end
