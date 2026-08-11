# frozen_string_literal: true

module RegexDojo
  # Single source of truth for belt ranks.
  #
  # Two callers depend on these numbers agreeing: DojoRepo assigns a belt from
  # a user's cumulative XP, and the HUD draws its progress bar against the top
  # threshold. Keeping the table here stops the two from drifting apart.
  module BeltScale
    # Cumulative XP thresholds, highest first — the first one reached wins.
    TIERS = [
      [370, "black"],
      [265, "green"],
      [160, "orange"],
      [75, "yellow"],
      [0, "white"]
    ].freeze

    # XP needed for the top belt, i.e. a full progress bar.
    MAX_XP = TIERS.first.first

    def self.for(xp)
      TIERS.find { |threshold, _belt| xp >= threshold }.last
    end
  end
end
