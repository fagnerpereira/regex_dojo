# frozen_string_literal: true

# Seeds every learning track, one transactional upsert-by-id seeder per
# track (lib/regex_dojo/seeds/). Reseeding is history-safe: no track ever
# deletes another track's rows, and challenge ids are stable so
# progress.kata_id references and submissions FKs survive every run.
require_relative "../../lib/regex_dojo/seeds/regex"
require_relative "../../lib/regex_dojo/seeds/ruby"

regex_count = RegexDojo::Seeds::Regex.call
ruby_count = RegexDojo::Seeds::Ruby.call

puts "Database seeded: #{regex_count} regex + #{ruby_count} ruby challenges."
