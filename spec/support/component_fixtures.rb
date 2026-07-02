# frozen_string_literal: true

# Single source of truth for the data shapes Phlex components receive in
# production, so component specs don't each invent slightly different
# fixtures. Mirrors:
#   - the presenter struct built in app/actions/home/index.rb
#   - the kata hash shape returned by DojoRepo#get_challenges_for_view
module ComponentFixtures
  UserPresenter = Struct.new(
    :id, :session_id, :xp, :belt, :streak, :katas_solved, :accuracy, :rank, :belt_percent, :initials
  )

  # Minimal shape for RegexDojo::Components::Screens::Leaderboard, which only
  # reads id/session_id/belt/xp off each user (dojo_repo.top_users rows).
  LeaderboardUser = Struct.new(:id, :session_id, :belt, :xp)

  def build_leaderboard_user(**overrides)
    defaults = {id: 1, session_id: "11111111", belt: "white", xp: 100}
    LeaderboardUser.new(*defaults.merge(overrides).values_at(*LeaderboardUser.members))
  end

  def build_user_presenter(**overrides)
    defaults = {
      id: 1,
      session_id: "11111111-1111-1111-1111-111111111111",
      xp: 100,
      belt: "white",
      streak: 3,
      katas_solved: 2,
      accuracy: 80,
      rank: 5,
      belt_percent: 33,
      initials: "11"
    }
    UserPresenter.new(*defaults.merge(overrides).values_at(*UserPresenter.members))
  end

  def build_kata(**overrides)
    defaults = {
      id: "1",
      title: "Match a digit",
      difficulty: "easy",
      concept: "Character classes",
      lesson: "Digits can be matched with \\d.",
      task: "Write a pattern that matches a single digit.",
      test_string: "abc123",
      hint: "Try \\d",
      xp: 25,
      test_cases: [
        {input: "abc123", should_match: true, expected_match: "1"},
        {input: "abcdef", should_match: false, expected_match: nil}
      ]
    }
    defaults.merge(overrides)
  end
end

RSpec.configure do |config|
  config.include ComponentFixtures, type: :component
end
