# frozen_string_literal: true

# Infrastructure concerns of the root page: document shell, CSRF meta,
# asset caching policy and CSP. The Início screen's content is covered in
# inicio_spec.rb.
RSpec.describe "GET / infrastructure", type: :request do
  it "serves the full Organic document" do
    get "/"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("<!doctype html>")
    expect(last_response.body).to include('<html lang="pt-BR"')
  end

  it "renders the session's CSRF token as a meta tag" do
    get "/"

    expect(last_response.body).to match(/<meta name="csrf-token" content="[a-f0-9]{64}">/)
  end

  it "serves assets with a forced-revalidation cache policy" do
    get "/assets/app.css"

    expect(last_response.status).to eq(200)
    expect(last_response.headers["cache-control"]).to eq("no-cache")
  end

  it "allows Google Fonts files through the Content-Security-Policy" do
    get "/"

    expect(last_response.headers["Content-Security-Policy"])
      .to match(%r{font-src[^;]*https://fonts\.gstatic\.com})
  end
end
