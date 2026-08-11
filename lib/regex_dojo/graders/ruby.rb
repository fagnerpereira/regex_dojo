# frozen_string_literal: true

require "json"
require_relative "canonicalizer"

module RegexDojo
  module Graders
    # Grades a typed Ruby answer against a challenge payload by structural
    # equivalence: the answer passes when its canonical AST form matches the
    # reference expression or any accepted alternate. The answer is parsed,
    # never executed.
    class Ruby
      class Result
        attr_reader :expected_output, :error_message

        def initialize(passed:, expected_output:, error_message: nil)
          @passed = passed
          @expected_output = expected_output
          @error_message = error_message
        end

        def passing?
          @error_message.nil? && @passed
        end

        def to_wire
          [{expected_output: @expected_output, passed: passing?}]
        end
      end

      class << self
        # Uniform grader entry point (see Graders::Regex.grade).
        def grade(answer, challenge)
          validate(answer, JSON.parse(challenge.payload.to_s))
        rescue JSON::ParserError
          Result.new(passed: false, expected_output: nil,
            error_message: "Challenge content is broken — payload is not valid JSON")
        end

        # @param answer [String] the learner's typed Ruby, never executed
        # @param payload [Hash] challenge payload with "expression",
        #   "expected_output" and optional "accepted" alternates
        # @return [Result]
        def validate(answer, payload)
          payload = payload.transform_keys(&:to_s)
          expected_output = payload["expected_output"]

          answer_form = Canonicalizer.call(answer)

          unless answer_form.ok?
            return Result.new(passed: false, expected_output: expected_output,
              error_message: answer_form.error_message)
          end

          passed = references(payload).any? do |reference|
            reference_form = Canonicalizer.call(reference)

            # A reference that doesn't parse is a content bug; skip it rather
            # than fail every learner who hits this challenge.
            reference_form.ok? && reference_form.canonical == answer_form.canonical
          end

          Result.new(passed: passed, expected_output: expected_output)
        end

        private

        def references(payload)
          [payload["expression"], *payload["accepted"]].compact
        end
      end
    end
  end
end
