# frozen_string_literal: true

module RegexDojo
  module Relations
    class Progress < RegexDojo::DB::Relation
      schema(:progress, infer: true)
    end
  end
end
