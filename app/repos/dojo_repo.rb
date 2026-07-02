# frozen_string_literal: true

module RegexDojo
  module Repos
    class DojoRepo < RegexDojo::DB::Repo
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
        already_solved = progress.where(user_id: user_id, kata_id: kata_id, solved: true).exist?
        return false if already_solved

        progress.command(:create).call(
          user_id: user_id,
          kata_id: kata_id,
          solved: true,
          xp_gained: xp_gained
        )

        user = users.by_pk(user_id).one
        new_xp = user.xp + xp_gained

        # Recalculate belt dynamically based on cumulative XP progression
        new_belt = if new_xp >= 370
          "black"
        elsif new_xp >= 265
          "green"
        elsif new_xp >= 160
          "orange"
        elsif new_xp >= 75
          "yellow"
        else
          "white"
        end

        users.by_pk(user_id).command(:update).call(xp: new_xp, belt: new_belt)
        true
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

          xp = case c.difficulty.to_s.downcase
          when "hard" then 50
          when "medium" then 35
          else 25
          end

          {
            id: c.id.to_s, # Stimulus uses string ID comparison
            title: c.title,
            difficulty: c.difficulty,
            concept: (c.respond_to?(:concept) && c.concept) ? c.concept : "#{c.difficulty} Challenge",
            lesson: (c.respond_to?(:lesson) && c.lesson) ? c.lesson : c.description,
            task: (c.respond_to?(:task) && c.task) ? c.task : c.description,
            test_string: test_string,
            hint: c.hint,
            xp: xp,
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

      def top_users(limit = 10)
        users.order { xp.desc }.limit(limit).to_a
      end
    end
  end
end
