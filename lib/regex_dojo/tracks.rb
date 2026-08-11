# frozen_string_literal: true

require_relative "belt_scale"
require_relative "graders/regex"
require_relative "graders/ruby"

module RegexDojo
  # The learning tracks this dojo offers. A track is a column value on
  # `challenges` plus this compile-time registry — the pieces that cannot
  # live in SQL: which grader rules on an answer, how the track is labelled,
  # and the XP ceiling its HUD bar is drawn against.
  #
  # Adding a language = one entry here + a seeder + challenge rows.
  module Tracks
    REGISTRY = {
      "regex" => {
        grader: Graders::Regex,
        label: "🥋 Regex",
        xp_ceiling: BeltScale::MAX_XP
      },
      "ruby" => {
        grader: Graders::Ruby,
        label: "💎 Ruby",
        # Phase 1 ships five hand-written Easy katas at 25 XP each; the
        # harvest phase recalibrates this alongside the generated content.
        xp_ceiling: 125
      }
    }.freeze

    def self.grader_for(track)
      REGISTRY.fetch(track.to_s).fetch(:grader)
    end

    def self.label_for(track)
      REGISTRY.fetch(track.to_s).fetch(:label)
    end
  end
end
