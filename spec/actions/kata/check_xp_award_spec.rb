# frozen_string_literal: true

require "stringio"

RSpec.describe RegexDojo::Actions::Kata::Check, :db do
  let(:dojo_repo) { Hanami.app["repos.dojo_repo"] }
  let(:session_id) { "xp-test-session" }

  let!(:user) do
    dojo_repo.create_user(session_id: session_id)
    dojo_repo.find_user_by_session_id(session_id)
  end

  def check_kata(kata_id: 31, pattern: "ruby")
    params = {
      "REQUEST_METHOD" => "POST",
      "router.params" => {id: kata_id},
      "rack.input" => StringIO.new({pattern: pattern}.to_json),
      "rack.session" => {"session_id" => session_id}
    }
    subject.call(params)
  end

  it "correctly tracks XP across multiple kata solves" do
    # First kata (Easy = 25 XP)
    response1 = check_kata(kata_id: 31, pattern: "ruby")
    body1 = JSON.parse(response1.body.join)
    expect(body1["xp_awarded"]).to eq(25)
    expect(body1["total_xp"]).to eq(25)

    # Second kata (Easy = 25 XP)
    response2 = check_kata(kata_id: 32, pattern: "c.t")
    body2 = JSON.parse(response2.body.join)
    expect(body2["xp_awarded"]).to eq(25)
    expect(body2["total_xp"]).to eq(50) # 25 + 25

    # Verify database reflects both solves
    reloaded_user = dojo_repo.find_user_by_session_id(session_id)
    expect(reloaded_user.xp).to eq(50)
  end

  it "returns current belt based on XP" do
    response = check_kata(kata_id: 31, pattern: "ruby")
    body = JSON.parse(response.body.join)

    # Initial user should be white belt
    expect(body["belt"]).to eq("white")
  end

  it "logs every submission regardless of pass/fail" do
    check_kata(kata_id: 31, pattern: "ruby")
    check_kata(kata_id: 31, pattern: "invalid(regex")

    submissions = dojo_repo.submissions
    expect(submissions.count).to eq(2)
    expect(submissions.where(is_passing: true).count).to eq(1)
    expect(submissions.where(is_passing: false).count).to eq(1)
  end
end
