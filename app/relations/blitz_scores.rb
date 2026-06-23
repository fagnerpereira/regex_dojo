# frozen_string_literal: true

module RegexDojo
  module Relations
    class BlitzScores < RegexDojo::DB::Relation
      schema(:blitz_scores, infer: true)
    end
  end
end
