# frozen_string_literal: true

module RegexDojo
  module Graders
    # Shared verdict shape for graders that evaluate an answer against a list
    # of test cases. Extracted from the original Validator::Result unchanged;
    # each grader subclasses it to own its client-facing wire format.
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
  end
end
