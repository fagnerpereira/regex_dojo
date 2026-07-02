# frozen_string_literal: true

RSpec.describe "Belt progression based on XP", :db do
  let(:dojo_repo) { Hanami.app["repos.dojo_repo"] }

  it "updates belt as user earns XP milestones" do
    user = dojo_repo.create_user(session_id: "belt-test")
    user = dojo_repo.find_user_by_session_id("belt-test")
    expect(user.belt).to eq("white")
    expect(user.xp).to eq(0)

    # Simulate solving katas to reach yellow belt (75 XP threshold)
    dojo_repo.record_solved_kata(user.id, "1", 25)
    dojo_repo.record_solved_kata(user.id, "2", 25)
    dojo_repo.record_solved_kata(user.id, "3", 25)

    user = dojo_repo.find_user_by_session_id("belt-test")
    expect(user.xp).to eq(75)
    expect(user.belt).to eq("yellow")

    # Continue to orange belt (160 XP threshold)
    dojo_repo.record_solved_kata(user.id, "4", 25)
    dojo_repo.record_solved_kata(user.id, "5", 25)
    dojo_repo.record_solved_kata(user.id, "6", 35) # Medium kata

    user = dojo_repo.find_user_by_session_id("belt-test")
    expect(user.xp).to eq(160)
    expect(user.belt).to eq("orange")

    # Reach green belt (265 XP threshold)
    dojo_repo.record_solved_kata(user.id, "7", 35)
    dojo_repo.record_solved_kata(user.id, "8", 25)

    user = dojo_repo.find_user_by_session_id("belt-test")
    expect(user.xp).to eq(220)
    expect(user.belt).to eq("orange") # Not yet at 265

    dojo_repo.record_solved_kata(user.id, "9", 50)
    user = dojo_repo.find_user_by_session_id("belt-test")
    expect(user.xp).to eq(270)
    expect(user.belt).to eq("green")
  end

  it "respects belt thresholds exactly" do
    user = dojo_repo.create_user(session_id: "threshold-test")
    user = dojo_repo.find_user_by_session_id("threshold-test")

    # Reach exactly 74 XP (1 below yellow threshold)
    dojo_repo.record_solved_kata(user.id, "1", 25)
    dojo_repo.record_solved_kata(user.id, "2", 25)
    dojo_repo.record_solved_kata(user.id, "3", 24) # 74 total

    user = dojo_repo.find_user_by_session_id("threshold-test")
    expect(user.xp).to eq(74)
    expect(user.belt).to eq("white") # Still white

    # Add 1 more XP to reach threshold
    dojo_repo.record_solved_kata(user.id, "4", 1)
    user = dojo_repo.find_user_by_session_id("threshold-test")
    expect(user.xp).to eq(75)
    expect(user.belt).to eq("yellow") # Now yellow
  end
end
