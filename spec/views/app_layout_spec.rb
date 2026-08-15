# frozen_string_literal: true

require "spec_helper"

RSpec.describe RegexDojo::Views::AppLayout do
  def render(dark: false, csrf_token: nil)
    user = {xp: 0, belt: "Novato", streak: 1, session_id: "abcdefgh-1234"}
    described_class.new(user: user, dark: dark, csrf_token: csrf_token).call { "MARKER" }
  end

  it "renders a Portuguese document shell on the Organic ground" do
    html = render

    expect(html).to include("<!doctype html>")
    expect(html).to include('<html lang="pt-BR">')
    expect(html).to include("<title>Regex Dojo</title>")
    expect(html).to include("MARKER")
  end

  it "stamps data-dark on the root element when the theme cookie says so" do
    expect(render(dark: true)).to include("data-dark")
    expect(render(dark: false)).not_to include("data-dark")
  end

  it "loads the Organic font families" do
    html = render

    expect(html).to include("Caprasimo")
    expect(html).to include("IBM+Plex+Mono")
  end

  it "renders the CSRF meta tag only when given a token" do
    expect(render(csrf_token: "tok123")).to include('<meta name="csrf-token" content="tok123">')
    expect(render).not_to include("csrf-token")
  end

  it "renders the global header" do
    expect(render).to include("0/#{RegexDojo::BeltScale::MAX_XP} XP")
  end
end
