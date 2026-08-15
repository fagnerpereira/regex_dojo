# frozen_string_literal: true

module RegexDojo
  # Single source of truth for the XP levels (formerly belt ranks).
  #
  # Two callers depend on these numbers agreeing: DojoRepo assigns a level from
  # a user's cumulative XP, and the header draws its progress bar against the
  # top threshold. Keeping the table here stops the two from drifting apart.
  module BeltScale
    # Cumulative XP thresholds, highest first — the first one reached wins.
    # Labels are the learner-facing level names (plain language, no jargon).
    TIERS = [
      [370, "Especialista"],
      [265, "Avançado"],
      [160, "Intermediário"],
      [75, "Iniciante"],
      [0, "Novato"]
    ].freeze

    # XP needed for the top belt, i.e. a full progress bar.
    MAX_XP = TIERS.first.first

    def self.for(xp)
      TIERS.find { |threshold, _belt| xp >= threshold }.last
    end
  end
end
