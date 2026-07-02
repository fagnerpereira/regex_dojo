# frozen_string_literal: true

RSpec.describe RegexDojo::Components::Screens::Playground, type: :component do
  # regex_playground_controller.js reads these via this.<name>Target — same
  # drift risk as the Lesson screen's dojo_controller.js targets.
  let(:required_targets) do
    %w[flags pattern flagsLabel error testString preview matchBadge matchList successBanner]
  end

  it "declares the regex-playground Stimulus controller on its root" do
    fragment = render_fragment(described_class.new)

    expect(fragment.at_css('[data-controller="regex-playground"]')).not_to be_nil
  end

  it "exposes every Stimulus target regex_playground_controller.js depends on" do
    fragment = render_fragment(described_class.new)

    required_targets.each do |target|
      expect(fragment.at_css(%([data-regex-playground-target="#{target}"]))).not_to be_nil,
        "expected a [data-regex-playground-target=\"#{target}\"] element"
    end
  end

  it "wires the pattern input to run on input" do
    fragment = render_fragment(described_class.new)

    input = fragment.at_css('[data-regex-playground-target="pattern"]')
    expect(input["data-action"]).to eq("input->regex-playground#run")
  end

  it "wires the reset button to the reset action" do
    fragment = render_fragment(described_class.new)

    expect(fragment.at_css('[data-action="regex-playground#reset"]')).not_to be_nil
  end

  it "wires each flag toggle to the toggleFlag action" do
    fragment = render_fragment(described_class.new)

    toggles = fragment.css('[data-action="click->regex-playground#toggleFlag"]')
    expect(toggles).not_to be_empty
  end
end
