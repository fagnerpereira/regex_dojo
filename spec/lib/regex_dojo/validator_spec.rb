# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/regex_dojo/validator"

RSpec.describe RegexDojo::Validator do
  let(:test_cases) do
    [
      { input: "the black cat", expected_match: "cat" },
      { input: "dogs are cool", expected_match: nil }
    ]
  end

  describe ".validate" do
    context "with a valid passing pattern" do
      it "returns a passing result" do
        result = described_index = described_class.validate("cat", test_cases)
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
  end
end
