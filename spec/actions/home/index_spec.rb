# frozen_string_literal: true

RSpec.describe RegexDojo::Actions::Home::Index do
  let(:params) { {} }

  it "works" do
    response = subject.call(params)
    expect(response).to be_successful
  end

  it "renders CSRF meta tags so @rails/request.js can send X-CSRF-Token on POSTs" do
    response = subject.call(params)
    body = response.body.join

    expect(body).to include('name="csrf-param"')
    expect(body).to include('name="csrf-token"')
  end
end
