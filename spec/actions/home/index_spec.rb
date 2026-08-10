# frozen_string_literal: true

RSpec.describe RegexDojo::Actions::Home::Index do
  let(:params) { {} }

  it "works" do
    response = subject.call(params)
    expect(response).to be_successful
  end
end
