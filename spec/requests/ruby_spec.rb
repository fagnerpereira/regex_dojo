# frozen_string_literal: true

require "nokogiri"

RSpec.describe "Ruby track pages", type: :request do
  def check(id, code)
    post "/ruby/#{id}/check", {answer: code}
  end

  describe "GET /ruby" do
    it "redirects to the current challenge" do
      get "/ruby"

      expect(last_response.status).to eq(302)
      expect(last_response.location).to end_with("/ruby/101")
    end
  end

  describe "GET /ruby/:id" do
    it "renders the challenge with dado, resultado esperado and the check form" do
      get "/ruby/101"

      expect(last_response.status).to eq(200)
      body = last_response.body
      expect(body).to include("Ruby · Desafio 1 de 5")
      expect(body).to include("experimento")
      expect(body).to include("Transformar com map")
      expect(body).to include("dado")
      expect(body).to include("resultado esperado")
      expect(body).to include("arr = [1, 2, 3]")
      expect(body).to include("[2, 4, 6]")
      expect(body).to include('action="/ruby/101/check"')
    end

    it "walks the track with wrapping previous/next links" do
      get "/ruby/101"
      expect(last_response.body).to include('href="/ruby/102"')
      expect(last_response.body).to include('href="/ruby/105"')

      get "/ruby/105"
      expect(last_response.body).to include('href="/ruby/101"')
      expect(last_response.body).to include('href="/ruby/104"')
    end

    it "404s for unknown and non-ruby ids" do
      get "/ruby/31"
      expect(last_response.status).to eq(404)

      get "/ruby/999"
      expect(last_response.status).to eq(404)
    end

    it "speaks plain language — no kata, no faixa" do
      get "/ruby/101"

      text = Nokogiri::HTML(last_response.body).text.downcase
      expect(text).not_to include("kata")
      expect(text).not_to include("faixa")
    end
  end

  describe "POST /ruby/:id/check" do
    it "accepts an equivalent solution and shows the ways to solve" do
      get "/inicio"

      check(101, "arr.map { |n| n * 2 }")

      expect(last_response.status).to eq(303)
      expect(last_response.location).to end_with("/ruby/101")

      get "/ruby/101"
      body = last_response.body
      expect(body).to include("Correto! +25 XP")
      expect(body).to include("formas de resolver")
      expect(body).to include("arr.collect { |x| x * 2 }")
      expect(body).to include("25/370 XP")
    end

    it "reports a wrong answer without awarding XP" do
      get "/inicio"

      check(101, "arr.map { |n| n * 3 }")

      expect(last_response.status).to eq(303)
      get "/ruby/101"
      expect(last_response.body).to include("0/370 XP")
      expect(last_response.body).not_to include("formas de resolver")
    end
  end
end
