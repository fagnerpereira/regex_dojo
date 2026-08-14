# frozen_string_literal: true

require "nokogiri"

RSpec.describe "GET /sandbox", type: :request do
  it "renders the free-play sandbox with pattern field, test text and result" do
    get "/sandbox"

    expect(last_response.status).to eq(200)
    body = last_response.body
    expect(body).to include("Sandbox · teste livre")
    expect(body).to include("texto de teste")
    expect(body).to include("resultado")
    expect(body).to include("copiar")
    expect(body).to include("The quick brown fox")
    expect(body).to include("0 ocorrências")
  end

  it "prefills the pattern from the query string for the Codex handoff" do
    get "/sandbox", pattern: "\\d{3}"

    expect(last_response.body).to include(">\\d{3}</textarea>")
  end

  it "speaks plain language — no kata, no faixa" do
    get "/sandbox"

    text = Nokogiri::HTML(last_response.body).text.downcase
    expect(text).not_to include("kata")
    expect(text).not_to include("faixa")
  end
end
