# frozen_string_literal: true

RSpec.describe "Root", type: :request do
  it "renders the dashboard successfully" do
    get "/"

    expect(last_response.status).to be(200)
    expect(last_response.body).to include("RegexDojo")
  end
end
