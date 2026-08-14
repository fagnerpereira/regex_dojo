# frozen_string_literal: true

require "json"
require_relative "canonicalizer"
require_relative "ruby_executor"

module RegexDojo
  module Graders
    # Grades a typed Ruby answer against a challenge payload in two rounds:
    #
    # 1. STRUCTURE — the answer's canonical AST (Canonicalizer) is compared to
    #    the reference expression and accepted alternates. A match is the
    #    idiomatic pass. Parsing never executes anything.
    # 2. RESULT — when structure misses, the answer runs in RubyExecutor's
    #    sandboxed subprocess; producing the expected output still passes,
    #    flagged non-idiomatic so the UI can teach the better forms.
    #
    # Either way the result carries `suggestions` — the kata's authored
    # approaches (code + why) — so every submission ends in a small lesson.
    class Ruby
      class Result
        attr_reader :expected_output, :error_message, :feedback, :suggestions

        def initialize(passed:, expected_output:, error_message: nil, feedback: nil,
          idiomatic: false, suggestions: [])
          @passed = passed
          @expected_output = expected_output
          @error_message = error_message
          @feedback = feedback
          @idiomatic = idiomatic
          @suggestions = suggestions
        end

        def passing?
          @error_message.nil? && @passed
        end

        def idiomatic?
          @idiomatic
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

        # @param answer [String] the learner's typed Ruby
        # @param payload [Hash] challenge payload with "expression",
        #   "expected_output", optional "accepted" and "approaches"
        # @return [Result]
        def validate(answer, payload)
          payload = deep_stringify(payload)
          expected_output = payload["expected_output"]
          suggestions = suggestions_for(payload)

          answer_form = Canonicalizer.call(answer)

          unless answer_form.ok?
            return Result.new(passed: false, expected_output: expected_output,
              error_message: answer_form.error_message, suggestions: suggestions)
          end

          if structurally_accepted?(answer_form, payload)
            return Result.new(passed: true, expected_output: expected_output,
              idiomatic: true, suggestions: suggestions)
          end

          graded_by_result(answer, payload, expected_output, suggestions)
        end

        private

        def structurally_accepted?(answer_form, payload)
          references(payload).any? do |reference|
            reference_form = Canonicalizer.call(reference)

            # A reference that doesn't parse is a content bug; skip it rather
            # than fail every learner who hits this challenge.
            reference_form.ok? && reference_form.canonical == answer_form.canonical
          end
        end

        # Round 2: the answer parses but matches no reference — run it and
        # judge by what it returns, so a correct novel solution still passes.
        def graded_by_result(answer, payload, expected_output, suggestions)
          unless RubyExecutor.available?
            return Result.new(passed: false, expected_output: expected_output,
              feedback: "This answer isn't one of the accepted forms for this kata — try one of the approaches below",
              suggestions: suggestions)
          end

          outcome = RubyExecutor.call(Array(payload["setup"]), answer)

          unless outcome.ok?
            return Result.new(passed: false, expected_output: expected_output,
              feedback: outcome.error_message, suggestions: suggestions)
          end

          if outcome.output.strip == expected_output.to_s.strip
            Result.new(passed: true, expected_output: expected_output,
              idiomatic: false, suggestions: suggestions)
          else
            Result.new(passed: false, expected_output: expected_output,
              feedback: "Your code ran and returned #{outcome.output.strip} — expected #{expected_output}",
              suggestions: suggestions)
          end
        end

        def references(payload)
          [payload["expression"], *payload["accepted"]].compact
        end

        # Authored approaches (code + why) win; otherwise fall back to the
        # reference forms so older payloads still teach something.
        def suggestions_for(payload)
          approaches = payload["approaches"]

          if approaches.is_a?(Array) && approaches.any?
            approaches.map { |a| {code: a["code"].to_s, note: a["note"]} }
          else
            references(payload).map { |code| {code: code, note: nil} }
          end
        end

        def deep_stringify(payload)
          JSON.parse(JSON.generate(payload))
        end
      end
    end
  end
end
