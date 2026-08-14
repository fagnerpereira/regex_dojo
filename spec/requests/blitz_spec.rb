# frozen_string_literal: true

require "nokogiri"

RSpec.describe "Blitz", type: :request do
  describe "GET /blitz" do
    it "renders start, run and end states with the mixed-review copy" do
      get "/blitz"

      expect(last_response.status).to eq(200)
      body = last_response.body
      expect(body).to include("Blitz · revisão mista")
      expect(body).to include("Começar")
      expect(body).to include("recorde")
      expect(body).to include("Pular")
      expect(body).to include("Tempo!")
      expect(body).to include("De novo")
    end

    it "embeds only non-hard challenges for the game" do
      get "/blitz"

      root = Nokogiri::HTML(last_response.body).at_css('[data-controller="blitz-page"]')
      ids = JSON.parse(root["data-blitz-page-challenges-value"]).map { |c| c["id"] }

      expect(ids).to eq((31..42).map(&:to_s))
    end

    it "speaks plain language — no kata, no faixa" do
      get "/blitz"

      text = Nokogiri::HTML(last_response.body).text.downcase
      expect(text).not_to include("kata")
      expect(text).not_to include("faixa")
    end
  end

  describe "POST /blitz/score" do
    it "persists the run and serves the record back on the next visit" do
      get "/blitz" # creates the guest session

      post "/blitz/score", {score: 4, speed_multiplier: 1.0}.to_json,
        "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(204)

      get "/blitz"
      expect(last_response.body).to include('data-blitz-page-best-value="4"')
    end

    it "rejects a negative score" do
      get "/blitz"

      post "/blitz/score", {score: -1}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response.status).to eq(422)
    end
  end
end
