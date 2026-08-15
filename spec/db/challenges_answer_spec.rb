# frozen_string_literal: true

require "json"

# Guards against unwinnable challenges: every challenge ships its own
# canonical answer as the last layer of its 3-layer hint (see
# lib/regex_dojo/seeds/regex.rb). If that answer can't pass the challenge's
# own test cases, no learner's equivalent pattern can either — the challenge
# is broken data, not a grader bug. This runs each canonical answer through
# the exact same path Actions::Challenges::Check uses in production.
RSpec.describe "Challenge canonical answers", :db do
  let(:repo) { Hanami.app["repos.dojo_repo"] }

  it "passes every regex challenge's own test cases" do
    challenges = repo.all_challenges(track: "regex")

    failure_reports = challenges.filter_map do |challenge|
      canonical_answer = JSON.parse(challenge.hint).last
      grader = RegexDojo::Tracks.grader_for(challenge.track)
      grading_result = grader.grade(canonical_answer, challenge)

      next if grading_result.passing?

      describe_failure(challenge, canonical_answer, grading_result)
    end

    expect(failure_reports).to be_empty, failure_reports.join("\n")
  end

  def describe_failure(challenge, canonical_answer, grading_result)
    failed_test_cases = grading_result.test_results.reject do |test_result|
      test_result[:passed]
    end
    reason = grading_result.error_message || failed_test_cases.inspect
    title = challenge.title.inspect

    "##{challenge.id} #{title}: #{canonical_answer.inspect} — #{reason}"
  end
end
