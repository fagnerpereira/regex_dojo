# frozen_string_literal: true

require "json"

# Load challenges JSON
challenges_path = File.expand_path("../challenges.json", __dir__)

if File.exist?(challenges_path)
  challenges_data = JSON.parse(File.read(challenges_path))

  # Access Sequel relations directly via ROM/Hanami app container
  begin
    challenges_relation = Hanami.app["relations.challenges"]
    test_cases_relation = Hanami.app["relations.test_cases"]

    # Clear existing data to ensure idempotency
    test_cases_relation.delete
    challenges_relation.delete

    challenges_data.each do |c|
      # Insert challenge and retrieve its ID
      challenge_id = challenges_relation.insert(
        title: c["title"],
        difficulty: c["difficulty"],
        description: c["description"] || c["lesson"] || c["title"],
        hint: c["hint"],
        concept: c["concept"],
        lesson: c["lesson"],
        task: c["task"]
      )

      # Insert test cases for this challenge
      c["test_cases"].each do |tc|
        test_cases_relation.insert(
          challenge_id: challenge_id,
          input: tc["input"],
          expected_match: tc["expected_match"]
        )
      end
    end

    puts "Database successfully seeded with #{challenges_data.size} challenges!"
  rescue => e
    puts "Error seeding database: #{e.message}"
    puts "Ensure migrations have been run using 'bundle exec hanami db migrate' first."
  end
else
  puts "Warning: config/challenges.json not found. Seeds not loaded."
end
