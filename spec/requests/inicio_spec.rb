# frozen_string_literal: true

require "nokogiri"

RSpec.describe "GET / (Início)", type: :request do
  it "renders the Organic home with greeting, hero, tracks and tools" do
    get "/"

    expect(last_response.status).to eq(200)
    body = last_response.body
    expect(body).to include("Bem-vindo de volta.")
    expect(body).to include("Desafio 1 de 15")
    expect(body).to include("Ferramentas")
    expect(body).to include('href="/sandbox"')
    expect(body).to include('href="/blitz"')
    expect(body).to include('href="/codex"')
    expect(body).to include('href="/ruby"')
  end

  it "renders the greeting date in Portuguese" do
    get "/"

    expect(last_response.body)
      .to match(/de (janeiro|fevereiro|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)/)
  end

  it "advances the hero to the first unsolved challenge" do
    get "/" # creates the guest session
    post "/desafios/31/check", {answer: "ruby"}

    get "/"

    expect(last_response.body).to include("Desafio 2 de 15")
    expect(last_response.body).to include("1/15 desafios")
  end

  it "stamps data-dark when the theme cookie says dark" do
    set_cookie "theme=dark"

    get "/"

    expect(last_response.body).to include("data-dark")
  end

  it "stays light without the theme cookie" do
    get "/"

    expect(last_response.body).not_to include("data-dark")
  end

  it "speaks plain language — no kata, no faixa" do
    get "/"

    text = Nokogiri::HTML(last_response.body).text.downcase
    expect(text).not_to include("kata")
    expect(text).not_to include("faixa")
  end
end
