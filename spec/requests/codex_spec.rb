# frozen_string_literal: true

require "nokogiri"

RSpec.describe "GET /codex", type: :request do
  it "renders the grouped Portuguese reference" do
    get "/codex"

    expect(last_response.status).to eq(200)
    body = last_response.body
    expect(body).to include("Codex · referência")
    expect(body).to include("Âncoras")
    expect(body).to include("Quantificadores")
    expect(body).to include("Lookaround")
    expect(body).to include("borda de palavra")
  end

  it "links every card except the Flags group into the Sandbox" do
    get "/codex"

    doc = Nokogiri::HTML(last_response.body)
    links = doc.css('a[href^="/sandbox?pattern="]')

    expect(links.size).to eq(30)
    expect(last_response.body).to include('href="/sandbox?pattern=%5Cd%7B3%7D"')
    expect(links.map { |a| a["href"] }).not_to include(a_string_including("%2Fcat%2Fg"))
  end

  it "speaks plain language — no kata, no faixa" do
    get "/codex"

    text = Nokogiri::HTML(last_response.body).text.downcase
    expect(text).not_to include("kata")
    expect(text).not_to include("faixa")
  end
end
