# frozen_string_literal: true

require "json"
require_relative "../../../lib/regex_dojo/kata_pool"

module RegexDojo
  module Actions
    module Kata
      class Check < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          kata_id = request.params[:id]
          challenge = dojo_repo.find_challenge_by_id(kata_id.to_i)

          unless challenge
            response.status = 404
            response.format = :json
            response.body = {error: "Challenge not found"}.to_json
            return
          end

          # Parse JSON body
          body = begin
            JSON.parse(request.body.read, symbolize_names: true)
          rescue JSON::ParserError
            {}
          end

          pattern = body[:pattern].to_s.strip

          if pattern.empty?
            response.status = 422
            response.format = :json
            response.body = {error: "Pattern cannot be empty", passing: false}.to_json
            return
          end

          # Safely compile the regex
          begin
            regex = Regexp.new(pattern)
          rescue RegexpError => e
            # Log the failed submission attempt before returning error
            dojo_repo.create_submission(
              challenge_id: challenge.id,
              user_pattern: pattern,
              is_passing: false
            )
            response.format = :json
            response.body = {
              passing: false,
              error_message: "Invalid regex: #{e.message}"
            }.to_json
            return
          end

          # Evaluate each test case against expected match
          test_results = challenge.test_cases.map do |tc|
            match_data = regex.match(tc.input)
            actual_match = match_data ? match_data[0] : nil
            passed = (actual_match == tc.expected_match)

            {
              input: tc.input,
              should_match: !tc.expected_match.nil?,
              did_match: !actual_match.nil?,
              actual_match: actual_match,
              passed: passed
            }
          end

          all_passing = test_results.all? { |r| r[:passed] }

          # Save submission telemetry
          dojo_repo.create_submission(
            challenge_id: challenge.id,
            user_pattern: pattern,
            is_passing: all_passing
          )

          xp_value = case challenge.difficulty.to_s.downcase
          when "hard" then 50
          when "medium" then 35
          else 25
          end

          xp_awarded = 0

          if all_passing
            # Record progress and award XP
            session_id = request.session[:session_id] || request.session["session_id"]
            if session_id
              user = dojo_repo.find_user_by_session_id(session_id)
              if user
                was_new = dojo_repo.record_solved_kata(user.id, challenge.id.to_s, xp_value)
                xp_awarded = was_new ? xp_value : 0
                user = dojo_repo.find_user_by_session_id(session_id) # Reload for updated XP
              end
            end
          end

          response.format = :json
          response.body = {
            passing: all_passing,
            pattern: pattern,
            xp_awarded: xp_awarded,
            total_xp: user&.xp || 0,
            belt: user&.belt || "white",
            test_results: test_results
          }.to_json
        end
      end
    end
  end
end
