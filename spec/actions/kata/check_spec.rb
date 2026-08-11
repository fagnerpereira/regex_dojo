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
    expect(body[:belt]).to eq("white")
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
end
