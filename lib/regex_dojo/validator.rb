# frozen_string_literal: true

module RegexDojo
  class Validator
    # Safety rails: user patterns run on unauthenticated requests, so cap the
    # compile surface and abort catastrophic backtracking before it can pin a
    # server thread (backreference patterns bypass Ruby's regex memoization).
    MAX_PATTERN_LENGTH = 200
    MATCH_TIMEOUT = 0.2 # seconds

    class Result
      attr_reader :pattern, :test_results, :error_message

      def initialize(pattern:, test_results: [], error_message: nil)
        @pattern = pattern
        @test_results = test_results
        @error_message = error_message
      end

      def passing?
        @error_message.nil? && @test_results.all? { |r| r[:passed] }
      end

      def to_h
        {
          pattern: @pattern,
          passing: passing?,
          error_message: @error_message,
          test_results: @test_results
        }
      end
    end

    # Validates a user's regex pattern against a set of test cases.
    #
    # @param pattern [String] The user-supplied regular expression pattern (e.g. "cat\\d+")
    # @param test_cases [Array<Hash>] Array of hashes with :input and :expected_match keys
    # @return [Result] The validation result object
    def self.validate(pattern, test_cases)
      return Result.new(pattern: pattern, error_message: "Pattern cannot be empty") if pattern.to_s.strip.empty?

      if pattern.to_s.length > MAX_PATTERN_LENGTH
        return Result.new(pattern: pattern, error_message: "Pattern too long (max #{MAX_PATTERN_LENGTH} characters)")
      end

      # Safely compile the regular expression
      begin
        regex = Regexp.new(pattern, timeout: MATCH_TIMEOUT)
      rescue RegexpError => e
        return Result.new(pattern: pattern, error_message: "Invalid regex syntax: #{e.message}")
      end

      # Evaluate each test case
      test_results = test_cases.map do |tc|
        input = tc[:input] || tc["input"]
        expected = tc[:expected_match] || tc["expected_match"]

        # Run match
        actual = graded_match(regex.match(input))

        passed = (actual == expected)

        {
          input: input,
          expected_match: expected,
          actual_match: actual,
          passed: passed
        }
      end

      Result.new(pattern: pattern, test_results: test_results)
    rescue Regexp::TimeoutError
      Result.new(pattern: pattern, error_message: "Pattern took too long to evaluate — try a simpler pattern")
    end

    # The graded value of a match: extraction katas are answered with a capture
    # group (numbered or named), so a participating group wins over the full
    # match. Groupless patterns keep full-match semantics.
    def self.graded_match(match_data)
      return nil unless match_data

      match_data.captures.compact.first || match_data[0]
    end
  end
end
