# frozen_string_literal: true

require "json"
require_relative "../regex_dojo/validator"

namespace :regex do
  desc "Test a pattern against a challenge. Usage: bundle exec rake regex:test[challenge_id,pattern]"
  task :test, [:challenge_id, :pattern] do |_, args|
    challenge_id = args[:challenge_id].to_i
    pattern = args[:pattern]

    if challenge_id.zero? || pattern.to_s.empty?
      puts "\e[31mError: Missing arguments.\e[0m"
      puts "Usage: bundle exec rake regex:test[challenge_id,pattern]"
      next
    end

    # Load JSON challenges
    challenges_path = File.expand_path("../../config/challenges.json", __dir__)
    unless File.exist?(challenges_path)
      puts "\e[31mError: config/challenges.json not found!\e[0m"
      next
    end

    challenges = JSON.parse(File.read(challenges_path))
    challenge = challenges.find { |c| c["id"] == challenge_id }

    if challenge.nil?
      puts "\e[31mError: Challenge ##{challenge_id} not found!\e[0m"
      next
    end

    puts "\nTesting Challenge ##{challenge["id"]}: #{challenge["title"]}"
    puts "Pattern: /#{pattern}/"
    puts "-" * 60

    result = RegexDojo::Validator.validate(pattern, challenge["test_cases"])

    if result.passing?
      puts "\e[32m✔ SUCCESS! All test cases passed.\e[0m"
    elsif result.error_message
      puts "\e[31m✖ ERROR: #{result.error_message}\e[0m"
    else
      puts "\e[31m✖ FAILURE: Some test cases failed.\e[0m"
      result.test_results.each_with_index do |tr, index|
        status = tr[:passed] ? "\e[32m✔ PASSED\e[0m" : "\e[31m✖ FAILED\e[0m"
        puts "  Test ##{index + 1}: Input: \"#{tr[:input]}\""
        puts "    Expected: #{tr[:expected_match].inspect}"
        puts "    Actual:   #{tr[:actual_match].inspect} [#{status}]"
      end
    end
    puts ""
  end
end
