# frozen_string_literal: true

require "json"
require_relative "../../../lib/regex_dojo/validator"

module RegexDojo
  module Actions
    module Kata
      class Check < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          response.format = :json

          challenge = dojo_repo.find_challenge_by_id(request.params[:id].to_i)

          unless challenge
            response.status = 404
            response.body = {error: "Challenge not found"}.to_json
            return
          end

          pattern = parse_body(request)[:pattern].to_s.strip
          result = RegexDojo::Validator.validate(pattern, challenge.test_cases.map(&:to_h))

          # Resolved before logging so every attempt is attributed to its author.
          user = current_user(request)

          # Log every attempt, including patterns the validator rejects, so
          # submission history and telemetry reflect what learners actually tried.
          dojo_repo.create_submission(
            user_id: user.id,
            challenge_id: challenge.id,
            user_pattern: pattern,
            is_passing: result.passing?
          )

          if result.error_message
            response.status = 422
            response.body = {passing: false, error_message: result.error_message}.to_json
            return
          end

          xp_awarded = award_xp(user, challenge, result.passing?)
          user = dojo_repo.find_user_by_session_id(user.session_id) # reload post-award

          response.body = {
            passing: result.passing?,
            pattern: pattern,
            xp_awarded: xp_awarded,
            total_xp: user.xp,
            belt: user.belt,
            test_results: wire_results(result)
          }.to_json
        end

        private

        def parse_body(request)
          JSON.parse(request.body.read, symbolize_names: true)
        rescue JSON::ParserError
          {}
        end

        def award_xp(user, challenge, passing)
          return 0 unless passing

          xp_value = dojo_repo.xp_for(challenge.difficulty)
          dojo_repo.record_solved_kata(user.id, challenge.id.to_s, xp_value) ? xp_value : 0
        end

        # The shape the Stimulus controllers render.
        def wire_results(result)
          result.test_results.map do |r|
            {
              input: r[:input],
              should_match: !r[:expected_match].nil?,
              did_match: !r[:actual_match].nil?,
              actual_match: r[:actual_match],
              passed: r[:passed]
            }
          end
        end
      end
    end
  end
end
