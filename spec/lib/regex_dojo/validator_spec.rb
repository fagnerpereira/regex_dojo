# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/regex_dojo/validator"

RSpec.describe RegexDojo::Validator do
  let(:test_cases) do
    [
      {input: "the black cat", expected_match: "cat"},
      {input: "dogs are cool", expected_match: nil}
    ]
  end

  describe ".validate" do
    context "with a valid passing pattern" do
      it "returns a passing result" do
        result = described_class.validate("cat", test_cases)
        expect(result.passing?).to be(true)
        expect(result.test_results[0][:passed]).to be(true)
        expect(result.test_results[1][:passed]).to be(true)
      end
    end

    context "with a valid failing pattern" do
      it "returns a failing result" do
        result = described_class.validate("dogs", test_cases)
        expect(result.passing?).to be(false)
        expect(result.test_results[0][:passed]).to be(false) # expected "cat", got nil
        expect(result.test_results[1][:passed]).to be(false) # expected nil, got "dogs"
      end
    end

    context "with an invalid regex pattern" do
      it "returns a result with an error message" do
        result = described_class.validate("[a-z", test_cases)
        expect(result.passing?).to be(false)
        expect(result.error_message).to include("Invalid regex syntax")
      end
    end

    context "with an empty pattern" do
      it "returns a result with an error message" do
        result = described_class.validate("", test_cases)
        expect(result.passing?).to be(false)
        expect(result.error_message).to eq("Pattern cannot be empty")
      end
    end

    context "with capture groups (extraction katas)" do
      it "grades the captured group, not the full match" do
        cases = [{input: "Call me at (555)-0199", expected_match: "555"}]

        result = described_class.validate('\((\d{3})\)', cases)

        expect(result.passing?).to be(true)
        expect(result.test_results[0][:actual_match]).to eq("555")
      end

      it "grades a named capture group" do
        cases = [
          {input: "https://hanamirb.org", expected_match: "https"},
          {input: "ftp://files.org", expected_match: nil}
        ]

        result = described_class.validate("(?<protocol>https?)://", cases)

        expect(result.passing?).to be(true)
      end

      it "falls back to the full match when no group participates" do
        cases = [{input: "abc", expected_match: "abc"}]

        result = described_class.validate("(x)?abc", cases)

        expect(result.passing?).to be(true)
      end

      it "still grades groupless patterns by full match" do
        cases = [{input: "the black cat", expected_match: "cat"}]

        result = described_class.validate("cat", cases)

        expect(result.passing?).to be(true)
      end
    end

    context "with hostile patterns (safety rails)" do
      it "rejects patterns longer than 200 characters" do
        result = described_class.validate("a" * 201, test_cases)

        expect(result.passing?).to be(false)
        expect(result.error_message).to include("Pattern too long")
      end

      it "aborts catastrophic backtracking instead of hanging" do
        # Backreferences defeat Ruby's regex memoization, so this pattern is
        # genuinely exponential — verified to hang without a timeout.
        cases = [{input: "#{"a" * 40}b", expected_match: nil}]

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = described_class.validate('^(a|aa)+\1$', cases)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

        expect(result.passing?).to be(false)
        expect(result.error_message).to include("took too long")
        expect(elapsed).to be < 2
      end
    end
  end
end
