# frozen_string_literal: true

require "json"

# Seed challenges and test cases from config/challenges.json.
#
# Ids are inserted explicitly from the JSON so re-seeding keeps
# progress.kata_id references (stringified challenge ids) valid.
challenges_path = File.expand_path("../challenges.json", __dir__)

raise "config/challenges.json not found — cannot seed" unless File.exist?(challenges_path)

challenges_data = JSON.parse(File.read(challenges_path))

challenges_relation = Hanami.app["relations.challenges"]
test_cases_relation = Hanami.app["relations.test_cases"]

# Clear existing data to ensure idempotency
test_cases_relation.delete
challenges_relation.delete

challenges_data.each do |c|
  challenge_id = challenges_relation.insert(
    id: c["id"],
    title: c["title"],
    difficulty: c["difficulty"],
    description: c["description"],
    hint: c["hint"],
    concept: c["concept"],
    lesson: c["lesson"],
    task: c["task"]
  )

  c["test_cases"].each do |tc|
    test_cases_relation.insert(
      challenge_id: challenge_id,
      input: tc["input"],
      expected_match: tc["expected_match"]
    )
  end
end

puts "Database successfully seeded with #{challenges_data.size} challenges!"
