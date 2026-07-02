# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Ui::Button, type: :component do
  it "defaults to the primary variant" do
    fragment = render_fragment(described_class.new { "Go" })

    expect(fragment.at_css("button")["class"]).to include("bg-dojo-violet", "shadow-btn-primary")
  end

  it "applies the requested variant's classes" do
    fragment = render_fragment(described_class.new(variant: :ghost) { "Cancel" })

    expect(fragment.at_css("button")["class"]).to include("bg-dojo-violet-light")
  end

  it "raises for an unknown variant instead of silently rendering unstyled" do
    expect {
      render_fragment(described_class.new(variant: :nonexistent) { "Broken" })
    }.to raise_error(KeyError)
  end

  it "adds the full-width class only when requested" do
    full = render_fragment(described_class.new(full_width: true) { "Wide" })
    normal = render_fragment(described_class.new(full_width: false) { "Normal" })

    expect(full.at_css("button")["class"]).to include("w-full")
    expect(normal.at_css("button")["class"]).not_to include("w-full")
  end

  it "passes through extra attributes like data-action" do
    fragment = render_fragment(described_class.new(data: {action: "click->tabs#switch"}) { "Switch" })

    expect(fragment.at_css("button")["data-action"]).to eq("click->tabs#switch")
  end
end
