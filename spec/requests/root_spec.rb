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

  it "advances the ruby track past the kata named in ruby_after" do
    get "/?ruby_after=101"
    expect(last_response.body).to include('data-ruby-dojo-challenge-id-value="102"')

    get "/?ruby_after=105" # wraps after the last kata
    expect(last_response.body).to include('data-ruby-dojo-challenge-id-value="101"')
  end

  it "steps the ruby track back with ruby_before" do
    get "/?ruby_before=102"
    expect(last_response.body).to include('data-ruby-dojo-challenge-id-value="101"')
  end

  # The next/previous links are full navigations; the landing tab must not
  # depend on localStorage (blocked in some private browsing modes).
  it "marks the ruby tab as the server-chosen tab when navigating the track" do
    get "/?ruby_after=101"
    expect(last_response.body).to include('data-tabs-server-tab="ruby"')

    get "/?ruby_before=101"
    expect(last_response.body).to include('data-tabs-server-tab="ruby"')

    get "/"
    expect(last_response.body).not_to include("data-tabs-server-tab")
  end

  # Without this, browsers heuristically cache the unfingerprinted assets and
  # every CSS/JS change silently requires a hard refresh.
  it "serves assets with a revalidation cache policy" do
    get "/assets/app.css"

    expect(last_response.status).to eq(200)
    expect(last_response.headers["cache-control"]).to eq("no-cache")
  end

  it "allows Google Fonts font files through the Content-Security-Policy" do
    get "/"

    expect(last_response.headers["Content-Security-Policy"])
      .to match(/font-src[^;]*fonts\.gstatic\.com/)
  end
end
