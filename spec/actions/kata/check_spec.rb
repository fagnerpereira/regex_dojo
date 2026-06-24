require "stringio"

RSpec.describe RegexDojo::Actions::Kata::Check, :db do
  let(:dojo_repo) { Hanami.app["repos.dojo_repo"] }
  let(:session_id) { "test-session-uuid" }

  let!(:user) do
    dojo_repo.create_user(session_id: session_id)
    dojo_repo.find_user_by_session_id(session_id)
  end

  let(:params) do
    {
      "REQUEST_METHOD" => "GET",
      "router.params" => { id: 1 },
      "rack.input" => StringIO.new({ pattern: "ruby" }.to_json),
      "rack.session" => { "session_id" => session_id }
    }
  end

  it "validates regex successfully, updates user XP, and logs a submission" do
    expect {
      response = subject.call(params)
      expect(response).to be_successful
      
      # Reload user and check XP
      updated_user = dojo_repo.find_user_by_session_id(session_id)
      expect(updated_user.xp).to eq(25) # Easy challenge maps to 25 XP
    }.to change { dojo_repo.submissions.count }.by(1)
  end
end
