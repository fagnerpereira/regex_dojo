# frozen_string_literal: true

require_relative "../../lib/regex_dojo/belt_scale"

module RegexDojo
  module Repos
    class DojoRepo < RegexDojo::DB::Repo
      XP_BY_DIFFICULTY = {"hard" => 50, "medium" => 35}.freeze
      DEFAULT_XP = 25

      def xp_for(difficulty)
        XP_BY_DIFFICULTY.fetch(difficulty.to_s.downcase, DEFAULT_XP)
      end

      def belt_for(xp)
        RegexDojo::BeltScale.for(xp)
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

            new_xp = users.by_pk(user_id).one.xp + xp_gained

            users.by_pk(user_id).command(:update).call(xp: new_xp, belt: belt_for(new_xp))
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

      def all_challenges(track: "regex")
        challenges.where(track: track).combine(:test_cases).order(:id).to_a
      end

      # What the learner should work on next in a track, plus their progress
      # through it. Phase 1 selection: first unsolved challenge by id, wrapping
      # to the first when everything is solved. With `after:`/`before:` (the
      # next/previous links), strictly the adjacent challenge by id — solved or
      # not — so the learner can always walk the whole track. The
      # spaced-repetition scheduler replaces these internals behind the same
      # method.
      def next_challenge_for(user_id, track:, after: nil, before: nil)
        rows = challenges.where(track: track).order(:id).to_a
        solved = progress.where(user_id: user_id, solved: true).to_a.map(&:kata_id)

        current = challenge_adjacent(rows, after, 1) ||
          challenge_adjacent(rows, before, -1) ||
          rows.find { |c| !solved.include?(c.id.to_s) } ||
          rows.first

        {
          challenge: current,
          solved: current ? solved.include?(current.id.to_s) : false,
          solved_count: (rows.map { |c| c.id.to_s } & solved).size,
          total_count: rows.size
        }
      end

      def find_challenge_by_id(id)
        challenges.by_pk(id).combine(:test_cases).one
      end

      private def challenge_adjacent(rows, anchor_id, step)
        return nil unless anchor_id

        index = rows.index { |c| c.id.to_s == anchor_id.to_s }
        rows[(index + step) % rows.size] if index
      end

      def create_submission(user_id:, challenge_id:, user_pattern:, is_passing:)
        submissions.command(:create).call(
          user_id: user_id,
          challenge_id: challenge_id,
          user_pattern: user_pattern,
          is_passing: is_passing
        )
      end

      # The user's most recent attempt per kata, keyed by the String challenge
      # id the view layer uses. One query, not one per kata.
      #
      # Ordered by `id`, not `submitted_at`: the timestamp has second
      # granularity, so same-second ties are real; the autoincrement id is a
      # true total order.
      def latest_patterns_for_user(user_id)
        return {} unless user_id

        newest_ids = submissions.dataset
          .where(user_id: user_id)
          .group(:challenge_id)
          .select { max(:id) }

        submissions.dataset
          .where(user_id: user_id, id: newest_ids)
          .select(:challenge_id, :user_pattern)
          .each_with_object({}) { |row, acc| acc[row[:challenge_id].to_s] = row[:user_pattern] }
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
