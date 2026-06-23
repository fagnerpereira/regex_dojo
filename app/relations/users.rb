# frozen_string_literal: true

module RegexDojo
  module Relations
    class Users < RegexDojo::DB::Relation
      schema(:users, infer: true)
    end
  end
end
