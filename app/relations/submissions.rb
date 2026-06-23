# frozen_string_literal: true

module RegexDojo
  module Relations
    class Submissions < RegexDojo::DB::Relation
      schema(:submissions, infer: true) do
        associations do
          belongs_to :challenges, as: :challenge
        end
      end
    end
  end
end
