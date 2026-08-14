# frozen_string_literal: true

RSpec.describe RegexDojo::Repos::DojoRepo do
  subject(:repo) { Hanami.app["repos.dojo_repo"] }

  describe "#xp_for" do
    it "maps difficulty to XP, case-insensitively" do
      expect(repo.xp_for("Hard")).to eq(50)
      expect(repo.xp_for("medium")).to eq(35)
      expect(repo.xp_for("Easy")).to eq(25)
      expect(repo.xp_for(nil)).to eq(25)
    end
  end

  describe "#create_user / #find_user_by_session_id" do
    it "creates a guest with starting stats and finds it back" do
      repo.create_user(session_id: "abc-123")
      user = repo.find_user_by_session_id("abc-123")

      expect(user.xp).to eq(0)
      expect(user.belt).to eq("white")
      expect(user.streak).to eq(1)
    end

    it "returns nil for an unknown session" do
      expect(repo.find_user_by_session_id("nope")).to be_nil
    end
  end

  describe "#best_blitz_score" do
    let(:user) do
      repo.create_user(session_id: "blitzer")
      repo.find_user_by_session_id("blitzer")
    end

    it "returns the user's highest score across runs" do
      repo.save_blitz_score(user.id, 3, 1.0)
      repo.save_blitz_score(user.id, 7, 1.0)
      repo.save_blitz_score(user.id, 5, 1.0)

      expect(repo.best_blitz_score(user.id)).to eq(7)
    end

    it "is zero for a user with no runs" do
      expect(repo.best_blitz_score(user.id)).to eq(0)
    end
  end

  describe "#create_submission" do
    let(:user) do
      repo.create_user(session_id: "submitter")
      repo.find_user_by_session_id("submitter")
    end

    it "attributes the attempt to the user who made it" do
      repo.create_submission(
        user_id: user.id, challenge_id: 31, user_pattern: "ruby", is_passing: true
      )

      expect(repo.submissions.where(user_id: user.id).count).to eq(1)
    end
  end

  describe "#latest_patterns_for_user" do
    let(:user) do
      repo.create_user(session_id: "historian")
      repo.find_user_by_session_id("historian")
    end

    def attempt(pattern, challenge_id: 31, passing: false, for_user: user)
      repo.create_submission(
        user_id: for_user.id,
        challenge_id: challenge_id,
        user_pattern: pattern,
        is_passing: passing
      )
    end

    it "returns an empty hash for a user with no submissions" do
      expect(repo.latest_patterns_for_user(user.id)).to eq({})
    end

    it "keys by String challenge id, matching get_challenges_for_view" do
      attempt("ruby")

      expect(repo.latest_patterns_for_user(user.id)).to eq({"31" => "ruby"})
    end

    it "returns the newest attempt per kata, not the first" do
      attempt("first-try")
      attempt("second-try")
      attempt("cat", challenge_id: 32)

      expect(repo.latest_patterns_for_user(user.id))
        .to eq({"31" => "second-try", "32" => "cat"})
    end

    it "keeps a failing attempt as the latest answer" do
      attempt("ruby", passing: true)
      attempt("broken-attempt", passing: false)

      expect(repo.latest_patterns_for_user(user.id)["31"]).to eq("broken-attempt")
    end

    it "ignores other users' submissions" do
      repo.create_user(session_id: "stranger")
      stranger = repo.find_user_by_session_id("stranger")
      attempt("mine")
      attempt("theirs", for_user: stranger)

      expect(repo.latest_patterns_for_user(user.id)).to eq({"31" => "mine"})
    end
  end

  describe "#record_solved_kata" do
    let(:user) do
      repo.create_user(session_id: "solver")
      repo.find_user_by_session_id("solver")
    end

    it "records progress and adds XP" do
      expect(repo.record_solved_kata(user.id, "1", 25)).to be(true)
      expect(repo.find_user_by_session_id("solver").xp).to eq(25)
    end

    it "is idempotent per kata" do
      repo.record_solved_kata(user.id, "1", 25)

      expect(repo.record_solved_kata(user.id, "1", 25)).to be(false)
      expect(repo.find_user_by_session_id("solver").xp).to eq(25)
    end

    it "promotes the belt to match the new XP total" do
      repo.record_solved_kata(user.id, "1", 200)

      expect(repo.find_user_by_session_id("solver").belt).to eq("Intermediário")
    end

    it "is backed by a DB unique index on (user_id, kata_id)" do
      progress = Hanami.app["relations.progress"]
      progress.command(:create).call(user_id: user.id, kata_id: "9", solved: true, xp_gained: 25)

      expect {
        progress.command(:create).call(user_id: user.id, kata_id: "9", solved: true, xp_gained: 25)
      }.to raise_error(ROM::SQL::UniqueConstraintError)
    end
  end

  describe "#next_challenge_for with after:" do
    let(:user) do
      repo.create_user(session_id: "walker")
      repo.find_user_by_session_id("walker")
    end

    it "returns the challenge following the given id, solved or not" do
      track = repo.next_challenge_for(user.id, track: "ruby", after: "101")

      expect(track[:challenge].id).to eq(102)
    end

    it "wraps to the first challenge after the last one" do
      track = repo.next_challenge_for(user.id, track: "ruby", after: "105")

      expect(track[:challenge].id).to eq(101)
    end

    it "steps back with before:, wrapping to the last from the first" do
      expect(repo.next_challenge_for(user.id, track: "ruby", before: "102")[:challenge].id).to eq(101)
      expect(repo.next_challenge_for(user.id, track: "ruby", before: "101")[:challenge].id).to eq(105)
    end

    it "falls back to first-unsolved when after is unknown" do
      repo.record_solved_kata(user.id, "101", 25)

      track = repo.next_challenge_for(user.id, track: "ruby", after: "999")

      expect(track[:challenge].id).to eq(102)
    end

    it "reports whether the shown challenge is already solved" do
      repo.record_solved_kata(user.id, "102", 25)

      solved_view = repo.next_challenge_for(user.id, track: "ruby", after: "101")
      fresh_view = repo.next_challenge_for(user.id, track: "ruby", after: "102")

      expect(solved_view[:solved]).to be(true)
      expect(fresh_view[:solved]).to be(false)
    end
  end

  describe "#find_challenge_by_id" do
    it "returns nil for an unknown id" do
      expect(repo.find_challenge_by_id(999_999)).to be_nil
    end
  end

  describe "#get_challenges_for_view" do
    subject(:challenges) { repo.get_challenges_for_view }

    it "ships ids as strings with difficulty-derived XP" do
      expect(challenges).not_to be_empty
      challenges.each do |c|
        expect(c[:id]).to be_a(String)
        expect(c[:xp]).to eq(repo.xp_for(c[:difficulty]))
      end
    end

    it "ships expected_match so the client can grade like the server" do
      test_cases = challenges.flat_map { |c| c[:test_cases] }

      expect(test_cases).to all(have_key(:expected_match))
    end

    it "uses the authored teaching content, not text derived from the description" do
      first = challenges.first

      expect(first[:concept]).not_to eq("#{first[:difficulty]} Challenge")
      expect(first[:lesson]).not_to eq(first[:task])
    end
  end

  describe "#get_blitz_challenges_for_view" do
    it "excludes hard challenges" do
      difficulties = repo.get_blitz_challenges_for_view.map { |c| c[:difficulty].downcase }

      expect(difficulties).not_to include("hard")
      expect(difficulties).not_to be_empty
    end
  end

  describe "track scoping" do
    it "keeps ruby challenges out of the regex sidebar and blitz" do
      ids = repo.get_challenges_for_view.map { |c| c[:id].to_i }
      blitz_ids = repo.get_blitz_challenges_for_view.map { |c| c[:id].to_i }

      expect(ids).to eq((31..45).to_a)
      expect(blitz_ids).to all(be < 100)
    end
  end

  describe "#next_challenge_for" do
    let(:user) do
      repo.create_user(session_id: "typist")
      repo.find_user_by_session_id("typist")
    end

    it "serves the first ruby challenge to a fresh user, with counts" do
      result = repo.next_challenge_for(user.id, track: "ruby")

      expect(result[:challenge].id).to eq(101)
      expect(result[:solved_count]).to eq(0)
      expect(result[:total_count]).to eq(5)
    end

    it "advances past solved challenges" do
      repo.record_solved_kata(user.id, "101", 25)

      result = repo.next_challenge_for(user.id, track: "ruby")

      expect(result[:challenge].id).to eq(102)
      expect(result[:solved_count]).to eq(1)
    end

    it "wraps to the first challenge when everything is solved" do
      (101..105).each { |id| repo.record_solved_kata(user.id, id.to_s, 25) }

      result = repo.next_challenge_for(user.id, track: "ruby")

      expect(result[:challenge].id).to eq(101)
      expect(result[:solved_count]).to eq(5)
    end
  end
end
