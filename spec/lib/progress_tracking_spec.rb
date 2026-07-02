# frozen_string_literal: true

RSpec.describe "Progress tracking", :db do
  let(:dojo_repo) { Hanami.app["repos.dojo_repo"] }

  it "prevents duplicate progress records for same kata" do
    dojo_repo.create_user(session_id: "progress-test")
    user = dojo_repo.find_user_by_session_id("progress-test")

    # First solve
    result1 = dojo_repo.record_solved_kata(user.id, "1", 25)
    expect(result1).to be true

    progress = dojo_repo.get_user_progress(user.id)
    expect(progress.count).to eq(1)
    expect(progress.first.kata_id).to eq("1")
    expect(progress.first.solved).to be true

    # Second solve (should be rejected)
    result2 = dojo_repo.record_solved_kata(user.id, "1", 25)
    expect(result2).to be false

    progress = dojo_repo.get_user_progress(user.id)
    expect(progress.count).to eq(1) # Still only 1 record
  end

  it "tracks multiple different kata solves" do
    dojo_repo.create_user(session_id: "multi-test")
    user = dojo_repo.find_user_by_session_id("multi-test")

    dojo_repo.record_solved_kata(user.id, "1", 25)
    dojo_repo.record_solved_kata(user.id, "2", 25)
    dojo_repo.record_solved_kata(user.id, "3", 25)

    progress = dojo_repo.get_user_progress(user.id)
    expect(progress.count).to eq(3)
    expect(progress.map(&:kata_id).sort).to eq(["1", "2", "3"])
  end

  it "correctly marks which katas have been solved" do
    dojo_repo.create_user(session_id: "solved-test")
    user = dojo_repo.find_user_by_session_id("solved-test")

    # Solve only katas 1 and 3
    dojo_repo.record_solved_kata(user.id, "1", 25)
    dojo_repo.record_solved_kata(user.id, "3", 25)

    progress = dojo_repo.get_user_progress(user.id)
    solved_ids = progress.select(&:solved).map(&:kata_id).sort

    expect(solved_ids).to eq(["1", "3"])
    expect(progress.all?(&:solved)).to be true
  end
end
