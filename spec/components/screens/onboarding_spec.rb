# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Screens::Onboarding, type: :component do
  it "welcomes the user and offers the training CTA" do
    fragment = render_fragment(described_class.new)

    expect(fragment.text).to include("Welcome to the Dojo")
    expect(fragment.text).to include("Begin training")
  end

  it "presents all three starting-level options" do
    fragment = render_fragment(described_class.new)

    expect(fragment.text).to include("Brand new")
    expect(fragment.text).to include("I know the basics")
    expect(fragment.text).to include("Regex veteran")
  end

  it "wires both CTA buttons to complete onboarding" do
    fragment = render_fragment(described_class.new)

    buttons = fragment.css('[data-action="click->tabs#completeOnboarding"]')
    expect(buttons.size).to eq(2)
  end
end
