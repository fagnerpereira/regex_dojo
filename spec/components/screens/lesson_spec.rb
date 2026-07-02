# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Screens::Lesson, type: :component do
  # dojo_controller.js reads these via this.<name>Target — if a target is
  # renamed here without updating the controller, Stimulus raises at runtime
  # with no test ever catching it. These assertions are the guardrail.
  let(:required_dojo_targets) do
    %w[concept title xpBadge lesson task hintText highlightArea patternInput errorBanner testCasesList]
  end

  it "exposes every Stimulus target dojo_controller.js depends on" do
    fragment = render_fragment(described_class.new)

    required_dojo_targets.each do |target|
      expect(fragment.at_css(%([data-dojo-target="#{target}"]))).not_to be_nil,
        "expected a [data-dojo-target=\"#{target}\"] element"
    end
  end

  it "wires the hint button to the dojo#revealHint action" do
    fragment = render_fragment(described_class.new)

    button = fragment.at_css('[data-action="click->dojo#revealHint"]')
    expect(button).not_to be_nil
  end

  it "wires the pattern input to the dojo#evaluatePattern action" do
    fragment = render_fragment(described_class.new)

    input = fragment.at_css('[data-dojo-target="patternInput"]')
    expect(input["data-action"]).to eq("input->dojo#evaluatePattern")
  end

  it "wires the submit button to the dojo#submit action" do
    fragment = render_fragment(described_class.new)

    button = fragment.at_css('[data-action="click->dojo#submit"]')
    expect(button).not_to be_nil
    expect(button.text).to include("Submit Pattern")
  end
end
