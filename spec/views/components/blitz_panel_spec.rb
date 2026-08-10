# frozen_string_literal: true

require "spec_helper"

RSpec.describe RegexDojo::Views::Components::BlitzPanel do
  let(:kata) do
    {
      id: "1", title: "Literal", concept: "Basics", test_string: "abc",
      task: "match abc", hint: "type abc", xp: 25,
      test_cases: [{input: "abc", should_match: true, expected_match: "abc"}]
    }
  end

  it "embeds the katas as JSON for the blitz controller" do
    html = described_class.new(katas: [kata]).call

    expect(html).to include('id="blitz-katas-data"')
    expect(html).to include("expected_match")
  end

  it "cannot be broken out of via </script> in challenge data" do
    hostile = kata.merge(title: "</script><script>alert(1)</script>")

    html = described_class.new(katas: [hostile]).call

    expect(html).not_to include("</script><script>")
  end
end
