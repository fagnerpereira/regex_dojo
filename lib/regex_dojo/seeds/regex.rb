# frozen_string_literal: true

require "json"

module RegexDojo
  module Seeds
    # Seeds the regex track from config/challenges.json.
    #
    # Rows are upserted by their explicit id (31–45) instead of the old
    # delete-everything-then-insert: progress.kata_id stores stringified
    # challenge ids and submissions carry a challenge FK with ON DELETE
    # CASCADE, so a table-wide delete would silently destroy user history.
    # test_cases are rebuilt per challenge — nothing references their ids.
    module Regex
      TRACK = "regex"

      def self.call(app: Hanami.app)
        path = File.join(app.root, "config", "challenges.json")
        raise "config/challenges.json not found — cannot seed" unless File.exist?(path)

        data = JSON.parse(File.read(path))
        challenges = app["relations.challenges"]
        test_cases = app["relations.test_cases"]

        app["db.rom"].gateways[:default].connection.transaction do
          data.each do |c|
            row = {
              title: c["title"],
              difficulty: c["difficulty"],
              description: c["description"],
              hint: c["hint"],
              concept: c["concept"],
              lesson: c["lesson"],
              task: c["task"],
              track: TRACK,
              mode: "pattern"
            }

            if challenges.where(id: c["id"]).exist?
              challenges.where(id: c["id"]).command(:update).call(row)
            else
              challenges.insert(row.merge(id: c["id"]))
            end

            test_cases.where(challenge_id: c["id"]).delete
            c["test_cases"].each do |tc|
              test_cases.insert(
                challenge_id: c["id"],
                input: tc["input"],
                expected_match: tc["expected_match"]
              )
            end
          end
        end

        data.size
      end
    end
  end
end
