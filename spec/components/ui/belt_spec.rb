# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Ui::Belt, type: :component do
  it "renders the block content" do
    fragment = render_fragment(described_class.new { "🟡 Yellow belt" })

    expect(fragment.text.strip).to eq("🟡 Yellow belt")
  end

  it "applies the given color classes" do
    fragment = render_fragment(described_class.new(color: "bg-amber-100 text-amber-700") { "Yellow" })

    expect(fragment.at_css("span")["class"]).to include("bg-amber-100", "text-amber-700")
  end

  it "falls back to the default violet color when none is given" do
    fragment = render_fragment(described_class.new { "Default" })

    expect(fragment.at_css("span")["class"]).to include("bg-dojo-violet-light", "text-dojo-violet-dark")
  end
end
