# frozen_string_literal: true

RSpec.describe "Seeds", :db do
  let(:challenges) { Hanami.app["relations.challenges"].to_a }

  it "loads the full curriculum with stable ids" do
    expect(challenges.size).to eq(15)
    expect(challenges.map { |c| c[:id] }.min).to eq(31)
  end

  it "populates the teaching content columns" do
    challenges.each do |c|
      expect(c[:concept]).not_to be_nil
      expect(c[:lesson]).not_to be_nil
      expect(c[:task]).not_to be_nil
    end
  end
end
