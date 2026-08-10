# frozen_string_literal: true

# End-to-end: through the router, with a real session cookie and JSON body.
# (CSRF enforcement is disabled by hanami-action in the test env.)
RSpec.describe "POST /kata/:id/check", type: :request do
  def post_pattern(kata_id, pattern)
    post "/kata/#{kata_id}/check",
      {pattern: pattern}.to_json,
      "CONTENT_TYPE" => "application/json"
    JSON.parse(last_response.body, symbolize_names: true)
  end

  it "grades a correct pattern and awards XP to the session's guest user" do
    get "/" # first visit creates the guest session

    body = post_pattern(31, "ruby")

    expect(last_response.status).to eq(200)
    expect(body[:passing]).to be(true)
    expect(body[:xp_awarded]).to eq(25)
    expect(body[:total_xp]).to eq(25)
  end

  it "keeps reporting the real XP total on a failing attempt" do
    get "/"
    post_pattern(31, "ruby")

    body = post_pattern(32, "zzz-wont-match")

    expect(body[:passing]).to be(false)
    expect(body[:total_xp]).to eq(25)
  end
end
