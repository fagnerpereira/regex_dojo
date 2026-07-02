# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Ui::Card, type: :component do
  it "renders the base card shell classes and block content" do
    fragment = render_fragment(described_class.new { "Card body" })

    div = fragment.at_css("div")
    expect(div["class"]).to include("bg-white", "rounded-card", "shadow-card")
    expect(div.text.strip).to eq("Card body")
  end

  it "defaults to full width when no max width is given" do
    fragment = render_fragment(described_class.new { "" })

    expect(fragment.at_css("div")["class"]).to include("w-full")
  end

  it "constrains width when max_w is given" do
    fragment = render_fragment(described_class.new(max_w: "max-w-[560px]") { "" })

    expect(fragment.at_css("div")["class"]).to include("max-w-[560px]", "flex-1")
  end

  it "passes through extra attributes like data-controller" do
    fragment = render_fragment(described_class.new(data: {controller: "regex-playground"}) { "" })

    expect(fragment.at_css("div")["data-controller"]).to eq("regex-playground")
  end
end
