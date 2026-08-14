# frozen_string_literal: true

RSpec.describe "Root", type: :request do
  it "renders the dashboard successfully" do
    get "/"

    expect(last_response.status).to be(200)
    expect(last_response.body).to include("RegexDojo")
  end

  it "renders a real HTML document, not escaped markup" do
    get "/"

    expect(last_response.body).to include("<!doctype html>")
    expect(last_response.body).to include('id="hud-bar"')
    expect(last_response.body).not_to include("&lt;div")
  end

  # CSRF enforcement itself is disabled by hanami-action in the test env, so this
  # asserts the tag the JS client needs is present — not that the check fires.
  it "exposes a CSRF token for the JS client" do
    get "/"

    expect(last_response.body).to match(/<meta name="csrf-token" content="[a-f0-9]{64}">/)
  end

  it "allows Google Fonts font files through the Content-Security-Policy" do
    get "/"

    expect(last_response.headers["Content-Security-Policy"])
      .to match(/font-src[^;]*fonts\.gstatic\.com/)
  end
end
