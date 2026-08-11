# frozen_string_literal: true

require "json"

RSpec.describe "Seeds", :db do
  let(:challenges) { Hanami.app["relations.challenges"] }
  let(:regex_challenges) { challenges.where(track: "regex").to_a }
  let(:ruby_challenges) { challenges.where(track: "ruby").to_a }

  it "loads the regex curriculum with stable ids" do
    expect(regex_challenges.size).to eq(15)
    expect(regex_challenges.map { |c| c[:id] }.min).to eq(31)
    expect(regex_challenges).to all(include(mode: "pattern"))
  end

  it "populates the regex teaching content columns" do
    regex_challenges.each do |c|
      expect(c[:concept]).not_to be_nil
      expect(c[:lesson]).not_to be_nil
      expect(c[:task]).not_to be_nil
    end
  end

  it "loads the ruby track with well-formed payloads" do
    expect(ruby_challenges.size).to eq(5)
    expect(ruby_challenges.map { |c| c[:id] }.min).to be >= 101
    expect(ruby_challenges).to all(include(mode: "type_code"))

    ruby_challenges.each do |c|
      payload = JSON.parse(c[:payload])
      expect(payload.keys).to include("prompt", "setup", "expression", "expected_output", "accepted")
    end
  end

  # The old seeds did DELETE FROM challenges, which cascaded into submissions
  # (FK ON DELETE CASCADE, PRAGMA foreign_keys ON) and destroyed attempt
  # history on every reseed. These two examples pin the upsert behavior.
  describe "reseeding" do
    let(:seeds_file) { File.join(Hanami.app.root, "config", "db", "seeds.rb") }

    it "preserves submissions across a reseed" do
      Hanami.app["relations.submissions"].insert(
        challenge_id: 31, user_pattern: "cat", is_passing: true
      )

      expect { load seeds_file }
        .not_to change { Hanami.app["relations.submissions"].to_a.size }
    end

    it "keeps every challenge id stable across a reseed" do
      ids_before = challenges.to_a.map { |c| c[:id] }.sort

      load seeds_file

      expect(challenges.to_a.map { |c| c[:id] }.sort).to eq(ids_before)
    end
  end
end
