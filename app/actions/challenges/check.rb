# frozen_string_literal: true

require_relative "../../../lib/regex_dojo/tracks"

module RegexDojo
  module Actions
    module Challenges
      # One check flow for every track: grade the answer, log the attempt,
      # award XP, then redirect back to the challenge page (PRG, 303) with
      # the verdict in the flash. The page renders the banner server-side.
      class Check < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          challenge = dojo_repo.find_challenge_by_id(request.params[:id].to_i)
          halt 404 unless challenge

          answer = request.params[:answer].to_s.strip
          result = RegexDojo::Tracks.grader_for(challenge.track).grade(answer, challenge)
          user = current_user(request)

          # Log every attempt, including rejected patterns, so submission
          # history reflects what learners actually tried.
          dojo_repo.create_submission(
            user_id: user.id,
            challenge_id: challenge.id,
            user_pattern: answer,
            is_passing: result.passing?
          )

          response.flash[:challenge_result] = flash_payload(result, user, challenge)
          response.redirect_to(return_path(challenge), status: 303)
        end

        private

        def flash_payload(result, user, challenge)
          if result.error_message
            {"status" => "error", "message" => result.error_message}
          elsif result.passing?
            {
              "status" => "passing",
              "xp_awarded" => award_xp(user, challenge),
              "idiomatic" => result.idiomatic?,
              "feedback" => result.feedback
            }.compact
          else
            {"status" => "failing", "feedback" => result.feedback}.compact
          end
        end

        def award_xp(user, challenge)
          xp_value = dojo_repo.xp_for(challenge.difficulty)
          dojo_repo.record_solved_kata(user.id, challenge.id.to_s, xp_value) ? xp_value : 0
        end

        def return_path(challenge)
          (challenge.track == "ruby") ? "/ruby/#{challenge.id}" : "/desafios/#{challenge.id}"
        end
      end
    end
  end
end
