# frozen_string_literal: true

module RegexDojo
  module Relations
    class Challenges < RegexDojo::DB::Relation
      schema(:challenges, infer: true) do
        associations do
          has_many :test_cases
          has_many :submissions
        end
      end
    end
  end
end
