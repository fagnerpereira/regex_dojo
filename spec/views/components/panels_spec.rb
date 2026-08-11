# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# Smoke specs: each panel renders without error and mounts its Stimulus
# controller. A cheap regression net for Phlex upgrades and refactors.
RSpec.describe "Panel components" do
  let(:user) do
    {xp: 0, belt: "white", streak: 1, session_id: "abcd1234-0000-0000-0000-000000000000"}
  end

  let(:kata) do
    {
      id: "1", title: "Literal", difficulty: "Easy", concept: "Basics",
      lesson: "Type the letters", task: "Match abc", test_string: "abc",
      hint: "just abc", xp: 25,
      test_cases: [{input: "abc", should_match: true, expected_match: "abc"}]
    }
  end

  it "renders the DojoPanel with its dojo controller" do
    html = RegexDojo::Views::Components::DojoPanel.new(
      user: user, solved_kata_ids: [], katas: [kata]
    ).call

    expect(html).to include('data-controller="dojo"')
    expect(html).to include("Literal")
  end

  describe "restoring the learner's last answer" do
    def kata_button(last_patterns:)
      html = RegexDojo::Views::Components::DojoPanel.new(
        user: user, solved_kata_ids: [], katas: [kata], last_patterns: last_patterns
      ).call

      Nokogiri::HTML.fragment(html).at_css("[data-kata-id='1']")
    end

    it "renders the user's last pattern for that kata" do
      button = kata_button(last_patterns: {"1" => 'a+\d{2}'})

      expect(button["data-kata-last-pattern"]).to eq('a+\d{2}')
    end

    it "renders an empty last pattern when the user has never tried the kata" do
      button = kata_button(last_patterns: {})

      expect(button["data-kata-last-pattern"]).to eq("")
    end

    it "is threaded through the Dashboard" do
      html = RegexDojo::Views::Home::Dashboard.new(
        user: user, solved_kata_ids: [], challenges: [kata],
        blitz_challenges: [], last_patterns: {"1" => "from-dashboard"}
      ).call

      button = Nokogiri::HTML.fragment(html).at_css("[data-kata-id='1']")
      expect(button["data-kata-last-pattern"]).to eq("from-dashboard")
    end
  end

  describe "RubyPanel" do
    let(:ruby_challenge) do
      Struct.new(:id, :title, :concept, :hint, :payload).new(
        id: 101, title: "Transform with map", concept: "💎 Array#map",
        hint: "map collects block returns",
        payload: {
          prompt: "Double every element.",
          setup: ["arr = [1, 2, 3]"],
          expression: "arr.map { |x| x * 2 }",
          expected_output: "[2, 4, 6]",
          accepted: []
        }.to_json
      )
    end

    it "renders one challenge with its ruby-dojo controller" do
      html = RegexDojo::Views::Components::RubyPanel.new(
        challenge: ruby_challenge, solved_count: 1, total_count: 5
      ).call

      expect(html).to include('data-controller="ruby-dojo"')
      expect(html).to include("data-ruby-dojo-challenge-id-value=\"101\"")
      expect(html).to include("Double every element.")
      expect(html).to include("[2, 4, 6]")
      expect(html).to include("1/5 solved")
    end

    it "degrades gracefully when the track has no challenges" do
      html = RegexDojo::Views::Components::RubyPanel.new(challenge: nil).call

      expect(html).to include("hanami db seed")
    end
  end

  it "renders the SandboxPanel with its sandbox controller" do
    html = RegexDojo::Views::Components::SandboxPanel.new.call

    expect(html).to include('data-controller="sandbox"')
  end

  it "renders the CodexPanel" do
    html = RegexDojo::Views::Components::CodexPanel.new.call

    expect(html).not_to be_empty
    expect(html).not_to include("Phlex Warning")
  end

  it "renders the Dashboard shell with tabs and all panels" do
    html = RegexDojo::Views::Home::Dashboard.new(
      user: user, solved_kata_ids: [], challenges: [kata], blitz_challenges: [kata]
    ).call

    expect(html).to include('data-controller="tabs"')
    expect(html).to include('data-controller="dojo"')
    expect(html).to include('data-controller="blitz"')
    expect(html).to include('id="hud-bar"')
    expect(html).to include('data-tab="ruby"')
  end
end
