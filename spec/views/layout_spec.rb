# frozen_string_literal: true

require "spec_helper"

RSpec.describe RegexDojo::Views::Layout do
  it "renders the full HTML document around the given content" do
    html = described_class.new.call { "MARKER" }

    expect(html).to include("<!doctype html>")
    expect(html).to include("<html lang=\"en\">")
    expect(html).to include("MARKER")
  end

  it "does not fall back to Phlex's missing-view_template warning" do
    html = described_class.new.call { "MARKER" }

    expect(html).not_to include("Phlex Warning")
  end

  it "renders the CSRF meta tag when given a token" do
    html = described_class.new(csrf_token: "tok123").call { "" }

    expect(html).to include('<meta name="csrf-token" content="tok123">')
  end

  it "omits the CSRF meta tag when no token is given" do
    html = described_class.new.call { "" }

    expect(html).not_to include("csrf-token")
  end
end
