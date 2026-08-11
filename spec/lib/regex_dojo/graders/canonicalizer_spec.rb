# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require_relative "../../../../lib/regex_dojo/graders/canonicalizer"

# The grading contract for the Ruby track, expressed as an equivalence table.
#
# The canonicalizer answers one question: "did the learner produce the same
# code as the reference, ignoring choices that carry no meaning?" Renaming a
# block parameter carries no meaning. Swapping operands does.
RSpec.describe RegexDojo::Graders::Canonicalizer do
  describe ".equivalent?" do
    # Accepted: the learner expressed the same thing a different way.
    equivalent = {
      "insignificant whitespace" => ["x*2", "x * 2"],
      "brace vs do/end block" => [
        "arr.map { |x| x * 2 }",
        "arr.map do |x|\n  x * 2\nend"
      ],
      "renamed block parameter" => [
        "arr.map { |x| x * 2 }",
        "arr.map { |e| e * 2 }"
      ],
      "renamed params in sibling scopes" => [
        "arr.map { |x| x + 1 }.select { |x| x > 2 }",
        "arr.map { |p| p + 1 }.select { |q| q > 2 }"
      ],
      "renamed local across statements" => [
        "a = [1, 2, 3]\na.map { |x| x * 2 }",
        "arr = [1, 2, 3]\narr.map { |x| x * 2 }"
      ],
      "renamed multiple block params" => [
        "h.map { |k, v| [v, k] }",
        "h.map { |key, val| [val, key] }"
      ],
      "renamed param shadowing an outer local" => [
        "n = 1\narr.each { |n| n }",
        "n = 1\narr.each { |z| z }"
      ],
      "trailing newline" => ["arr.sum", "arr.sum\n"]
    }

    # Rejected: these mean different things. A fluency drill that accepts
    # them teaches the wrong thing.
    different = {
      "operand order" => ["x * 2", "2 * x"],
      "different literal argument" => ["arr.first(2)", "arr.first(3)"],
      "receiver and argument swapped" => ["a.zip(b)", "b.zip(a)"],
      "a genuinely different method" => ["arr.sum", "arr.inject(:+)"],
      "symbol-to-proc vs explicit block" => [
        "arr.select(&:even?)",
        "arr.select { |x| x.even? }"
      ],
      # The three below are the flag-masking regressions. Prism's
      # deconstruct_keys omits :flags entirely, so a canonical form built
      # from it alone accepts all three pairs as identical.
      "inclusive vs exclusive range" => ["(1..5).to_a", "(1...5).to_a"],
      "safe navigation" => ["s.to_s", "s&.to_s"],
      "regexp options" => ["/ruby/.match?(s)", "/ruby/i.match?(s)"]
    }

    equivalent.each do |label, (reference, answer)|
      it "accepts #{label}" do
        expect(described_class.equivalent?(reference, answer)).to be(true)
      end
    end

    different.each do |label, (reference, answer)|
      it "rejects #{label}" do
        expect(described_class.equivalent?(reference, answer)).to be(false)
      end
    end

    it "is reflexive over every fixture" do
      (equivalent.values + different.values).flatten.each do |source|
        expect(described_class.equivalent?(source, source)).to be(true)
      end
    end

    it "rejects rather than raises when the answer does not parse" do
      expect(described_class.equivalent?("arr.sum", "arr.map { |x|")).to be(false)
    end
  end

  describe ".call" do
    it "reports success for parseable source" do
      result = described_class.call("arr.map { |x| x * 2 }")

      expect(result.ok?).to be(true)
      expect(result.error_message).to be_nil
      expect(result.canonical).not_to be_nil
    end

    # Prism returns failure? == true but still hands back a partial tree, so
    # walking unconditionally reports a syntax error as a wrong answer.
    it "reports a syntax error instead of a canonical form" do
      result = described_class.call("arr.map { |x|")

      expect(result.ok?).to be(false)
      expect(result.canonical).to be_nil
      expect(result.error_message).to be_a(String)
      expect(result.error_message).not_to be_empty
    end

    it "rejects source beyond the length cap" do
      result = described_class.call("x" * (described_class::MAX_SOURCE_LENGTH + 1))

      expect(result.ok?).to be(false)
      expect(result.error_message).to match(/too long/i)
    end

    it "rejects blank source" do
      expect(described_class.call("   ").ok?).to be(false)
    end

    it "does not execute the source it parses" do
      canary = File.join(Dir.tmpdir, "regex_dojo_canary_#{Process.pid}")
      described_class.call("require 'fileutils'; FileUtils.touch(#{canary.inspect})")

      expect(File.exist?(canary)).to be(false)
    end
  end
end
