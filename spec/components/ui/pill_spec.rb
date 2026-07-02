# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Ui::Pill, type: :component do
  it "renders the block content with the given background and text classes" do
    fragment = render_fragment(described_class.new(bg: "bg-dojo-success-bg", text: "text-dojo-success-text") { "✓ Done" })

    span = fragment.at_css("span")
    expect(span.text.strip).to eq("✓ Done")
    expect(span["class"]).to include("bg-dojo-success-bg", "text-dojo-success-text")
  end

  it "falls back to the default violet colors when none are given" do
    fragment = render_fragment(described_class.new { "Default" })

    expect(fragment.at_css("span")["class"]).to include("bg-dojo-violet-light", "text-dojo-violet-dark")
  end

  it "passes through extra attributes like data targets" do
    fragment = render_fragment(described_class.new(data: {dojo_target: "xpBadge"}) { "+25 XP" })

    expect(fragment.at_css("span")["data-dojo-target"]).to eq("xpBadge")
  end
end
