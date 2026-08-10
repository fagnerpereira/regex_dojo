# frozen_string_literal: true

module RegexDojo
  module Repos
    class DojoRepo < RegexDojo::DB::Repo
      XP_BY_DIFFICULTY = {"hard" => 50, "medium" => 35}.freeze
      DEFAULT_XP = 25

      def xp_for(difficulty)
        XP_BY_DIFFICULTY.fetch(difficulty.to_s.downcase, DEFAULT_XP)
      end

      def find_user_by_session_id(session_id)
        users.where(session_id: session_id).one
      end

      def create_user(session_id:)
        users.command(:create).call(
          session_id: session_id,
          xp: 0,
          belt: "white",
          streak: 1
        )
      end

      def record_solved_kata(user_id, kata_id, xp_gained)
        solved = false

        transaction do
          unless progress.where(user_id: user_id, kata_id: kata_id, solved: true).exist?
            progress.command(:create).call(
              user_id: user_id,
              kata_id: kata_id,
              solved: true,
              xp_gained: xp_gained
            )

            user = users.by_pk(user_id).one
            new_xp = user.xp + xp_gained

            # Simple Belt progression for MVP
            new_belt = user.belt
            if new_xp >= 200 && user.belt == "white"
              new_belt = "yellow"
            end

            users.by_pk(user_id).command(:update).call(xp: new_xp, belt: new_belt)
            solved = true
          end
        end

        solved
      rescue ROM::SQL::UniqueConstraintError
        # Concurrent solves raced past the exist? check; the index kept one.
        false
      end

      def get_user_progress(user_id)
        progress.where(user_id: user_id).to_a
      end

      def save_blitz_score(user_id, score, speed_multiplier)
        blitz_scores.command(:create).call(
          user_id: user_id,
          score: score,
          speed_multiplier: speed_multiplier
        )
      end

      def all_challenges
        challenges.combine(:test_cases).order(:id).to_a
      end

      def find_challenge_by_id(id)
        challenges.by_pk(id).combine(:test_cases).one
      end

      def create_submission(challenge_id:, user_pattern:, is_passing:)
        submissions.command(:create).call(
          challenge_id: challenge_id,
          user_pattern: user_pattern,
          is_passing: is_passing
        )
      end

      def get_challenges_for_view
        all_challenges.map do |c|
          # Find first test case with expected match to use as test string
          first_matching = c.test_cases.find { |tc| !tc.expected_match.nil? }
          test_string = first_matching ? first_matching.input : (c.test_cases.first&.input || "")

          {
            id: c.id.to_s, # Stimulus uses string ID comparison
            title: c.title,
            difficulty: c.difficulty,
            concept: c.concept || "#{c.difficulty} Challenge",
            lesson: c.lesson || c.description,
            task: c.task || c.description,
            test_string: test_string,
            hint: c.hint,
            xp: xp_for(c.difficulty),
            test_cases: c.test_cases.map { |tc|
              {
                input: tc.input,
                should_match: !tc.expected_match.nil?,
                expected_match: tc.expected_match
              }
            }
          }
        end
      end

      def get_blitz_challenges_for_view
        get_challenges_for_view.select { |c| c[:difficulty].to_s.downcase != "hard" }
      end
    end
  end
end
