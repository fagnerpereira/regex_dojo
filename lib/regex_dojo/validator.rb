# frozen_string_literal: true

module RegexDojo
  class Validator
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

      # Safely compile the regular expression
      begin
        regex = Regexp.new(pattern)
      rescue RegexpError => e
        return Result.new(pattern: pattern, error_message: "Invalid regex syntax: #{e.message}")
      end

      # Evaluate each test case
      test_results = test_cases.map do |tc|
        input = tc[:input] || tc["input"]
        expected = tc[:expected_match] || tc["expected_match"]

        # Run match
        match_data = regex.match(input)
        actual = match_data ? match_data[0] : nil

        passed = (actual == expected)

        {
          input: input,
          expected_match: expected,
          actual_match: actual,
          passed: passed
        }
      end

      Result.new(pattern: pattern, test_results: test_results)
    end
  end
end
