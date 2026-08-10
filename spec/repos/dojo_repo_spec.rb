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

    it "promotes white to yellow belt at 75 XP" do
      repo.record_solved_kata(user.id, "1", 75)

      expect(repo.find_user_by_session_id("solver").belt).to eq("yellow")
    end

    it "is backed by a DB unique index on (user_id, kata_id)" do
      progress = Hanami.app["relations.progress"]
      progress.command(:create).call(user_id: user.id, kata_id: "9", solved: true, xp_gained: 25)

      expect {
        progress.command(:create).call(user_id: user.id, kata_id: "9", solved: true, xp_gained: 25)
      }.to raise_error(ROM::SQL::UniqueConstraintError)
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
end
