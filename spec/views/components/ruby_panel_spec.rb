# frozen_string_literal: true

require "spec_helper"
require "json"
require "nokogiri"

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

  it "renders a Next challenge link that advances past the current one" do
    html = described_class.new(challenge: challenge).call

    expect(html).to include('href="/?ruby_after=102"')
    expect(html).to include("Next")
    # Plain language: no jargon in what the learner reads (CSS class names
    # and data attributes are internals and may keep their historical names)
    visible_text = Nokogiri::HTML.fragment(html).text
    expect(visible_text.downcase).not_to include("kata")
  end

  it "renders a Previous challenge link that steps back" do
    html = described_class.new(challenge: challenge).call

    expect(html).to include('href="/?ruby_before=102"')
    expect(html).to include("Previous")
  end

  it "replaces the history entry instead of stacking one per navigation click" do
    html = described_class.new(challenge: challenge).call

    expect(html).to match(/href="\/\?ruby_after=102"[^>]*data-turbo-action="replace"/)
    expect(html).to match(/href="\/\?ruby_before=102"[^>]*data-turbo-action="replace"/)
  end

  it "badges an already-solved kata so cycling stays honest" do
    html = described_class.new(challenge: challenge, solved: true).call

    expect(html).to include("✓ solved")
  end

  it "shows no badge on an unsolved kata" do
    html = described_class.new(challenge: challenge).call

    expect(html).not_to include("✓ solved")
  end

  it "announces track completion when everything is solved" do
    html = described_class.new(challenge: challenge, solved: true, solved_count: 5, total_count: 5).call

    expect(html).to include("Track complete")
  end
end
