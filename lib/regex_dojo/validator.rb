# frozen_string_literal: true

require_relative "graders/regex"

module RegexDojo
  # Historical entry point for regex grading, kept so existing callers and
  # specs stay valid. The implementation lives in Graders::Regex; new code
  # should resolve its grader through RegexDojo::Tracks instead.
  class Validator
    Result = Graders::Regex::Result

    def self.validate(pattern, test_cases)
      Graders::Regex.validate(pattern, test_cases)
    end
  end
end
