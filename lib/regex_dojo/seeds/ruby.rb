# frozen_string_literal: true

require "json"

module RegexDojo
  module Seeds
    # Seeds the ruby track from config/ruby_challenges.json.
    #
    # Same upsert-by-explicit-id contract as Seeds::Regex (ids 101+ so they
    # can never collide with the regex katas at 31–45). Content lives in the
    # payload JSON column; the shape is validated here, at the only moment
    # generated content enters the database.
    module Ruby
      TRACK = "ruby"
      REQUIRED_PAYLOAD_KEYS = %w[prompt setup expression expected_output accepted].freeze

      def self.call(app: Hanami.app)
        path = File.join(app.root, "config", "ruby_challenges.json")
        raise "config/ruby_challenges.json not found — cannot seed" unless File.exist?(path)

        data = JSON.parse(File.read(path))
        challenges = app["relations.challenges"]

        app["db.rom"].gateways[:default].connection.transaction do
          data.each do |c|
            missing = REQUIRED_PAYLOAD_KEYS - c.fetch("payload", {}).keys
            raise "ruby challenge #{c["id"]} payload missing #{missing.join(", ")}" unless missing.empty?

            row = {
              title: c["title"],
              difficulty: c["difficulty"],
              description: c["description"],
              hint: c["hint"],
              concept: c["concept"],
              track: TRACK,
              mode: "type_code",
              payload: JSON.generate(c["payload"])
            }

            if challenges.where(id: c["id"]).exist?
              challenges.where(id: c["id"]).command(:update).call(row)
            else
              challenges.insert(row.merge(id: c["id"]))
            end
          end
        end

        data.size
      end
    end
  end
end
