# frozen_string_literal: true

require "stringio"

RSpec.describe RegexDojo::Actions::Kata::Check, :db do
  let(:dojo_repo) { Hanami.app["repos.dojo_repo"] }
  let(:session_id) { "test-session-uuid" }

  let!(:user) do
    dojo_repo.create_user(session_id: session_id)
    dojo_repo.find_user_by_session_id(session_id)
  end

  def make_request(pattern:, kata_id: 31)
    {
      "REQUEST_METHOD" => "POST",
      "router.params" => {id: kata_id},
      "rack.input" => StringIO.new({pattern: pattern}.to_json),
      "rack.session" => {"session_id" => session_id}
    }
  end

  it "awards XP only on first successful submission of a kata" do
    # First submission (new kata)
    params = make_request(pattern: "ruby")
    response = subject.call(params)
    body = JSON.parse(response.body.join)

    expect(body["passing"]).to be true
    expect(body["xp_awarded"]).to eq(25) # Easy kata = 25 XP

    # Check user's total XP updated
    updated_user = dojo_repo.find_user_by_session_id(session_id)
    expect(updated_user.xp).to eq(25)

    # Second submission (same kata, already solved) — must create fresh params/request
    params = make_request(pattern: "ruby")
    response = subject.call(params)
    body = JSON.parse(response.body.join)

    expect(body["passing"]).to be true
    expect(body["xp_awarded"]).to eq(0) # No XP on re-solve
    expect(body["total_xp"]).to eq(25) # Still 25 total
  end

  it "includes belt info in response for HUD updates" do
    params = make_request(pattern: "ruby")
    response = subject.call(params)
    body = JSON.parse(response.body.join)

    expect(body).to have_key("belt")
    expect(body["belt"]).to be_a(String)
  end

  it "returns all test case results for UI feedback" do
    params = make_request(pattern: "ruby")
    response = subject.call(params)
    body = JSON.parse(response.body.join)

    expect(body["test_results"]).to be_an(Array)
    expect(body["test_results"].length).to be > 0

    test_result = body["test_results"].first
    expect(test_result).to have_key("input")
    expect(test_result).to have_key("actual_match")
    expect(test_result).to have_key("passed")
  end

  it "rejects invalid regex with error message" do
    params = make_request(pattern: "[invalid(regex")
    response = subject.call(params)
    body = JSON.parse(response.body.join)

    expect(body["passing"]).to be false
    expect(body).to have_key("error_message")
    expect(body["error_message"]).to include("Invalid regex")
  end
end
