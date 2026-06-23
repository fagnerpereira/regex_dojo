# frozen_string_literal: true

module RegexDojo
  module Relations
    class TestCases < RegexDojo::DB::Relation
      schema(:test_cases, infer: true) do
        associations do
          belongs_to :challenges, as: :challenge
        end
      end
    end
  end
end
