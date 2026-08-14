# frozen_string_literal: true

require "nokogiri"

RSpec.describe "Desafio pages", type: :request do
  def check(id, answer)
    post "/desafios/#{id}/check", {answer: answer}
  end

  describe "GET /desafios/:id" do
    it "renders the challenge with Portuguese copy, dots and the check form" do
      get "/desafios/31"

      expect(last_response.status).to eq(200)
      body = last_response.body
      expect(body).to include("Caracteres literais")
      expect(body).to include("Regex · Desafio 1 de 15")
      expect(body).to include("vale 25 XP")
      expect(body).to include('action="/desafios/31/check"')
      expect(body).to include('href="/desafios/45"')
      expect(body).to include("welcome to ruby dojo")
    end

    it "renders the lesson's inline markup instead of escaping it" do
      get "/desafios/31"

      expect(last_response.body).to include("<code>ruby</code>")
    end

    it "speaks plain language — no kata, no faixa" do
      get "/desafios/31"

      text = Nokogiri::HTML(last_response.body).text.downcase
      expect(text).not_to include("kata")
      expect(text).not_to include("faixa")
    end

    it "404s for unknown and non-regex ids" do
      get "/desafios/999"
      expect(last_response.status).to eq(404)

      get "/desafios/101"
      expect(last_response.status).to eq(404)
    end

    it "restores the learner's last submitted answer for the pattern field" do
      get "/"
      check(31, "my-wrong-answer")

      get "/desafios/31"

      expect(last_response.body).to include('data-desafio-last-pattern-value="my-wrong-answer"')
    end
  end

  describe "GET /desafios" do
    it "redirects to the first unsolved challenge" do
      get "/desafios"

      expect(last_response.status).to eq(302)
      expect(last_response.location).to end_with("/desafios/31")
    end

    it "advances past solved challenges" do
      get "/"
      check(31, "ruby")

      get "/desafios"

      expect(last_response.location).to end_with("/desafios/32")
    end
  end

  describe "POST /desafios/:id/check" do
    it "grades, awards XP and comes back with the success banner" do
      get "/"

      check(31, "ruby")

      expect(last_response.status).to eq(303)
      expect(last_response.location).to end_with("/desafios/31")

      get "/desafios/31"
      expect(last_response.body).to include("Correto! +25 XP")
      expect(last_response.body).to include("25/370 XP")
      expect(last_response.body).to include("Próximo desafio")
    end

    it "grades capture groups by the first participating group, like the server validator" do
      get "/"

      check(43, "(red|green|blue)")

      get "/desafios/43"
      expect(last_response.body).to include("Correto!")
    end

    it "logs failing attempts without awarding XP" do
      get "/"

      check(31, "zzz")

      expect(last_response.status).to eq(303)
      get "/desafios/31"
      expect(last_response.body).to include("0/370 XP")
      expect(last_response.body).to include('data-desafio-last-pattern-value="zzz"')
    end

    it "notes an already solved challenge instead of double-awarding" do
      get "/"
      check(31, "ruby")

      check(31, "ruby")

      get "/desafios/31"
      expect(last_response.body).to include("sem XP novo")
      expect(last_response.body).to include("25/370 XP")
    end

    it "404s for unknown ids" do
      check(999, "x")

      expect(last_response.status).to eq(404)
    end

    it "reports validator rejections through the error flash" do
      get "/"

      check(31, "a" * 201) # over the validator's pattern length cap

      expect(last_response.status).to eq(303)
      get "/desafios/31"
      expect(last_response.body).to include("bg-terra-100") # error box rendered
      expect(last_response.body).to include("0/370 XP")
    end
  end
end
