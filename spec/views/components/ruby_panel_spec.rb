# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe RegexDojo::Views::Components::RubyPanel do
  let(:challenge_struct) { Struct.new(:id, :title, :concept, :hint, :payload) }

  let(:challenge) do
    challenge_struct.new(
      id: 102,
      title: "Filter with select",
      concept: "💎 Array#select",
      hint: "use even?",
      payload: {
        prompt: "Keep only the even numbers.",
        setup: ["arr = [1, 2]"],
        expression: "arr.select(&:even?)",
        expected_output: "[2]",
        accepted: []
      }.to_json
    )
  end

  it "renders the suggestions container for post-answer approaches" do
    html = described_class.new(challenge: challenge).call

    expect(html).to include('data-ruby-dojo-target="suggestions"')
  end

  it "renders the solved counter as a live target" do
    html = described_class.new(challenge: challenge, solved_count: 1, total_count: 5).call

    expect(html).to include('data-ruby-dojo-target="solvedCounter"')
    expect(html).to include("1/5 solved")
  end
end
