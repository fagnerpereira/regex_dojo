# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/regex_dojo/graders/ruby"

RSpec.describe RegexDojo::Graders::Ruby do
  let(:payload) do
    {
      "prompt" => "Double every element with Array#map",
      "setup" => ["arr = [1, 2, 3]"],
      "expression" => "arr.map { |x| x * 2 }",
      "expected_output" => "[2, 4, 6]",
      "accepted" => []
    }
  end

  describe ".validate" do
    it "passes the reference expression itself" do
      result = described_class.validate("arr.map { |x| x * 2 }", payload)

      expect(result.passing?).to be(true)
      expect(result.error_message).to be_nil
    end

    it "passes a structurally equivalent answer with renamed parameters" do
      result = described_class.validate("arr.map { |e| e*2 }", payload)

      expect(result.passing?).to be(true)
    end

    it "passes a do/end variant" do
      result = described_class.validate("arr.map do |x|\n  x * 2\nend", payload)

      expect(result.passing?).to be(true)
    end

    it "fails a semantically different answer" do
      result = described_class.validate("arr.map { |x| x + 2 }", payload)

      expect(result.passing?).to be(false)
      expect(result.error_message).to be_nil
    end

    it "passes an answer matching an accepted alternate" do
      payload["accepted"] = ["arr.collect { |x| x * 2 }"]
      result = described_class.validate("arr.collect { |n| n * 2 }", payload)

      expect(result.passing?).to be(true)
    end

    it "reports a syntax error for an unparseable answer" do
      result = described_class.validate("arr.map { |x|", payload)

      expect(result.passing?).to be(false)
      expect(result.error_message).to be_a(String)
    end

    it "reports an error for a blank answer" do
      result = described_class.validate("   ", payload)

      expect(result.passing?).to be(false)
      expect(result.error_message).to match(/empty/i)
    end

    it "handles symbol-keyed payloads from JSON round-trips" do
      symbolized = payload.transform_keys(&:to_sym)
      result = described_class.validate("arr.map { |x| x * 2 }", symbolized)

      expect(result.passing?).to be(true)
    end
  end

  describe "#to_wire" do
    it "exposes the expected output and verdict for the client" do
      wire = described_class.validate("arr.map { |x| x * 2 }", payload).to_wire

      expect(wire).to eq([{expected_output: "[2, 4, 6]", passed: true}])
    end
  end
end
