# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/regex_dojo/tracks"

RSpec.describe RegexDojo::Tracks do
  describe ".grader_for" do
    it "resolves the regex track to the regex grader" do
      expect(described_class.grader_for("regex")).to be(RegexDojo::Graders::Regex)
    end

    it "resolves the ruby track to the ruby grader" do
      expect(described_class.grader_for("ruby")).to be(RegexDojo::Graders::Ruby)
    end

    it "raises on an unknown track rather than grading with the wrong rules" do
      expect { described_class.grader_for("klingon") }
        .to raise_error(KeyError, /klingon/)
    end
  end

  describe ".label_for" do
    it "returns the display label for a track" do
      expect(described_class.label_for("ruby")).to include("Ruby")
    end
  end

  it "gives every track a grader, label, and xp ceiling" do
    described_class::REGISTRY.each_value do |track|
      expect(track).to include(:grader, :label, :xp_ceiling)
      expect(track[:xp_ceiling]).to be > 0
    end
  end
end
