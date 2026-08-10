# frozen_string_literal: true

require "spec_helper"

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
  end
end
