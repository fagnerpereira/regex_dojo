# frozen_string_literal: true

require "stringio"

RSpec.describe RegexDojo::Actions::Kata::Check, :db do
  let(:dojo_repo) { Hanami.app["repos.dojo_repo"] }
  let(:session_id) { "test-session-uuid" }

  let!(:user) do
    dojo_repo.create_user(session_id: session_id)
    dojo_repo.find_user_by_session_id(session_id)
  end

  def call_check(id:, pattern:, session: {"session_id" => session_id})
    subject.call(
      "REQUEST_METHOD" => "POST",
      "router.params" => {id: id},
      "rack.input" => StringIO.new({pattern: pattern}.to_json),
      "rack.session" => session
    )
  end

  def json(response)
    JSON.parse(response.body.first, symbolize_names: true)
  end

  it "validates regex successfully, updates user XP, and logs a submission" do
    expect {
      response = call_check(id: 31, pattern: "ruby")
      expect(response).to be_successful

      body = json(response)
      expect(body[:passing]).to be(true)
      expect(body[:xp_awarded]).to eq(25) # Easy challenge maps to 25 XP
      expect(body[:total_xp]).to eq(25)

      updated_user = dojo_repo.find_user_by_session_id(session_id)
      expect(updated_user.xp).to eq(25)
    }.to change { dojo_repo.submissions.count }.by(1)
  end

  it "accepts a capture-group answer (grades the group, not the full match)" do
    response = call_check(id: 31, pattern: "(ruby) dojo")

    expect(json(response)[:passing]).to be(true)
  end

  it "reports the user's real XP and belt on a failing submission" do
    call_check(id: 31, pattern: "ruby") # earn 25 XP first

    response = call_check(id: 32, pattern: "zzz-no-match")

    body = json(response)
    expect(body[:passing]).to be(false)
    expect(body[:total_xp]).to eq(25)
    expect(body[:belt]).to eq("Novato")
  end

  it "creates a guest user and awards XP when no session exists" do
    session = {}

    expect {
      response = call_check(id: 31, pattern: "ruby", session: session)
      expect(json(response)[:xp_awarded]).to eq(25)
    }.to change { dojo_repo.users.count }.by(1)

    expect(session["session_id"]).not_to be_nil
  end

  it "awards no XP for re-solving an already-solved kata" do
    call_check(id: 31, pattern: "ruby")

    response = call_check(id: 31, pattern: "ruby")

    body = json(response)
    expect(body[:passing]).to be(true)
    expect(body[:xp_awarded]).to eq(0)
    expect(body[:total_xp]).to eq(25)
  end

  it "returns 404 for an unknown kata" do
    response = call_check(id: 999_999, pattern: "hanami")

    expect(response.status).to eq(404)
  end

  it "returns 422 for an empty pattern" do
    response = call_check(id: 31, pattern: "   ")

    expect(response.status).to eq(422)
    expect(json(response)[:error_message]).to eq("Pattern cannot be empty")
  end

  it "returns 422 for an invalid regex" do
    response = call_check(id: 31, pattern: "[a-z")

    expect(response.status).to eq(422)
    expect(json(response)[:error_message]).to include("Invalid regex syntax")
  end

  it "logs rejected patterns too, so telemetry sees every attempt" do
    expect {
      call_check(id: 31, pattern: "[a-z")
    }.to change { dojo_repo.submissions.where(is_passing: false).count }.by(1)
  end

  describe "grading the ruby track" do
    it "passes the reference expression and awards XP" do
      response = call_check(id: 101, pattern: "arr.map { |x| x * 2 }")

      body = json(response)
      expect(body[:passing]).to be(true)
      expect(body[:xp_awarded]).to eq(25)
      expect(body[:test_results]).to eq([{expected_output: "[2, 4, 6]", passed: true}])
    end

    it "passes a structurally equivalent answer with different names and spacing" do
      response = call_check(id: 101, pattern: "arr.map { |e| e*2 }")

      expect(json(response)[:passing]).to be(true)
    end

    it "passes an accepted alternate phrasing" do
      response = call_check(id: 104, pattern: "arr.sum")

      expect(json(response)[:passing]).to be(true)
    end

    it "fails a semantically different answer without an error" do
      response = call_check(id: 101, pattern: "arr.map { |x| x + 2 }")

      expect(response.status).to eq(200)
      body = json(response)
      expect(body[:passing]).to be(false)
      expect(body[:error_message]).to be_nil
    end

    it "returns 422 with the parser's message for a syntax error" do
      response = call_check(id: 101, pattern: "arr.map { |x|")

      expect(response.status).to eq(422)
      expect(json(response)[:error_message]).not_to be_empty
    end

    it "logs ruby attempts to submissions like regex ones" do
      expect {
        call_check(id: 101, pattern: "arr.map { |x| x * 2 }")
      }.to change { dojo_repo.submissions.where(user_id: user.id).count }.by(1)
    end
  end

  describe "ruby track responses" do
    it "returns suggestions and the idiomatic flag on a structural pass" do
      body = json(call_check(id: 102, pattern: "arr.select(&:even?)"))

      expect(body[:passing]).to be(true)
      expect(body[:idiomatic]).to be(true)
      expect(body[:suggestions]).to be_an(Array)
      expect(body[:suggestions]).not_to be_empty
      expect(body[:suggestions].first).to have_key(:code)
    end

    it "passes an output-equivalent answer, flagged non-idiomatic" do
      body = json(call_check(id: 102, pattern: "arr.select { |n| [2, 4, 6].include?(n) }"))

      expect(body[:passing]).to be(true)
      expect(body[:idiomatic]).to be(false)
    end

    it "explains a wrong result through feedback, not a 422" do
      response = call_check(id: 102, pattern: "arr.select(&:odd?)")

      expect(response.status).to eq(200)
      body = json(response)
      expect(body[:passing]).to be(false)
      expect(body[:feedback]).to include("[1, 3, 5]")
    end
  end

  describe "attributing attempts to the learner" do
    def submissions_for(user_id)
      dojo_repo.submissions.where(user_id: user_id).count
    end

    it "attributes a passing submission to the current user" do
      expect {
        call_check(id: 31, pattern: "ruby")
      }.to change { submissions_for(user.id) }.by(1)
    end

    it "attributes a failing submission to the current user" do
      expect {
        call_check(id: 31, pattern: "zzz-no-match")
      }.to change { submissions_for(user.id) }.by(1)
    end

    it "attributes a validator-rejected submission to the current user" do
      expect {
        call_check(id: 31, pattern: "[a-z")
      }.to change { submissions_for(user.id) }.by(1)
    end

    it "attributes the attempt to the guest it just created" do
      session = {}

      call_check(id: 31, pattern: "ruby", session: session)

      guest = dojo_repo.find_user_by_session_id(session["session_id"])
      expect(submissions_for(guest.id)).to eq(1)
    end
  end
end
